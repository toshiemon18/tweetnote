# -*- coding : utf-8 -*-
# 
# InitTweetnote
# 

 # Tweetnote関係のクラスを初期化する

require 'json'

class InitTweetNote

	def initialize(path)
		@path = path
		@json_config = File.open(@path) do |io|
			JSON.load(io)
		end
	end

	def update_json(json_data)
		File.open(@path, "w") do |io|
			JSON.dump(json_data, io)
		end
	end

	def get_config
		@json_config
	end

	def twitter_setup
		twitter_config = {}
		twitter_config = @json_config["twitter"]
	end

	def evernote_setup
		evernote_config = {}
		evernote_config = @json_config["evernote"]
	end

	def tweetnote_setup
		tweetnote_config = {}
		tweetnote_config = @json_config["tweetnote"]
	end
end