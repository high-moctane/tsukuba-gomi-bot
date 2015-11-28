require "date"
require "pp"
require_relative "../lib/bot"
require_relative "../lib/extend_date"

include Bot

account = $DEBUG ? :dev : :tsukuba_gominohi_bot

P = Bot::Project

P.log.info($0) {"起動"}
warn "#{$0} 起動"


gomi_bot = Bot::Bot.new(account)
now      = DateTime.now
garb     = Bot::Garbage.new(now)



message = ""
if now.hour < 12
  exit unless garb.any_collect?
  message << "今日 #{now.to_date.to_s(:ja)}\n"
  message << "#{garb.day.map { |o| o.join(": ") }.join("\n")}\n"
else
  exit unless garb.any_collect?(shift: 1)
  message << "明日 #{(now + 1).to_date.to_s(:ja)}\n"
  message << "#{garb.day(shift: 1).map { |o| o.join(": ") }.join("\n")}\n"
end

message << "です(｀･ω･´) #{now.strftime("%H:%M")}"


gomi_bot.update(message)


P.log.info($0) {"終了"}
warn "#{$0} 終了"
