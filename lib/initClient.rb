#
#InitClient
#

#TweetlibのTweetlib::Clientのinitializeとトークン取得機構

$:.unshift File.dirname(__FILE__)

require 'initTweetnote'

class InitClient
	def initialize(keys)
		@consumer_key = keys[0]
		@consumer_secret = keys[1]
		@oauth_token = keys[2]
		@oauth_token_secret = keys[3]

		@consumer = OAuth::Consumer.new(
			@consumer_key,
			@consumer_secret,
			site:  "https://api.twitter.com"
		)

		if @oauth_token == nil || @oauth_token_secret == nil || @oauth_token.empty? || @oauth_token_secret.empty? then
			puts "Please access the following URL because there is no access token."
			buf_token = []
			buf_token = self.fetch_token
			@oauth_token = buf_token[0]
			@oauth_token_secret = buf_token[1]
		end

		@access_token = OAuth::AccessToken.new(
			@consumer,
			@oauth_token,
			@oauth_token_secret
	  	)
	end

	private
		def fetch_token
			request_token = @consumer.get_request_token
			puts "Please access this URL : \n#{request_token.authorize_url}"
			print "Please enter the PIN : "
			pin = STDIN.gets.chomp
			
			token = request_token.get_access_token(oauth_verifier: pin)

			setup_config = InitTweetNote.new("cnf/tweetnote_config.json")
			config = setup_config.get_config

			access_token = []
			access_token << token.token
			config["twitter"]["token"] = token.token.to_s
			access_token << token.secret
			config["twitter"]["token_secret"] = token.secret.to_s
			setup_config.update_keys(config)

			access_token
		end
end
