#coding : utf-8

require 'rubygems'
require 'evernote_oauth'
require 'json'
require 'openssl'
require '.././lib/noteheader'
require '.././cnf/config'

token = EVERNOTE[2]
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
client = EvernoteOAuth::Client.new(:token => token, :sandbox => true)
note_store = client.note_store
puts client.methods



note_content = <<CONTENT
#{NOTE_HEADER}
<en-note>はろーるびー！！はろーえばーのーと！！！</en-note>
CONTENT

note = Evernote::EDAM::Type::Note.new
note.title = "Test Note"
note.content = note_content

begin 
	note_store.createNote(token, note)
rescue Exception => e
	puts "Exception!! #{e}"
	exit
end
