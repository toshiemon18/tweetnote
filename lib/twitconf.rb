#-*- coding : utf-8 -*-
#
#TwitConf
#

#Twitterでログイン中のアカウントの情報とか返すクラス
#名前とかスクリーンネームとか
#必要になり次第逐次メソッドを追加する予定

$:.unshift File.dirname(__FILE__)
require 'rubygems'
require 'oauth'
require 'tweetlib'
require_relative ".././cnf/config"

class TwitConf
	class Client
		def initialize(keys)
			consumer_key = keys[0]
			consumer_secret = keys[1]
			oauth_token = keys[2]
			oauth_token_secret = keys[3]

			@consumer = OAuth::Consumer.new(
				consumer_key,
				consumer_secret,
				{site:  "https://api.twitter.com/"}
			)

			if oauth_token.empty? || oauth_token == nil || oauth_token_secret.empty? || oauth_token_secret == nil then
				puts "Please access the following URL because there is no access token."
				buf_token = []
				buf_token = self.token_fetch
				oauth_token = buf_token[0]
				oauth_token_secret = buf_token[1]
			end

			@access_token = OAuth::AccessToken.new(
				@consumer,
				oauth_token,
				oauth_token_secret
		  	)

		end

		def fetch_token
			request_token = @consumer.get_request_token

			puts "Please access this URL. : #{request_token.authorize_url}"
			puts "Please enter the PIN. : "
			pin = STDIN.gets.chomp

			token = request_token.get_access_token(
				oauth_token: request_token.token,
				oauth_verifier: pin
			)

			access_token = []
			access_token << token.token.to_s
			access_token << token.secret.to_s

			access_token
		end

		def fetch_account_info
			response = @access_token.get("/1.1/account/verify_credentials.json")
			JSON.parse(response.body)
		end
	end

	def initialize
		@client = Client.new(TWITTER)
		@usrinfo = @client.fetch_account_info
	end

	def name
		@usrinfo["name"]
	end

	def screen_name
		@usrinfo["screen_name"]
	end

	def protected?
		@usrinfo["protected"]
	end

	def location
		@usrinfo["location"]
	end

	def time_zone
		@usrinfo["time_zone"]
	end

	def lang
		@usrinfo["lang"]
	end
end
