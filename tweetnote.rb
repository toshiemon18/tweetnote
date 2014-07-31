#-*- coding : utf-8 -*-
#
#Tweetnote
#

#TwitterからEvernoteへアップロードする

require './lib/twitnote'

#
app_name = "tweetnote"

tweetnote = TwitNote.new(app_name)
tweetnote.observe
