require "pp"
require_relative "./bot/Bot"

include Bot

# gomi_bot = Bot::Bot.new(:tsukuba_gominohi_bot)
gomi_bot = Bot::Bot.new(:shakiin)


today = DateTime.now


calendar_dir = File.expand_path("../data/calendar", __FILE__)
data = YAML.load_file("#{calendar_dir}/2015_11.yml")
data.each_value do |hash|
  hash.default = :収集なし
end

string = <<"EOF"
今日（#{today.day}日）
北地区：#{data[:North][today.day]}
西地区：#{data[:West][today.day]}
東地区：#{data[:East][today.day]}
南地区：#{data[:South][today.day]}

明日（#{today.day + 1}日）
北地区：#{data[:North][today.day + 1]}
西地区：#{data[:West][today.day + 1]}
東地区：#{data[:East][today.day + 1]}
南地区：#{data[:South][today.day + 1]}

です(｀･ω･´)
EOF


gomi_bot.post(string)








puts "" ; puts :done
