require "pp"
require "thread"
require_relative "bot/bot"
require_relative "garbage/garbage"
require_relative "project/project"
require_relative "extend_date/extend_date"

include Bot
include Project



Project.log.info("stream.rb 起動")


threads       = []
tweets        = Queue.new
normal_tweets = Queue.new
normal_reply  = Queue.new
dist_reply    = Queue.new
search_reply  = Queue.new



gomi_bot = Bot::Bot.new(:shakiin, stream: true)
# gomi_bot = Bot::Bot.new(:tsukuba_gominohi_bot, stream: true)

my_id = gomi_bot.twitter.user.id
my_screen_name = gomi_bot.twitter.user.screen_name



# TLからツイートを取得
threads << Thread.fork do
  begin
    gomi_bot.stream.userstream do |tweet|
      tweets.push(tweet)
      Project.log.debug("ストリーム検知")
    end
  rescue => e
    Project.log.fatal Project.log_message(e)
    raise
    abort
  end
end



# ツイートの種類を振り分ける
threads << Thread.fork do |tweet, data|
  loop do
    tweet = tweets.pop
    Project.log.debug("振り分け")

    data = {
      retweet?:                tweet.retweet?,
      reply?:                  tweet.reply?,
      user_id:                 tweet.user.id,
      in_reply_to_screen_name: tweet.in_reply_to_screen_name,
      text:                    tweet.text,
      id:                      tweet.id,
      screen_name:             tweet.user.screen_name,
    }

    # 絶対に処理しないやつ
    next if data[:retweet?]
    next if data[:user_id] == my_id


    # 振り分け開始
    if data[:reply?]
      if data[:in_reply_to_screen_name] == my_screen_name
        # 自分へのリプ
        normal_tweets.push(data)
      else
        # 他人へのリプ
        next
      end
    else
      # からリプ
      normal_tweets.push(data)
    end

  end
end



# ツイートを解析して返答を考える
threads << Thread.fork do |data, text, message|
  loop do
    data = normal_tweets.pop
    text = data[:text]
    message = text.split.delete_if { |item| /\A@/ === item }
    Project.log.debug("解析: #{data[:text].inspect}")

    case message[0]
    when /^(ごみ|ゴミ)($|(の(日|ひ)))/
      case message[1]
      when /^(東|ひがし)(地区)*/
        dist_reply.push [data, :East]
      when /^(西|にし)(地区)*/
        dist_reply.push [data, :West]
      when /^(南|みなみ)(地区)*/
        dist_reply.push [data, :South]
      when /^(北|北)(地区)*/
        dist_reply.push [data, :North]
      when /^燃やせる$/
        search_reply.push [data, :燃やせる]
      when /^燃やせない$/
        search_reply.push [data, :燃やせない]
      when /^ペットボトル$/
        search_reply.push [data, :ペットボトル]
      when /^粗大ごみ$/
        search_reply.push [data, :粗大ごみ]
      when /びん|スプレー/
        search_reply.push [data, :びん・スプレー容器]
      when /かん/
        search_reply.push [data, :かん]
      when /古紙|古布/
        search_reply.push [data, :古紙・古布]
      else
        normal_reply.push(data)
      end
    else
      # 形式通りでないやつ
      normal_reply.push(data) if data[:in_reply_to_screen_name] == my_screen_name
    end
  end
end



# 普通の返事をする
threads << Thread.fork do |data, message, now, garb|
  loop do
    data = normal_reply.pop
    Project.log.info("普通の返事: #{data[:text].inspect}")

    now  = DateTime.now
    garb = Garbage::Garbage.new(now)

    if now.hour < 12
      message = "今日 #{now.to_s(:ja)}\n"
      message << "#{garb.day.map { |a| a.join(": ") }.join("\n")}\n"
    else
      message = "明日 #{(now + 1).to_s(:ja)}\n"
      message << "#{garb.day(shift: 1).map { |a| a.join(": ") }.join("\n")}\n"
    end
    message << "です(｀･ω･´) #{now.strftime("%H:%M")}"

    gomi_bot.twitter.favorite(data[:id])
    gomi_bot.update(message, id: data[:id], id_name: data[:screen_name])
  end
end



# 地区ごとの返事をする
threads << Thread.fork do |dist, data, now, garb, message|
  loop do
    data, dist = dist_reply.pop
    Project.log.info("地区ごとの返事: #{data[:text].inspect}")

    now  = DateTime.now
    garb = Garbage::Garbage.new(now)

    message = "#{Project.lang[:ja][:dist_name][dist]}"
    message << "のごみは\n今日 "

    message << "#{garb.week(dist).map { |a| "#{a[0].to_s(:ja)}: #{a[1]}" }.join("\n")}\n"
    message << "です(｀･ω･´) #{now.strftime("%H:%M")}"

    gomi_bot.twitter.favorite(data[:id])
    gomi_bot.update(message, id: data[:id], id_name: data[:screen_name])
  end
end



# 次のゴミの日の検索結果を返す
threads << Thread.fork do |data, category, now, garb, category_name, message|
  loop do
    data, category = search_reply.pop
    Project.log.info("地区ごとの返事: #{data[:text].inspect}")

    now  = DateTime.now
    garb = Garbage::Garbage.new(now)

    category_name = Project.lang[:ja][:category_name]

    message = "次の#{category_name[category]}の回収日は"
    message << "#{garb.next_collect(category).map { |a| "#{a[0]}: #{a[1].to_s(:ja)}" } * "\n"}\n"
    message << "です(｀･ω･´) #{now.strftime("%H:%M")}"

    gomi_bot.twitter.favorite(data[:id])
    gomi_bot.update(message, id: data[:id], id_name: data[:screen_name])
  end
end


# これがないとすぐにプログラムが終了する
threads.map(&:join)


