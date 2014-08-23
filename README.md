TweetNote
==========

##Installation
	bundle install

##Setup
	ruby en_authorize.rb
ブラウザで以下のリンクに移動し、自身のEvernoteアカウントでこのアプリケーションを承認してください.
[localhost:4567/](localhost:4567/ "localhost:4567/")

cnf/action_config.jsonを編集することでアプリケーションの動作を変えることが出来ます.
```
{
	"action":{
		"sandbox": false, // EvernoteをSandbox環境で利用するか
		"feed_back": true // 動作をリプライで通知する
	},
	"commands":{
		"track_word":"#tweetnote", // アップロードするツイートを仕分けるためのハッシュタグ
		"exit_command":"--quit", // アプリケーションを終了するコマンド
		"heartbeat_command":"Yo" // プロセスが生きているか確認するコマンド
	}
}
```

##Usage
	ruby tweetnote.rb
