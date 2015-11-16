require "pp"
require_relative "./bot/Bot"
require_relative "./garbage/garbage"

include Bot
include Garbage



Account = $DEBUG ? :shakiin : :tsukuba_gominohi_bot


gomi_bot = Bot::Bot.new(Account)
today    = Date.today
garb     = Garbage::Garbage.new(today)


message = <<"EOS"
今日 #{garb.day}

明日 #{garb.day(1)}

です(｀･ω･´)
EOS


gomi_bot.post(message)


STDERR.puts "" ; puts :done
