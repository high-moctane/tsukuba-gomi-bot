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


now       = DateTime.now
garb      = Bot::Garbage.new(now)


shift = now.hour.between?(0, 11) ? 0 : 1

unless garb.any_collect?(shift: shift)
  p.log.info($0) { "ごみ収集なしのためつぶやかない" }
  warn "ごみ収集なしのためつぶやかない"
  exit
end



message = <<"EOS"
#{%w(今日 明日)[shift]} #{(now + shift).to_lang(:ja)}
#{garb.day(shift: shift).map { |o| o * ": " } * "\n" }
です(｀･ω･´) #{now.strftime("%H:%M")}
EOS


Bot::Bot.new(account).update(message)


p.log.info($0) {"終了"}
warn "#{$0} 終了"
