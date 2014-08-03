#
#initTwitnote
#

#TwitNoteクラスのinitializie

$:.unshift File.dirname(__FILE__)

require_relative ".././cnf/config"
require 'tweetlib'
require 'rubygems'
require 'evernote_oauth'

class InitTwitNote

	attr_accessor :track_word
	attr_accessor :exit_command
	attr_accessor :heartbeat_command
	attr_accessor :feed_back

	def initialize
		@twitclient = Tweetlib::Client.new(TWITTER)
		@me = @twitclient.fetch_account_info
		@token = EVERNOTE[2]
		@client = EvernoteOAuth::Client.new(
				token: @token,
				consumer_key: EVERNOTE[0],
				consumer_secret: EVERNOTE[1],
				sandbox: SANDBOX
			)
		@track_word = "#tweetnote"
		@exit_command = "--quit"
		@heartbeat_command = "Yo"
		@feed_back = FEED_BACK
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
end