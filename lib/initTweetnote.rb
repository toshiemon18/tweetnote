# -*- coding : utf-8 -*-
# 
# InitTweetnote
# 

# Tweetnote関係のクラスを初期化する

$:.unshift File.dirname(__FILE__)

require 'json'

class InitTweetNote

	def initialize
		@tweetnote_config = File.open("cnf/tweetnote_config.json") do |io|
			JSON::load(io)
		end
		@action_config = File.open("cnf/action_config.json") do |io|
			JSON::load(io)
		end
	end

	def update_keys(json_data)
		File.open(@path, "w") do |io|
			JSON::dump(json_data, io)
		end
	end

	def get_config
		@json_config
	end

	def tweetnote_setup
		@action_config
	end

	def twitter_setup
		twitter_config = {}
		twitter_config = @tweetnote_config["twitter"]
	end

	def evernote_setup
		evernote_config = {}
		evernote_config = @tweetnote_config["evernote"]
	end
end