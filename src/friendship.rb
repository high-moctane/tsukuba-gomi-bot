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


# ----------------------------------------------------------------------
# フォロー
#
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
  else
    # botっぽかったりするのは自動フォローの対象外
    config[:skip_follow] << id
  end

  # 鍵垢の人は次から自動フォローの対象外
  if data[:protected]
    config[:skip_follow] << id
    p.log.info($0) { "#{id} を :skip_follow に追加" }
    puts "#{$0}: #{id} を :skip_follow に追加"
  end
end


# ----------------------------------------------------------------------
# リムーブ
#
new_unfollow.sample(10).each do |id|
  gomi_bot.unfollow(id)
end



# ----------------------------------------------------------------------
# friendship.yml のアップデート
#
File.open(config_dir, "w") { |f| YAML.dump(config, f) }




p.log.info($0) {"終了"}
warn "#{$0}: 終了"
