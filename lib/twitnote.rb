#-*- coding : utf-8 -*-
#
# TwitNote
#

#ツイートをEvernoteのノートに加工してアップロードするためのクラス
#ハッシュタグの抽出とかツイートからハッシュタグを分離するメソッドとかあるから他でも使えるかもしれない

$:.unshift File.dirname(__FILE__)

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

	attr_accessor :track_word
	attr_accessor :exit_command
	attr_accessor :heartbeat_command

	def initialize
		twitter_config = setup.twitter_setup
		evernote_config = setup.evernote_setup
		@tweetnote_config = setup.tweetnote_setup

		@twitclient = Tweetlib::Client.new(twitter_config.values)
		@me = @twitclient.fetch_account_info
		@token = evernote_config["token"]
		@client = EvernoteOAuth::Client.new(
			token: @token,
			consumer_key: evernote_config["consumer_key"],
			consumer_secret: evernote_config["consumer_secret"],
			sandbox: @tweetnote_config["action"]["sandbox"]
		)
		
		@track_word = @tweetnote_config["commands"]["track_word"]
		@exit_command = @tweetnote_config["commands"]["exit_command"]
		@heartbeat_command = @tweetnote_config["commands"]["heartbeat_command"]
		@feed_back = @tweetnote_config["action"]["feed_back"]

		begin
			@note_store = @client.note_store
		rescue => e
			puts e
		end

		begin
			@user_store = @client.user_store
		rescue  => e
			puts e
		end
	end

	def setup
		config = InitTweetNote.new
	end

	def validation
		validation = {
			"sandbox_mode" => @tweetnote_config["action"]["sandbox"],
			"send_reply_mode" => @tweetnote_config["action"]["feed_back"],
			"logging_in_twitter_account" => @me["screen_name"],
			"track_word" => @track_word,
			"exit_command" => @exit_command,
			"heartbeat_command" => @heartbeat_command
		}
	end

	def print_config
		validation = self.validation
		puts "SandBox mode 			: #{validation["sandbox_mode"]}"
		puts "Send reply mode 		: #{validation["send_reply_mode"]}"
		puts "Logging in Twitter Account 	: #{validation["logging_in_twitter_account"]}"
		puts "Track word 			: #{validation["track_word"]}"
		puts "Exit command 			: #{validation["exit_command"]}"
		puts "Heartbeat command 		: #{validation["heartbeat_command"]}"
	end

	def check_tweet_text(status)
		sign = false
		status["entities"]["hashtags"].each do |tag|
			sign = true if tag["text"] == @track_word
		end
		return sign
	end

	def extract_tgas(status)
		hashtags = []
		cnt = 0
		status["entities"]["hashtags"].each do |tag|
			hashtags[cnt] = tag["text"] unless tag["text"] == "tweetnote"
			cnt += 1
		end
		return hashtags
	end

	def tweet_demolish(status_text, hashtags)
		tweet_text = status_text
		hashtags.each do |tag|
			tweet_text.to_s.slice!("#" + "#{tag}" + " ")
		end
		return tweet_text.to_s.slice!("#tweetnote ")
	end

	def process_exist?(status_text)
		status_text.match(/.*#{@heartbeat_command}*./)
	end

	def heartbeat
		@twitclient.update("@#{@me["screen_name"]} ✋(   ͡° ͜ʖ ͡° ) (͡° ͜ʖ ͡°   )✋")
	end

	def process_exit(status_text)
		if status_text.match(/.*#{@exit_command}*./) then
			@twitclient.update("@#{@me["screen_name"]} Tweetnoteを終了します。") if @feed_back
			puts "\nDisconnected. #{Time.now}"
			exit
		end
	end

	def make_note(text, tags=nil)
		now = Time::now
		note = Evernote::EDAM::Type::Note.new
		note.title = "#{now.year}-#{now.month}-#{now.day}(#{now.hour}:#{now.min}:#{now.sec})"
		note.content = "#{NOTE_HEADER}<en-note>#{text}</en-note>"
		note.notebookGuid = @note_store.getDefaultNotebook(@token).guid
		note.tagNames = tags if tags
		return note
	end

	def note_setup(status)
		hashtags = self.extract_tgas(status)
		note_content = self.tweet_demolish(status["text"], hashtags)
		note = self.make_note(note_content, hashtags)
		return note
	end

	# @track_wordが含まれているログイン中のアカウントのツイートを取得したらノートをアップロードする
	# コマンドに応じて対応する動作も行う
	def upload_note
		@twitclient.user_stream do |status|
			if status["text"] then
				if status["user"]["screen_name"] == @me["screen_name"]  && !(status["retweeted"]) then
					self.process_exit(status["text"])
					if self.process_exist?(status["text"]) then
						self.heartbeat

					elsif check_tweet_text(status) then
						begin
							@note_store.createNote(@token, self.note_setup(status))
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
	end

	# プログラムを起動したプラットフォームを調べる
	# Winならfalse
	# UNIX系、その他のOSならばtrue
	def check_os
		require 'rbconfig'
		platform = RbConfig::CONFIG["target_os"].downcase
		os = platform =~ /mswin(?!ce)|mingw|cygwin|bccwin/ ? "win" : (platform =~ /linux/ ? "linux" : "other")
		if os != "win" then
			return true
		else
			return false
		end
	end

	#TL監視
	def monitoring_timeline
		puts "Boot TweetNote..."
		self.print_config
		puts "Conected to Twitter and Evernote."
		puts nil
		@twitclient.update("@#{@me["screen_name"]} tweetnoteを起動しました") if @feed_back
		if @tweetnote_config["action"]["daemon_process_mode"] || self.check_os then 
			Process.daemon
			puts "This is as daemon process."
		end

		loop do 
			self.upload_note
		end
	end
end
