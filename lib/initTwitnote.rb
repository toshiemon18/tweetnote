#
#initTwitnote
#

#TwitNoteクラスのinitializie

$:.unshift File.dirname(__FILE__)

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

	private
		def setup
			config = InitTweetNote.new
		end
end