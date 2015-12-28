require "pp"
require_relative "../lib/bot"
require "yaml"

include Bot

p = Bot::Project

p.log.info($0) {"起動"}
warn "#{$0}: 起動"


# ----------------------------------------------------------------------
# 初期化
#
gomi_bot   = Bot::Bot.new(:tsukuba_gominohi_bot)
config_dir = p.root_dir + "config/friendship.yml"
config     = YAML.load_file(config_dir)

follower_ids         = gomi_bot.follower_ids
friend_ids           = gomi_bot.friend_ids
friendships_outgoing = gomi_bot.friendships_outgoing

new_follow   = (follower_ids | config[:follow]) - friend_ids \
  - friendships_outgoing - config[:unfollow] - config[:skip_follow]
new_unfollow = (friend_ids | config[:unfollow]) - follower_ids \
  - friendships_outgoing - config[:follow] - config[:skip_unfollow]

p.log.info($0) { "follower_ids: " + follower_ids.inspect }
p.log.info($0) { "friend_ids: " + friend_ids.inspect }
p.log.info($0) { "friendships_outgoing: " + friendships_outgoing.inspect }
p.log.info($0) { "new_follow: " + new_follow.inspect }
p.log.info($0) { "new_unfollow: " + new_unfollow.inspect }


# ----------------------------------------------------------------------
# フォロー
#
new_follow.sample(10).each do |id|
  data = gomi_bot.twitter.user(id).attrs
  config[:skip_follow] << id
  p.log.info($0) { "#{id} を :skip_follow に追加" }
  puts "#{$0}: #{id} を :skip_follow に追加"

  # NOTE:
  #   当面は日本のアカウントのみフォロー
  #   botっぽいのもフォローしない
  if data[:lang] == "ja" \
    && data[:screen_name] !~ /[^r][^o]bot/i \
    && data[:name] !~ /bot|[^ロ]ボット|[^ろ]ぼっと/i \
    && data[:description] !~ /bot|[^ロ]ボット|[^ろ]ぼっと/i \
    && data[:favourites_count] > 0

    gomi_bot.follow(id)
  end
end


# ----------------------------------------------------------------------
# リムーブ
#
# NOTE: 一時停止中

# new_unfollow.sample(10).each do |id|
  # gomi_bot.unfollow(id)
# end



# ----------------------------------------------------------------------
# friendship.yml のアップデート
#
File.open(config_dir, "w") { |f| YAML.dump(config, f) }




p.log.info($0) {"終了"}
warn "#{$0}: 終了"
