# -*- coding : utf-8 -*-
# 
# InitTweetnote
# 

# Tweetnoteに必要なキーやコマンドをJSONからハッシュに変換する

$:.unshift File.dirname(__FILE__)

require 'json'

class InitTweetNote

	def initialize
		@tweetnote_config = JSON::parse(File.read("cnf/tweetnote_config.json"))
		@action_config = JSON::parse(File.read("cnf/action_config.json"))
	end

	def update_keys(hash_obj)
		File.open("cnf/tweetnote_config.json", "w") do |io|
			JSON::dump(hash_obj, io)
		end
	end

	def get_config
		@tweetnote_config
	end

	def tweetnote_setup
		@action_config
	end

	def twitter_setup
		twitter_config = {}
		return twitter_config = @tweetnote_config["twitter"]
	end

	def evernote_setup
		evernote_config = {}
		return evernote_config = @tweetnote_config["evernote"]
	end
end
