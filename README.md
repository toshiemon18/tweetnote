TweetNote
==========

##Installation
###Requirements
System : 

	Ruby2.0.0
gems:

	bundle
	evernote_oauth
	oauth
	sinatra

###Install gem
	bundle install

##Application Setup
###Evernote Authenticate
	ruby en_authorize.rb
上記のコマンドを実行し、ブラウザで以下のリンクに移動し、自身のEvernoteアカウントでこのアプリケーションを承認してください．
[localhost:4567/](localhost:4567/)

###Twitter Authenticate
アクセストークンが無い場合はtweetnote.rbを起動した時に承認用URLが表示されます．
その承認用URLにアクセスし、自身のアカウントでこのアプリケーションを承認し、表示されたPINを入力してください．(アクセストークンは自動で保存されるハイ・テックなシステムです．)

###TweetNote Config
cnf/action_config.jsonを編集することでアプリケーションの動作を変えることが出来ます．
```
{
	"action":{
		"sandbox": false, // EvernoteをSandbox環境で利用するか (デフォルトではfalse)
		"feed_back": true // 動作をリプライで通知する (デフォルトではtrue)
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

  このとき、Twitterのアクセストークンが未取得の場合は承認用URLが表示されます．
"#tweenote"を付けてツイートするとEvernoteに保存されます．

##開発環境
Windows 8.1 x64  
Ruby 2.0.0p481(i386-mingw32)

#実装予定の機能
1, 追記モード  
 ~~ 2, プラグイン機能の実装 ~~   
3, 画像添付機能
