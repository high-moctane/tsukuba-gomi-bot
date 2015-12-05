require "date"
require "pp"
require_relative "../lib/bot"
require_relative "../lib/extend_date"

include Bot
include Extend_Date




account = $DEBUG ? :dev : :tsukuba_gominohi_bot

p = Bot::Project



p.log.info($0) {"起動"}
warn "#{$0} 起動"



mes_obj = Bot::Message.new

message = mes_obj.garb_regular

Bot::Bot.new(account).update(message)



p.log.info($0) {"終了"}
warn "#{$0} 終了"
