#-*- coding : utf-8 -*-
#
# TwitNote
#

#ツイートをEvernoteのノートに加工してアップロードするためのクラス
#ハッシュタグの抽出とかツイートからハッシュタグを分離するメソッドとかあるから他でも使えるかもしれない

$:.unshift File.dirname(__FILE__)

require_relative ".././cnf/config"
require 'tweetlib'
require 'noteheader'
require 'rubygems'
require 'evernote_oauth'
require 'openssl'
require 'json'

#なんかこの一行がないとEvernote側の通信がこける
#そのくせ警告だして来るしたぶんEvernoteOauthが悪い
begin
	OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
rescue => e
	puts e
end

class TwitNote
	# initializeでconfig.rbの定数をロードするので、起動前にかならずconfig.rbの中身が満足か確認すること
	#確認しないで起動したらあなたが末代です
	def initialize
		@twitclient = Tweetlib::Client.new(TWITTER)
		@me = @twitclient.fetch_account_info
		@token = EVERNOTE[2]
		client = EvernoteOAuth::Client.new(
				token: @token,
				consumer_key: EVERNOTE[0],
				consumer_secret: EVERNOTE[1], 
				sandbox: SANDBOX
			)
		
		begin
			@note_store = client.note_store
		rescue => e
			puts e
		end
	end

	#ツイートのJSONからハッシュタグを抽出
	def extract_tgas(status)
		tags = []
		tags.each do |tag|
			status["entities"]["hashtags"].each do |status_tag|
				tag = status_tag["text"].to_s
			end
		end
		tags
	end

	#ツイート本文からハッシュタグを削除
	def tweet_demolish(status_text, hashtags)
		hashtags.each do |tag|
			if tag["text"] != "tweetnote" then
				status_text.slice!("#" + "#{tag["text"]}" + " ")
			end
		end
		status_text
	end

	#noteを生成
	#noteのタイトルは作成時の時間とする
	def make_note(text, tags=nil)
		now = Time::now

		body = "#{NOTE_HEADER}"
		body << "<en-note>#{text}</en-note>"
		note = Evernote::EDAM::Type::Note.new
		note.title = "#{now.year}-#{now.month}-#{now.day}(#{now.hour}:#{now.min}:#{now.sec})"
		note.content = body.to_s
		note.notebookGuid = @note_store.getDefaultNotebook(@token).guid
		note.tagNames = tags if tags

		note
	end

	#"#tweetnote"を含むログイン中のTwitterアカウントによるツイートを取得、ノートの形式にデータを加工してEvernoteにアップロード
	#"--quit"を含むツイートを取得したらアプリケーションを終了する旨のリプライをユーザに送って終了する
	def search_tweet(track="#tweetnote")
		@twitclient.track_stream(track) do |status|
			if status["user"]["screen_name"] == @me["screen_name"] then
				status["text"].slice!("#{track}" + " ")
				unless status["text"].match(/.*--quit*./) then 
					hashtags = extract_tgas(status)
					note_content = tweet_demolish(status["text"], hashtags) 
					note = make_note(note_content, hashtags)

					begin
						@note_store.createNote(@token, note)
						puts "Successed cearted note. (at #{Time.now})"
					rescue => e
						@twitclient.update("@#{@me["screen_name"]} failed to upload the note. \n #{e}")
						puts "Field create note. (at #{Time.now})"
						puts "Exception that occurred is #{e}"
					end
				else 
					#@twitclient.update("@#{@me["screen_name"]} tweetnoteを終了します")
					puts "Disconnected."
					exit
				end
			end
		end
	end

	#OSがWin以外ならデーモン化する
	def observe
		puts "Boot TweetNote..."
		puts "Conected to Twitter and Evernote."
		#@twitclient.update("@#{@me["screen_name"]} tweetnoteを起動しました")
		require 'rbconfig'
		platform = RbConfig::CONFIG["target_os"].downcase
		os = platform =~ /mswin(?!ce)|mingw|cygwin|bccwin/ ? "win" : (platform =~ /linux/ ? "linux" : "other")

		unless os == "win" then
			Process.daemon
			puts "This is as daemon process."
		end

		loop do 
			self.search_tweet
		end
	end
end
