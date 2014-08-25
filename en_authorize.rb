# -*- coding : utf-8 -*-

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))

require 'lib/initTweetnote'
require 'rubygems'
require 'oauth'
require 'evernote_oauth'
require 'openssl'
require 'sinatra'

enable :sessions

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

OAUTH_CONSUMER_KEY = "toshiemon18-4917"
OAUTH_CONSUMER_SECRET = "b5894e170c8a398b"
SANDBOX = false

puts nil
puts "Please access \"localhost://4567/\""
puts nil

helpers do
  def auth_token
    session[:access_token].token if session[:access_token]
  end

  def client
    @client ||= EvernoteOAuth::Client.new(
          token: auth_token, 
          consumer_key:OAUTH_CONSUMER_KEY, 
          consumer_secret:OAUTH_CONSUMER_SECRET, 
          sandbox: SANDBOX
      )
  end

  def user_store
    @user_store ||= client.user_store
  end

  def note_store
    @note_store ||= client.note_store
  end

  def en_user
    user_store.getUser(auth_token)
  end

  def notebooks
    @notebooks ||= note_store.listNotebooks(auth_token)
  end

  def total_note_count
    filter = Evernote::EDAM::NoteStore::NoteFilter.new
    counts = note_store.findNoteCounts(auth_token, filter, false)
    notebooks.inject(0) do |total_count, notebook|
      total_count + (counts.notebookCounts[notebook.guid] || 0)
    end
  end
end

get '/' do
  erb :index
end

get '/reset' do
  session.clear
  redirect '/'
end

get '/requesttoken' do
  callback_url = request.url.chomp("requesttoken").concat("callback")
  begin
    session[:request_token] = client.request_token(:oauth_callback => callback_url)
    redirect '/authorize'
  rescue => e
    @last_error = "Error obtaining temporary credentials: #{e}"
    erb :error
  end
end

get '/authorize' do
  if session[:request_token]
    redirect session[:request_token].authorize_url
  else
    # You shouldn't be invoking this if you don't have a request token
    @last_error = "Request token not set."
    erb :error
  end
end

get '/callback' do
  unless params['oauth_verifier'] || session['request_token']
    @last_error = "Content owner did not authorize the temporary credentials"
    halt erb :error
  end
  session[:oauth_verifier] = params['oauth_verifier']
  begin
    session[:access_token] = session[:request_token].get_access_token(:oauth_verifier => session[:oauth_verifier])
    redirect '/list'
  rescue => e
    @last_error = 'Error extracting access token'
    erb :error
  end
end

get '/list' do
  
  obj = InitTweetNote.new
  keys = obj.get_config
  keys["evernote"]["token"] = auth_token
  obj.update_keys(keys)

  begin
    # Get notebooks
    session[:notebooks] = notebooks.map(&:name)
    # Get username
    session[:username] = en_user.username
    # Get total note count
    session[:total_notes] = total_note_count
    erb :index
  rescue => e
    @last_error = "Error listing notebooks: #{e}"
    erb :error
  end
end

__END__

@@ index
<html>
<head>
  <title>Evernote Ruby Authorize Application</title>
</head>
<body>
  <a href="/requesttoken">Click here</a> to authenticate this application using OAuth.
  <% if session[:notebooks] %>
  <hr />
  <h3>The current user is <%= session[:username] %> and there are <%= session[:total_notes] %> notes in their account</h3>
  <br />
  <br />
  <h3>Here are the notebooks in this account:</h3>
  <ul>
    <% session[:notebooks].each do |notebook| %>
    <li><%= notebook %></li>
    <% end %>
  </ul>
  <% end %>
</body>
</html>

@@ error 
<html>
<head>
  <title>Evernote Ruby Authorize Application &mdash; Error</title>
</head>
<body>
  <p>An error occurred: <%= @last_error %></p>
  <p>Please <a href="/reset">start over</a>.</p>
</body>
</html>
