#
#initTwitnote
#

#TwitNoteクラスのinitializing

$:.unshift File.dirname(__FILE__)
require_relative ".././cnf/config"
require 'tweetlib'
require 'rubygems'
require 'evernote_oauth'

class InitTwitNote

	attr_accessor :track_word
	attr_accessor :exit_command
	attr_accessor :feed_back

	def initialize(key_word)
		@twitclient = Tweetlib::Client.new(TWITTER)
		@me = @twitclient.fetch_account_info
		@token = EVERNOTE[2]
		client = EvernoteOAuth::Client.new(
				token: @token,
				consumer_key: EVERNOTE[0],
				consumer_secret: EVERNOTE[1],
				sandbox: SANDBOX
			)
		@track_word = "#"+ "#{key_word}"
		@exit_command = "--quit"
		@feed_back = FEED_BACK
		begin
			@note_store = client.note_store
		rescue => e
			puts e
		end
	end
end