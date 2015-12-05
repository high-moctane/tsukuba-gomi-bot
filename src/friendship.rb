require "pp"
require_relative "../lib/bot"

include Bot

P = Bot::Project

P.log.info($0) {"起動"}
warn "#{$0}: 起動"


gomi_bot = Bot::Bot.new(:tsukuba_gominohi_bot)


follower_ids         = gomi_bot.follower_ids
friend_ids           = gomi_bot.friend_ids
friendships_outgoing = gomi_bot.friendships_outgoing

new_follow   = follower_ids - friend_ids - friendships_outgoing
new_unfollow = friend_ids - follower_ids - friendships_outgoing


# フォロー
new_follow.sample(10).each do |id|
  data = gomi_bot.twitter.user(id).attrs

  # NOTE:
  #   当面は日本のアカウントのみフォロー
  #   botっぽいのもフォローしない
  if data[:lang] == "ja" \
    && data[:screen_name] !~ /[^r][^o]bot/i \
    && data[:name] !~ /bot|[^ロ]ボット|[^ろ]ぼっと/i \
    && data[:description] !~ /bot|[^ロ]ボット|[^ろ]ぼっと/i

    gomi_bot.follow(id)
  end
end


# リムーブ
new_unfollow.sample(10).each do |id|
  gomi_bot.unfollow(id)
end


P.log.info($0) {"終了"}
warn "#{$0}: 終了"
