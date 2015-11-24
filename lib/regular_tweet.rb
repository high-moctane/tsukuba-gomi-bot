require "date"
require "pp"
require_relative "bot/bot"
require_relative "garbage/garbage"
require_relative "extend_date/extend_date"
require_relative "project/project"

include Bot
include Garbage
include Project

account = $DEBUG ? :dev : :tsukuba_gominohi_bot


Project.log.info("regular_tweet.rb を起動しました")


gomi_bot = Bot::Bot.new(account)
now      = DateTime.now
garb     = Garbage::Garbage.new(now)


message = ""
if now.hour < 12
  message << "今日 #{now.to_date.to_s(:ja)}\n"
  message << "#{garb.day.map { |o| o.join(": ") }.join("\n")}\n"
else
  message << "明日 #{(now + 1).to_date.to_s(:ja)}\n"
  message << "#{garb.day(shift: 1).map { |o| o.join(": ") }.join("\n")}\n"
end

message << "です(｀･ω･´) #{now.strftime("%H:%M")}"


gomi_bot.update(message)


Project.log.info("regular_tweet.rb を正常終了しました")
