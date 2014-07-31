#-*- coding : utf-8 -*-
#
# TwitNote
#

#ツイートをEvernoteのノートに加工してアップロードするためのクラス
#ハッシュタグの抽出とかツイートからハッシュタグを分離するメソッドとかあるから他でも使えるかもしれない

$:.unshift File.dirname(__FILE__)

require 'initTwitnote'
require 'noteheader'
require 'rubygems'
require 'openssl'

#なんかこの一行がないとEvernote側の通信がこける
#そのくせ警告だして来るしたぶんEvernoteOauthが悪い
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class TwitNote < InitTwitNote

	#現在の設定状況をハッシュオブジェクトにして返す
	def validation
		validation = {"sandbox_mode" => SANDBOX, 
				"send_reply_mode" => FEED_BACK, 
				"logging_in_twitter_account" => @me["screen_name"].to_s,
				"track_word" => @track_word,
				"wxit_commad" => @exit_command
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

	#ノートのオブジェクトを生成して返す
	def setup_note(status)
		hashtags = extract_tgas(status)
		note_content = tweet_demolish(status["text"], hashtags)
		note = make_note(note_content, hashtags)
	end

	#@track_wordの値を含むユーザーのツイートをノートの形式にデータを加工してEvernoteにアップロード
	#"--quit"を含むツイートを取得したらプログラムを終了する
	#FEED_BACK=trueの場合はリプライを送信
	def search_tweet
		@twitclient.track_stream(@track_word) do |status|
			if status["user"]["screen_name"] == @me["screen_name"] then
				if status["text"] then
					unless status["text"].match(/.*#{@exit_command}*./) then
						note = setup_note(status)
						
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
						puts nil
						puts "Disconnected."
						exit
					end
				end
			end
		end
	end

	def print_config

	end

	#OSがWin以外ならデーモン化する
	#TL監視
	def observe
		puts "Boot TweetNote..."
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
