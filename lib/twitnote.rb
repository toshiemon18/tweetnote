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
				"exit_command" => @exit_command,
				"heartbeat_command" => @heartbeat_command
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

	#終了コマンドが含まれているツイートを取得したらプロセスを終了する
	def process_exit(status_text)
		if status_text.match(/.*#{@exit_command}*./) then
			@twitclient.update("@#{@me["screen_name"]} tweetnoteを終了します") if @feed_back
			puts "Disconnected."
			exit
		end
	end

	#プロセスが生きてるかを確認するためのメソッド
	#生きていればTrue
	def process_exist?(status_text)
		status_text.match(/.*#{@heartbeat_command}*./)
	end

	# プロセスが生きていればリプライで通知する
	def heartbeat
		@twitclient.update("@#{@me["screen_name"]} 生きてるYo!!")
	end

	# ツイートからノートのオブジェクトをセットアップする
	def note_setup(status)
		hashtags = self.extract_tgas(status)
		note_content = self.tweet_demolish(status["text"], hashtags)
		note = self.make_note(note_content, hashtags)
	end

	#@track_wordの値を含むユーザーのツイートをノートの形式にデータを加工してEvernoteにアップロード
	#FEED_BACK=trueの場合はリプライを送信
	def search_tweet
		@twitclient.track_stream(@track_word) do |status|
			if status["user"]["screen_name"] == @me["screen_name"] then
				self.process_exit(status["text"])
				if self.process_exist?(status["text"]) then
					self.heartbeat
				else
					note =self.note_setup(status)
					begin
						@note_store.createNote(@token, note)
						puts "Successed cearted note. (at #{Time.now})"
						@twitclient.update("@#{@me["screen_name"]} ツイートをEvernoteへアップロードしました") if @feed_back
					rescue => e
						@twitclient.update("@#{@me["screen_name"]} ノートのアップロードに失敗しました \n #{e}")
						puts "Field create note. (at #{Time.now})"
						puts "Exception that occurred is #{e}"
					end
				end
			end
		end
	end

	# 設定状況を表示
	def print_config
		validation = self.validation
		puts "SandBox mode 			: #{validation["sandbox_mode"]}"
		puts "Send reply mode 		: #{validation["send_reply_mode"]}"
		puts "Logging in Twitter Account 	: #{validation["logging_in_twitter_account"]}"
		puts "Track word 			: #{validation["track_word"]}"
		puts "Exit command 			: #{validation["exit_command"]}"
		puts "Heartbeat command 		: #{validation["heartbeat_command"]}"
	end

	#OSがWin以外ならデーモン化する
	#TL監視
	def observe
		puts "Boot TweetNote..."
		self.print_config
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
