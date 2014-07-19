#coding : utf-8

CONFIG = <<CNF
#coding : utf-8

TWITTER = []
TWITTER << "YOURCONSUMERKEY"
TWITTER << "YOURCONSUMERSECRET"
TWITTER << "YOUROAUTHTOKEN"
TWITTER << "YOUROAUTHTOKENSECRET"

EVERNOTE = []
EVERNOTE << "YOURCONSUMERKEY"
EVERNOTE << "YOURCONSUMERSECRET"
EVERNOTE << "YOURTOKEN"
SANDBOX = false  # true or false (デフォルトではfalseです)

CNF

class ConfigGenerator
	def initialize(name)
		@name = "./cnf/" + name + ".rb"
	end

	def generate
		exist = true
		Dir::glob("config.rb") do |file|
			exist = false if !(file == "configgenerator.rb")
		end
		if !exist then
			begin
				file = File.open(@name, "w+:utf-8")
				file.puts CONFIG
			rescue => e
				puts e
				retry
			end
		else
			puts "config.rb already exist!"
		end
	end
end

generator = ConfigGenerator.new("config")
generator.generate