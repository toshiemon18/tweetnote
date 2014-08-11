#
#initTwitnote
#

#TwitNoteクラスのinitializie

$:.unshift File.dirname(__FILE__)

require_relative '../cnf/config'
require 'tweetlib'
require 'initTweetnote'
require 'rubygems'
require 'evernote_oauth'
require 'json'

class InitTwitNote

	attr_accessor :track_word
	attr_accessor :exit_command
	attr_accessor :heartbeat_command

	def initialize
		twitter_config = setup.twitter_setup
		evernote_config = setup.evernote_setup
		tweetnote_config = setup.tweetnote_setup

		@twitclient = Tweetlib::Client.new(twitter_config.values)
		@me = @twitclient.fetch_account_info
		@token = evernote_config["token"]
		@client = EvernoteOAuth::Client.new(
				token: @token,
				consumer_key: evernote_config["consumer_key"],
				consumer_secret: evernote_config["consumer_secret"],
				sandbox: tweetnote_config["sandbox"]
			)
		
		@track_word = tweetnote_config["track_word"]
		@exit_command = tweetnote_config["exit_command"]
		@heartbeat_command = tweetnote_config["heartbeat_command"]
		@feed_back = tweetnote_config["feed_back"]

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
		config_path = "cnf/tweetnote_config.json"
		config = InitTweetNote.new(config_path)
	end
end
