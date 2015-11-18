require "pp"
require_relative "bot/bot"
require_relative "garbage/garbage"

include Bot

Bot.log.info("stream.rb 起動")

gomi_bot = Bot::Bot.new(:tsukuba_gominohi_bot)
now = DateTime.now
garb = Garbage::Garbage.new(now)

puts string = <<"EOS"
今日は #{garb.day}
明日は #{garb.day(1)}
です(｀･ω･´) #{now.strftime("%H:%M")}
EOS

gomi_bot.stream.userstream do |tweet|
  pp tweet
  if /^ごみ$/ === tweet.text
    Bot.log.info("ごみ ツイート発見")

    tweet.user.screen_name
    message = "@#{tweet.user.screen_name}\n"
    message << string
    gomi_bot.twitter.favorite(tweet)

    if message.size <= 140
      gomi_bot.post(message)
    else
      post("140字超えちゃった(´; ω ;｀)")
      Bot.log.error("140字オーバー")
    end
  end
end

