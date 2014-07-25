#-*- coding : utf-8 -*-

CONFIG = <<CNF

TWITTER = []
TWITTER << "YOURCONSUMERKEY"
TWITTER << "YOURCONSUMERSECRET"
TWITTER << "YOUROAUTHTOKEN"
TWITTER << "YOUROAUTHTOKENSECRET"

EVERNOTE = []
EVERNOTE << "YOURCONSUMERKEY"
EVERNOTE << "YOURCONSUMERSECRET"
EVERNOTE << "YOURTOKEN"
#Evernoteのサンドボックスモードで動作させるか
#trueでサンドボックスモード有効
#デフォルトではfalseが設定されます
SANDBOX = false

#起動時とノート作成時、プログラム終了時にリプライを自身に対し送信します
#デフォルトではtrueになっており、リプライが送信されます
#リプライがうざったらしいと感じたならfalseにすることを推奨します
FEED_BACK = true

CNF

class ConfigGenerator
	def initialize(name)
		@file_name = name.to_s
		@name = "./cnf/" + name + ".rb"
	end

	def generate
		exist = true
		Dir::glob("#{@file_name}.rb") do |file|
			exist = false if !(file == "#{@file_name}.rb")
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
			puts "#{@file_name}.rb already exist!"
		end
	end
end

generator = ConfigGenerator.new("config")
generator.generate
