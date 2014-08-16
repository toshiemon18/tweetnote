#-*- coding : utf-8 -*-
#
#Tweetnote
#

#TwitterからEvernoteへアップロードする

require './lib/twitnote.rb'

TwitNote.new.monitoring_timeline
