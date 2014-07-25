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
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

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
		@track_word = "#tweetnote"
		@exit_command = "--quit"
		@feed_back = FEED_BACK
		
		begin
			@note_store = client.note_store
		rescue => e
			puts e
		end
	end

	#現在の設定状況をハッシュオブジェクトにして返す
	def validation
		validation = {"sandbox_mode" => "Sandbox mode : #{SANDBOX} ", 
				"send_reply_mode" => "Send reply mode : #{FEED_BACK}", 
				"logging_in_twitter_account" => "Logging Twitter account : #{@me["screen_name"].to_s}"
			}
	end

	#ツイートのJSONからハッシュタグを抽出
	def extract_tgas(status)
		hashtags = []
		cnt = 0
		status["entities"]["hashtags"].each do |tag|
			hashtags[cnt] = tag["text"].to_s
			cnt += 1
		end
		hashtags
	end

	#ツイート本文からハッシュタグを削除
	def tweet_demolish(status_text, hashtags)
		hashtags.each do |tag|
			status_text.to_s.slice!("#" + "#{tag}" + " ")
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

	#@track_wordの値を含むユーザーのツイートをノートの形式にデータを加工してEvernoteにアップロード
	#"--quit"を含むツイートを取得したらプログラムを終了する
	#FEED_BACK=trueの場合はリプライを送信
	def search_tweet
		@twitclient.track_stream(@track_word) do |status|
			if status["user"]["screen_name"] == @me["screen_name"] then
				if status["text"] then
					unless status["text"].match(/.*#{@exit_command}*./) then
						hashtags = extract_tgas(status)
						note_content = tweet_demolish(status["text"], hashtags)
						note = make_note(note_content, hashtags)

						begin
							@note_store.createNote(@token, note)
							puts "Successed cearted note. (at #{Time.now})"
							@twitclient.update("@#{@me["screen_name"]} ツイートをEvernoteへアップロードしました") if @feed_back
						rescue => e
							@twitclient.update("@#{@me["screen_name"]} ノートのアップロードに失敗しました \n #{e}")
							puts "Field create note. (at #{Time.now})"
							puts "Exception that occurred is #{e}"
						end
					else 
						@twitclient.update("@#{@me["screen_name"]} tweetnoteを終了します") if @feed_back
						puts "Disconnected."
						exit
					end
				end
			end
		end
	end

	#OSがWin以外ならデーモン化する
	#TL監視
	def observe
		validation = self.validation
		puts "Boot TweetNote..."
		validation.each_key do |key|
			puts validation[key]
		end
		puts "Conected to Twitter and Evernote."
		puts nil
		@twitclient.update("@#{@me["screen_name"]} tweetnoteを起動しました") if @feed_back
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
