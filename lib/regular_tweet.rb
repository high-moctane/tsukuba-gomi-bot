require "./Bot"
require "pp"

include Bot

gomi_bot = Bot::Bot.new(:tsukuba_gominohi_bot)


today = DateTime.now


data = YAML.load_file("2015_11.yml")
data.each_value do |hash|
  hash.default = :収集なし
end

string = <<"EOF"
今日（#{today.day}日）
西地区：#{data[:West][today.day]}
東地区：#{data[:East][today.day]}

明日（#{today.day + 1}日）
西地区：#{data[:West][today.day + 1]}
東地区：#{data[:East][today.day + 1]}

です(｀･ω･´)
EOF


gomi_bot.post(string)








puts "" ; puts :done
