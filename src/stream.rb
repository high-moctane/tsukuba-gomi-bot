require "pp"
require "thread"
require_relative "../lib/bot"
require_relative "../lib/extend_date"

include Bot

p = Bot::Project

p.log.info($0) {"stream.rb 起動"}


threads  = []
statuses = Queue.new


account  = $DEBUG ? :dev : :tsukuba_gominohi_bot
bot = Bot::Bot.new(account, stream: true)
bot_user = bot.twitter.user.attrs



# ----------------------------------------------------------------------
# TL からツイートを取得
#
# NOTE:
#   ここで使う変数は必ずスレッドでローカルな変数として
#   宣言しておくこと
#

threads << Thread.fork do |e|
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
      statuses.push({status: direct_message, dm?: true})

    }.on_error { |message|
      warn "on_error: #{message.inspect}\n"
      p.log.error($0) {"on_error: #{message.inspect}"}

    }.on_reconnect { |timeout, retries|
      warn "on_reconnect: 再接続\n"
      p.log.info($0) {"on_reconnect: #{[timeout.inspect, retries.inspect]}"}

    }.userstream { |tweet|
      statuses.push({status: tweet, dm?: false})

    }
  rescue => e
    p.log.fatal($0) {p.log_message(e)}
    raise
    abort
  end
end




# ----------------------------------------------------------------------
# 新しいストリームの実装
#
begin
  mes = Bot::Message.new
  limit_count = {}

  loop do
    status = statuses.pop
    trigger = false

    # ------------------------------------------------------------
    # data, trigger を構築
    # 入らないものも弾いてしまう
    #
    if status[:dm?]
      data = status[:status].attrs
      p.log.debug($0) {"on_direct_message: #{status.inspect}"}

      # 自分のには反応しない
      next if data[:sender][:id] == bot_user[:id]

      elements = data[:text].split(/\s|\p{blank}/)
      trigger = true
    else
      data = status[:status].attrs
      p.log.debug($0) {"userstream: #{status.inspect}"}

      # 絶対処理しないものを弾いてしまう
      next if data.key?(:retweeted_status)
      next if data[:user][:screen_name] == bot_user[:screen_name]
      next if data[:in_reply_to_user_id].nil?.! \
        && data[:in_reply_to_screen_name] != bot_user[:screen_name]

      elements = data[:text].split(/\s|\p{blank}/).reject { |i| /\A@/ === i }

      trigger = true if data[:in_reply_to_screen_name] == bot_user[:screen_name]
    end



    # ------------------------------------------------------------
    # elements からtrigger 要素を探す
    #
    if /^(ごみ|ゴミ|gomi)($|((の|no)(日|ひ|hi))|((出|だ|da)(し|si|shi)))/i === elements[0]
      trigger = true
      elements.delete_at(0)
    end


    # ------------------------------------------------------------
    # ここでアクションの定義をする
    #

    # now はローカル変数
    # 返事する場合はtrue, しない場合は false を返す
    limit_counter = ->(id: nil, now: Time.now) {
      id = status[:dm?] ? data[:sender][:id] : data[:user][:id]
      screen_name = status[:dm?] ? data[:sender][:screen_name] : data[:user][:screen_name]
      next true if screen_name == p.config[:admin_screen_name]

      if limit_count.key?(id)
        limit_count[id].reject! { |i| now - i > p.config[:limit_sec] }
        if limit_count[id].size >= p.config[:limit_count]
          p.log.info($0) {"reply_limit: #{status.inspect}"}
          next false
        else
          limit_count[id] << now
          next true
        end
      else
        limit_count[id] = [now]
        next true
      end
    }


    post = ->(message) {
      next unless limit_counter[]
      if status[:dm?]
        bot.dm(data[:sender][:id], message)
      else
        bot.update(
          message, id: data[:id], screen_name: data[:user][:screen_name]
        )
      end
    }


    favorite = -> {
      tmp_id = status[:dm?] ? data[:sender][:id] : data[:user][:id]
      next if p.user_config[:no_auto_fav].include?(tmp_id)
      if status[:dm?]
        post[mes.garb_regular]
      else
        next unless limit_counter[]
        bot.twitter.favorite(data[:id])
        p.log.info($0) {"favorite: #{status.inspect}"}
      end
    }




    # ------------------------------------------------------------
    # 内容を解析してアクションを起こす
    #
    case trigger
    when true
      # 管理者コマンド
      if status[:dm?] && p.config[:admin_screen_name].include?(data[:sender][:screen_name])
        case elements[0]
        when "kill"
          post["kill されます(´･ω･｀)"]
          warn "killed by admin\n"
          p.log.warn($0) {"killed by admin"}
          exit
        end
      end


      # 通常のもの
      case elements[0]
      when /^(東|ひがし|ヒガシ|higasi|higashi)/i
        post[mes.garb_dist(:東地区) + mes.garb_og_day(:東地区)]

      when /^(西|にし|ニシ|nisi|nishi)/i
        post[mes.garb_dist(:西地区) + mes.garb_og_day(:西地区)]

      when /^(南|みなみ|ミナミ|minami)/i
        post[mes.garb_dist(:南地区) + mes.garb_og_day(:南地区)]

      when /^(北|きた|kita)/i
        post[mes.garb_dist(:北地区) + mes.garb_og_day(:北地区)]

      when /^(燃|萌|も|mo)(やせ|え|yase|e)(る|ru)/i
        post[mes.garb_search(:燃やせるごみ)]

      when /^(燃|萌|も|mo)(やせ|え|yase|e)(ない|nai)/i
        post[mes.garb_search(:燃やせないごみ)]

      when /^(ペット|ぺっと|petto|pet)/i
        post[mes.garb_search(:ペットボトル)]

      when /^(粗大|そだい|sodai)/i
        post[mes.garb_search(:粗大ごみ) + mes.garb_og_day]

      when /^(びん|瓶|スプレー|bin|supure|splay)/i
        post[mes.garb_search(:びん・スプレー容器)]

      when /^(かん|缶|can|kan)/i
        post[mes.garb_search(:かん)]

      when /紙|布|^(koshi|kosi|kofu)/i
        post[mes.garb_search(:古紙・古布)]

      when /^(御神籤|(おみ|ごみ|ゴミ)くじ|omikuji|(占|うらな)い|ラッキー|(運勢|うんせい))/i
        post[mes.lucky_item]

      when *(p.place_name(:東地区))
        if status[:dm?]
          post[mes.garb_dist(:東地区) + mes.garb_og_day(:東地区)]
        else
          post["DMのみに対応した機能です(｀･ω･´)"]
        end

      when *(p.place_name(:西地区))
        if status[:dm?]
          post[mes.garb_dist(:西地区) + mes.garb_og_day(:西地区)]
        else
          post["DMのみに対応した機能です(｀･ω･´)"]
        end

      when *(p.place_name(:南地区))
        if status[:dm?]
          post[mes.garb_dist(:南地区) + mes.garb_og_day(:南地区)]
        else
          post["DMのみに対応した機能です(｀･ω･´)"]
        end

      when *(p.place_name(:北地区))
        if status[:dm?]
          post[mes.garb_dist(:北地区) + mes.garb_og_day(:北地区)]
        else
          post["DMのみに対応した機能です(｀･ω･´)"]
        end

      when /^((日|ひ)(付|づ))/
        post.(mes.garb_particular_day(elements[1]))

      when /^(今日|きょう)/
        post.(mes.garb_particular_day(Date.today.to_s))

      when /^(明日|あした)/
        post.(mes.garb_particular_day((Date.today + 1).to_s))

      when /^(明後日|あさって)/
        post.(mes.garb_particular_day((Date.today + 2).to_s))

      # TODO: この辺を lambda オブジェクトにしておきたい(｀･ω･´)
      when /(自動|じどう)(ファボ|ふぁぼ|fav|お(気|き)に(入|い)り)/i
        tmp_conf = p.user_config
        tmp_id = status[:dm?] ? data[:sender][:id] : data[:user][:id]
        case elements[1]
        when /on|オン|おん|設定|する/i
          tmp_conf[:no_auto_fav].reject! { |i| i == tmp_id }
          p.user_config(tmp_conf)
          post.("自動ふぁぼをオンにしました(｀･ω･´)")
        when /off|オフ|おふ|解除|しない/i
          tmp_conf[:no_auto_fav] << tmp_id
          p.user_config(tmp_conf)
          post.("自動ふぁぼをオフにしました(｀･ω･´)")
        else
          post.("オン か オフ で設定できます(｀･ω･´)")
        end

      when /(リマインダー|出し忘れ)/
        tmp_conf = p.user_config
        tmp_id = status[:dm?] ? data[:sender][:id] : data[:user][:id]
        case elements[1]
        when /on|オン|おん|設定|する/i
          tmp_conf[:morning_reminder].reject! { |i| i == tmp_id }
          p.user_config(tmp_conf)
          post.("リマインダー機能をオンにしました(｀･ω･´)")
        when /off|オフ|おふ|解除|しない/i
          tmp_conf[:morning_reminder] << tmp_id
          p.user_config(tmp_conf)
          post.("リマインダー機能をオフにしました(｀･ω･´)")
        else
          post.("オン か オフ で設定できます(｀･ω･´)")
        end

      else
        # 日付っぽいのは変換を試みて、うまくいったら日付検索機能を発動
        if (Date.parse_lang(elements[0], :ja) rescue nil).nil?.!
          post.(mes.garb_particular_day(elements[0]))

        else
          post[mes.garb_regular]

        end
      end
    else
      # 全文検索
      case data[:text]
      when /(起|お)き|むくり|おは/i
        tmp = "\n（これはごみ出し忘れ機能です。設定でオフにすることができます(｀･ω･´)）\n"
        tmp_id = status[:dm?] ? data[:sender][:id] : data[:user][:id]
        if p.user_config[:morning_reminder].include?(tmp_id) \
          && DateTime.now.hour.between?(4, 10)

          post.(mes.garb_regular + tmp)
        end
        post[mes.garb_regular + tmp] if DateTime.now.hour.between?(4, 10)

      when /^((ごみ|ゴミ)くじ|gomikuji)/i
        post[mes.lucky_item]

      when /(\(|（)(｀|`).ω.(´|')\)/
        favorite[]

      when /(\(|（)(´|').ω.(｀|`)\)/
        favorite[]

      when /ぽわ/
        favorite[]

      when /I-\('-ω-be\) をしながら/
        favorite[]

      when /🔥🔥🔥\n🔥🐧🔥\n🔥🔥🔥\n/
        favorite[]

      else
        # NOP

      end
    end
  end
rescue => e
  p.log.error($0) { p.log_message(e) }
  warn "error: #{e.message}"
  retry
end



# これがなくても困らないが、念のため
threads.map(&:join)

