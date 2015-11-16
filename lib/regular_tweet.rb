require "date"
require "pp"
require_relative "./bot/bot"
require_relative "./garbage/garbage"

include Bot
include Garbage



Account = $DEBUG ? :shakiin : :tsukuba_gominohi_bot


gomi_bot = Bot::Bot.new(Account)
now      = DateTime.now
garb     = Garbage::Garbage.new(now)


message = <<"EOS"
今日 #{garb.day}

明日 #{garb.day(1)}

です(｀･ω･´) #{now.strftime("%H:%M")}
EOS


gomi_bot.post(message)
