require "pp"
require "thread"
require_relative "../lib/bot"
require_relative "../lib/extend_date"

include Bot

p = Bot::Project

p.log.info($0) {"stream.rb 起動"}


threads = []
tweets  = Queue.new


account = $DEBUG ? :dev : :tsukuba_gominohi_bot

bot = Bot::Bot.new(account, stream: true)

bot_data = bot.twitter.user.attrs


# ----------------------------------------------------------------------
# 返事などのアクションを定義する
#

# NOTE: 確実にローカル変数化しておきたいなら引数に置いておけばいいのかも(｀･ω･´)
# NOTE: 引数に data を取らなくていいように、この段階で data を定義しておこう(｀･ω･´)
# NOTE: 必要な時だけ garb を更新するようにする仕様

data = {}
garb = Bot::Garbage.new(DateTime.now)

# --------------------------------------------------
# 普通の返事をする
#
regular_reply = ->(message: "") {
  p.log.info($0) { "regular_reply: #{data[:text].inspect}" }
  now  = DateTime.now
  garb = Bot::Garbage.new(now) unless garb.date == now.to_date

  shift = now.hour.between?(0, 11) ? 0 : 1

  message = <<-"EOS"
#{%w(今日 明日)[shift]} #{now.to_lang(:ja)}
#{garb.day(shift: shift).map { |a| a * ": " } * "\n"}
です(｀･ω･´) #{now.strftime("%H:%M")}
  EOS

  bot.twitter.favorite(data[:id])
  bot.update(message, id: data[:id], id_name: data[:screen_name])
}


# --------------------------------------------------
# 地区別の返事をする
#
dist_reply = ->(dist, message: "") {
  p.log.info($0) { "dist_reply: #{data[:text].inspect}" }
  now  = DateTime.now
  garb = Bot::Garbage.new(now) unless garb.date == now.to_date

  message = <<-"EOS"
#{dist}のごみは
今日 #{garb.week(dist).map { |a| "#{a[0].to_lang(:ja)}: #{a[1]}" } * "\n"}
です(｀･ω･´) #{now.strftime("%H:%M")}
  EOS

  bot.twitter.favorite(data[:id])
  bot.update(message, id: data[:id], id_name: data[:screen_name])
}


# --------------------------------------------------
# ごみ検索の返事をする
#
search_reply = ->(category, message: "") {
  p.log.info($0) { "search_reply: #{data[:text].inspect}" }
  now  = DateTime.now
  garb = Bot::Garbage.new(now) unless garb.date == now.to_date

  message = <<-"EOS"
次の#{category}の回収日は
#{garb.next_collect(category).map { |a| "#{a[0]}: #{a[1].to_lang(:ja)} (#{"%d" % a[2]}日後)" } * "\n"}
です(｀･ω･´) #{now.strftime("%H:%M")}
  EOS

  bot.twitter.favorite(data[:id])
  bot.update(message, id: data[:id], id_name: data[:screen_name])
}


# --------------------------------------------------
# ふぁぼるだけ
#
only_favorite = -> {
  p.log.info($0) { "only_favorite : #{data[:text].inspect}" }
  bot.twitter.favorite(data[:id])
}


# --------------------------------------------------
# おみくじ機能
#
lucky_item = ->(message: "", garb_list: nil, prob: nil, item: nil) {
  p.log.info($0) { "lucky_item: #{data[:text].inspect}" }
  now  = DateTime.now

  # NOTE:
  #   とりあえず[連番, 出やすさ, ごみ名称]みたいな感じで
  #   なんかいいアルゴリズムないの(´･ω･｀)？
  # TODO: とりあえず連番くらいはメソッドで追加できそう
  garb_list = [
    [0, 10, "燃やせるごみ"],
    [1, 10, "燃やせないごみ"],
    [2, 5,  "びん"],
    [3, 5,  "かん"],
    [4, 5,  "スプレー容器"],
    [5, 10, "粗大ごみ"],
    [6, 5,  "ペットボトル"],
    [7, 5,  "古紙"],
    [8, 5,  "古布"],
    [9, 1,  "ごみの日bot(｀･ω･´)"],
  ]

  item = garb_list.map { |a| [a[0]] * a[1] }.flatten.sample
  prob = garb_list[item][1].fdiv(garb_list.inject(0) {|sum, a| sum + a[1]})


  message = <<-"EOS"
今日のラッキーアイテムは
  #{garb_list[item][2]} (出現率#{"%.1f" % (prob * 100)}％)
です(｀･ω･´) #{now.strftime("%H:%M")}
  EOS

  bot.twitter.favorite(data[:id])
  bot.update(message, id: data[:id], id_name: data[:screen_name])
}








# ----------------------------------------------------------------------
# TL からツイートを取得
#

threads << Thread.fork do
  p.log.info($0) { "TL監視準備開始" }
  warn "TL監視準備開始\n"
  begin
    bot.stream.on_inited {

      warn "サーバ接続完了\n"
      p.log.info($0) {"on_inited: サーバ接続完了"}

    }.on_limit { |skip_count|

      warn "on_limit: API規制\n"
      p.log.error($0) {"on_limit: API規制"}
      # todo:
      #   ここでワーカースレッドを停止させるようにしたい？

    }.on_direct_message { |direct_message|

      # todo: 実装まだ
      warn :on_direct_message
      p.log.debug($0) {"on_direct_message: #{direct_message.inspect}"}

    }.on_error { |message|

      warn "on_error: #{message.inspect}\n"
      p.log.error($0) {"on_error: #{message.inspect}"}

    }.on_reconnect { |timeout, retries|

      warn "on_reconnect: 再接続完了\n"
      p.log.info($0) {"on_reconnect: #{[timeout.inspect, retries.inspect]}"}

    }.userstream { |tweet|

      tweets.push(tweet)

    }
  rescue => e
    p.log.fatal($0) {P.log_message(e)}
    raise
    abort
  end
end


# ----------------------------------------------------------------------
# ツイートを解析してアクションを起こす
#

threads << Thread.fork do |tweet|
  p.log.info($0) { "解析準備開始" }
  warn "解析準備開始\n"
  loop do
    tweet = tweets.pop

    data = tweet.attrs
    data[:screen_name] = tweet.user.screen_name

    p.log.debug($0) {"ストリーム: #{data[:text].inspect}"}


    # --------------------------------------------------
    # 処理しないものはここで next して弾く
    #

    next if data.key?(:retweeted_status)
    next if data[:screen_name] == bot_data[:screen_name]
    next if data[:in_reply_to_user_id].nil?.! && data[:in_reply_to_screen_name] != bot_data[:screen_name]


    # --------------------------------------------------
    # 内容を解析してアクションを起こす
    #

    text = data[:text]
    message = text.split.delete_if { |item| /\A@/ === item }
    p.log.debug($0) {"解析: #{data[:text].inspect}"}

    # TODO: 自分へのリプの場合は "ごみ" とかいらないと思うので、
    #   そういうのいらない実装をする。

    # 部分的に検索
    case message[0]
    when /^(ごみ|ゴミ|gomi)($|((の|no)(日|ひ|hi)))/i
      case message[1]
      when /^(東|ひがし|ヒガシ|higasi|higashi)/i
        dist_reply[:東地区]
      when /^(西|にし|ニシ|nisi|nishi)/i
        dist_reply[:西地区]
      when /^(南|みなみ|ミナミ|minami)/i
        dist_reply[:南地区]
      when /^(北|きた|kita)/i
        dist_reply[:北地区]
      when /^(燃|萌|も|mo)(やせ|え|yase|e)(る|ru)/i
        search_reply[:燃やせるごみ]
      when /^(燃|萌|も|mo)(やせ|え|yase|e)(ない|nai)/
        search_reply[:燃やせないごみ]
      when /^(ペット|ぺっと|petto|pet)/i
        search_reply[:ペットボトル]
      when /^(粗大|そだい|sodai)/i
        search_reply[:粗大ごみ]
      when /^(びん|瓶|スプレー|bin|supure|splay)/i
        search_reply[:びん・スプレー容器]
      when /^(かん|缶|can|kan)/i
        search_reply[:かん]
      when /紙|布|^(koshi|kosi|kofu)/i
        search_reply[:古紙・古布]
      when /^(御神籤|(おみ|ごみ|ゴミ)くじ|omikuji|(占|うらな)い|ラッキー|(運勢|うんせい))/i
        lucky_item[]
      else
        regular_reply[]
      end
    else
      # 全文を検索する
      case data[:text]
      when /(起|お)き|むくり|おは/i
        regular_reply[] if DateTime.now.hour.between?(4, 10)
      when /(\(|（)(｀|`)(･|・)ω(･|・)(´|')\)/
        only_favorite[]
      when /(\(|（)(´|')(･|・)ω(･|・)(｀|`)\)/
        only_favorite[]
      when /(\(|（)(´|')(;|；)ω(;|；)(｀|`)\)/
        only_favorite[]
      when /ぽわ(ー|〜)/
        only_favorite[]
      when /I-\('-ω-be\) をしながら/
        only_favorite[]
      else
        regular_reply[] if data[:in_reply_to_screen_name] == bot_data[:screen_name]
      end
    end

  end
end




p.log.info($0) { "スレッド起動完了" }
warn "スレッド起動完了\n"


# これがないとすぐにプログラムが終了する
threads.map(&:join)
