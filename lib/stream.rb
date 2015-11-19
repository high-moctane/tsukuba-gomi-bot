require "pp"
require_relative "bot/bot"
require_relative "garbage/garbage"

include Bot

Bot.log.info("stream.rb 起動")

gomi_bot = Bot::Bot.new(:tsukuba_gominohi_bot)

gomi_bot.stream.userstream do |tweet|
  if /^ごみ$/ === tweet.text && tweet.in_reply_to_status_id == nil
    Bot.log.info("ごみ ツイート発見")

    now = DateTime.now
    garb = Garbage::Garbage.new(now)

    message = "@#{tweet.user.screen_name}\n"

    string = <<"EOS"
今日は #{garb.day}
明日は #{garb.day(1)}
です(｀･ω･´) #{now.strftime("%H:%M")}
EOS

    message << string
    gomi_bot.twitter.favorite(tweet)

    if message.size <= 140
      gomi_bot.twitter.update(message, {in_reply_to_status_id: tweet.id})
    else
      gomi_bot.twitter.update(
        "@#{tweet.user.screen_name} 140字超えちゃった(´; ω ;｀)",
        {in_reply_to_status_id: tweet.id}
      )
      Bot.log.error("140字オーバー")
    end
  end
end

