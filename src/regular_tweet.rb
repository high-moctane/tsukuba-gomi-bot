require "date"
require "pp"
require_relative "../lib/bot"
require_relative "../lib/extend_date"

include Bot

account = $DEBUG ? :dev : :tsukuba_gominohi_bot

p = Bot::Project

p.log.info($0) {"起動"}
warn "#{$0} 起動"


now       = DateTime.now
garb      = Bot::Garbage.new(now)
lang_data = p.lang


shift = now.hour.between?(0, 11) ? 0 : 1

lang = [
  Array.new(8, :ja),
  Array.new(2, :en),
].flatten.sample


unless garb.any_collect?(shift: shift)
  p.log.info($0) { "ごみ収集なしのためつぶやかない" }
  warn "ごみ収集なしのためつぶやかない"
  exit
end


garb.localize(lang)


message =
  if shift == 0
    lang_data[lang][:today].to_s
  else
    lang_data[lang][:tomorrow].to_s
  end

message << <<"EOS"
: #{(now + shift).to_s(lang)}
#{garb.day(shift: shift).map { |o| o * ": " } * "\n" }
#{lang_data[lang][:footer]} #{now.strftime("%H:%m")}
EOS



Bot::Bot.new(account).update(message)


p.log.info($0) {"終了"}
warn "#{$0} 終了"
