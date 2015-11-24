# coding: utf-8

require "yaml"
require "twitter"
require "tweetstream"
require "pp"
require "logger"

require_relative "../project/project"

include Project



# Bot module
module Bot
  # twitterアカウント関連のことをする
  class Bot
    attr_reader :twitter, :stream


    def initialize(app_name, stream: false)
      keys = YAML.load_file(
        Project.root + "/lib/config/#{app_name}_keys.yml"
      )

      @twitter = init_twitter(keys)
      @stream  = init_tweetstream(keys) if stream
    rescue => e
      Project.log.fatal Project.log_message(e)
      raise
    else
      Project.log.debug "#{app_name} のインスタンス生成完了"
    end


    def update(string, id: nil, id_name: "")
      self.class.format_message(string, id_name: id_name).each do |str|
        obj = @twitter.update(str, {in_reply_to_status_id: id})
        id = obj.id

        Project.log.info("post: #{str.inspect}")
        warn "post:"
        warn str
      end
    rescue => e
      Project.log.error Project.log_message(e)
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
      Project.log.fatal Project.log_message(e)
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
      Project.log.fatal Project.log_message(e)
      raise
    end



    # クラスメソッドにはTwitter関連のを入れる
    class << self
      # 140以内に適当に分割する
      # Note: 改行で優先的にきっている
      def format_message(message, id_name: "")
        id_name = "@" + id_name + "\n" unless id_name == ""
        ans = [""]
        i = 0
        message.scan(/^\n|.{1,#{140 - id_name.size}}/)
        .map { |s| s << "\n" }.each do |str|
          if (ans[i] + str).size > 140 - id_name.size
            i += 1
            ans[i] = ""
          end
          ans[i] << str
        end



        pp ans.map {|str| id_name + str}
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
  pp a = Bot::Bot.new(:shakiin, stream: true)
  a.stream.userstream do |o|
    if /ぽわ/ === o.text
      a.twitter.favorite(o)
    end
  end
end
