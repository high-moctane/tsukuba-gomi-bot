# coding: utf-8

require "yaml"
require "twitter"
require "tweetstream"
require "pp"
require "logger"



# Bot module
module Bot
  # あたかもなんかのインスタンスのようにつかう
  # Note: ここはスクリプト全体のものを定義する
  def root
    File.expand_path("../../../", __FILE__)
  end

  def config
    YAML.load_file(root + "/lib/config/config.yml")
  end

  def log
    level = {
      FATAL: Logger::FATAL,
      ERROR: Logger::ERROR,
      WARN:  Logger::WARN,
      INFO:  Logger::INFO,
      DEBUG: Logger::DEBUG,
    }

    logger = Logger.new(root + "/log/" + config[:logfile_name])

    logger.level =
      if $DEBUG
        level[config[:log_level_debug]]
      else
        level[config[:log_level]]
      end

    logger
  end



  # twitterアカウント関連のことをする
  class Bot
    attr_reader :twitter, :stream


    def initialize(app_name, stream: false)
      keys = YAML.load_file(
        Bot.root + "/lib/config/#{app_name}_config.yml"
      )

      @twitter = init_twitter(keys)
      @stream  = init_tweetstream(keys) if stream
    rescue => e
      Bot.log.fatal "#{e.backtrace[0]} / #{e.message}"
      raise
    else
      Bot.log.debug "#{app_name} のインスタンス生成完了"
    end


    # Todo: 140字超えたときの対応とかどうにかしないといけない
    # Todo: リプを送れるようにしないといけない
    def update(string, id: nil, id_name: "")
      Bot.format_message(string, id_name: id_name).each do |str|
        obj = @twitter.update(str, {in_reply_to_status_id: id})
        id = obj.id
        Bot.log.info("post: #{string.inspect}")
      end
    rescue => e
      Bot.log.error "#{e.backtrace[0]} / #{e.message}"
    end



    private


    def init_twitter(keys)
      Twitter::REST::Client.new do |config|
        config.consumer_key        = keys[:consumer_key]
        config.consumer_secret     = keys[:consumer_secret]
        config.access_token        = keys[:access_token]
        config.access_token_secret = keys[:access_token_secret]
      end
    rescue => e
      Bot.log.fatal "#{e.backtrace[0]} / #{e.message}"
      raise
    end


    def init_tweetstream(keys)
      TweetStream.configure do |config|
        config.consumer_key       = keys[:consumer_key]
        config.consumer_secret    = keys[:consumer_secret]
        config.oauth_token        = keys[:access_token]
        config.oauth_token_secret = keys[:access_token_secret]
        config.auth_method        = :oauth
      end

      TweetStream::Client.new
    rescue => e
      Bot.log.fatal "#{e.backtrace[0]} / #{e.message}"
      raise
    end



    # クラスメソッドにはTwitter関連のを入れる
    class << self
      # 140以内に適当に分割する
      # Note: 改行で優先的にきっている
      def format_message(message, id_name: "")
        id_name = "@" + id_name + "\n" unless id_name == ""
        ans = message.scan(/^\n|.{1,#{140 - id_name.size}}/)
        ans.map {|str| id_name + str}
      end
    end
  end
end



# debug
if $0 == __FILE__
  str = <<"EOS"
これはある精神病院の患者、――第二十三号がだれにでもしゃべる話である。彼はもう三十を越しているであろう。が、一見したところはいかにも若々しい狂人である。彼の半生の経験は、――いや、そんなことはどうでもよい。彼はただじっと両膝りょうひざをかかえ、時々窓の外へ目をやりながら、（鉄格子てつごうしをはめた窓の外には枯れ葉さえ見えない樫かしの木が一本、雪曇りの空に枝を張っていた。）院長のＳ博士や僕を相手に長々とこの話をしゃべりつづけた。もっとも身ぶりはしなかったわけではない。彼はたとえば「驚いた」と言う時には急に顔をのけぞらせたりした。……
　僕はこういう彼の話をかなり正確に写したつもりである。もしまただれか僕の筆記に飽き足りない人があるとすれば、東京市外××村のＳ精神病院を尋ねてみるがよい。年よりも若い第二十三号はまず丁寧ていねいに頭を下げ、蒲団ふとんのない椅子いすを指さすであろう。それから憂鬱ゆううつな微笑を浮かべ、静かにこの話を繰り返すであろう。最後に、――僕はこの話を終わった時の彼の顔色を覚えている。彼は最後に身を起こすが早いか、たちまち拳骨げんこつをふりまわしながら、だれにでもこう怒鳴どなりつけるであろう。――「出て行け！　この悪党めが！　貴様も莫迦ばかな、嫉妬しっと深い、猥褻わいせつな、ずうずうしい、うぬぼれきった、残酷な、虫のいい動物なんだろう。出ていけ！　この悪党めが！」
EOS
  include Bot
  a = Bot::Bot.new(:dev)
  a.update("(｀･ω･´)")
end
