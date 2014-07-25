#-*-coding : utf-8 -*-

$:.unshift File.dirname(__FILE__)

require '.././lib/tweetlib'
require '.././cnf/config'

client = Tweetlib::Client.new(TWITTER)
show_hashtags = true
client.track_stream("#tweetnote") do |status|
	if status["text"] && show_hashtags then
		status["entities"]["hashtags"].each do |tag|
			status["text"].slice!("#" + "#{tag["text"]}" + " ")
		end
		puts status["text"]
	else 
		puts status["text"].to_s if status["text"]
	end
end
