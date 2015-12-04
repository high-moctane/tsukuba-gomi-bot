require "yaml"
require "twitter"
require "tweetstream"
require "logger"
require "pp"

require_relative "project"




# Bot module
module Bot
  include Project

  # twitterアカウント関連のことをする
  class Bot
    @@P = Project

    attr_reader :twitter, :stream


    def initialize(app_name, stream: false)
      keys = YAML.load_file(
        @@P.root_dir + "config/#{app_name}_keys.yml"
      )

      @twitter = init_twitter(keys)
      @stream  = init_tweetstream(keys) if stream
    rescue => e
      @@P.log.fatal($0) { @@P.log_message(e) }
      raise
    else
      @@P.log.debug($0) { "#{app_name} のBotインスタンス生成" }
    end


    # 普通のツイート
    def update(string, id: nil, screen_name: "")
      self.class.format_message(string, screen_name: screen_name).each do |str|
        obj = @twitter.update(str, {in_reply_to_status_id: id})
        id = obj.id

        @@P.log.info($0) {"post: #{str.inspect}"}
        warn "post:\n" + str + "\n"
      end
      true
    rescue => e
      @@P.log.error($0) {@@P.log_message(e)}
      false
    end



    # DM
    def dm(user, message)
      @twitter.create_direct_message(user, message)
    rescue => e
      @@P.log.error($0) { @@P.log_message(e) }
      false
    else
      @@P.log.info($0) { "DM: to: #{user}, message: #{message.inspect}" }
      warn "DM: #{message.inspect}\n"
      true
    end



    # フォロワーのIDリスト
    def follower_ids(account = nil)
      chain_cursor("follower_ids(#{account ? %{"#{account}"} : "nil"}, {cursor: cursor})")
    end



    # フォローのIDリスト
    def friend_ids(account = nil)
      chain_cursor("friend_ids(#{account ? %{"#{account}"} : "nil"}, {cursor: cursor})")
    end



    # フォロリク申請中のIDリスト
    def friendships_outgoing
      chain_cursor("friendships_outgoing({cursor: cursor})")
    end



    # フォローする
    def follow(id)
      @twitter.follow(id)
    rescue => e
      @@P.log.error($0) {@@P.log_message(e)}
      false
    else
      @@P.log.info($0) {"follow: #{id}"}
      true
    end



    # フォロー外す
    def unfollow(id)
      @twitter.unfollow(id)
    rescue => e
      @@P.log.error($0) {@@P.log_message(e)}
      false
    else
      @@P.log.info($0) {"unfollow: #{id}"}
      true
    end




    private

    # gem twitter のクライアントを生成
    def init_twitter(keys)
      Twitter::REST::Client.new do |config|
        config.consumer_key        = keys[:consumer_key]
        config.consumer_secret     = keys[:consumer_secret]
        config.access_token        = keys[:access_token]
        config.access_token_secret = keys[:access_token_secret]
      end
    rescue => e
      @@P.log.fatal($0) {@@P.log_message(e)}
      raise
    end



    # gem tweetstream のクライアントを生成
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
      @@P.log.fatal($0) {@@P.log_message(e)}
      raise
    end



    # カーソルで何回もデータをとってこなきゃいけないものに対応している
    def chain_cursor(method)
      ids = []
      cursor = -1
      while cursor != 0 do
        tmp = eval "@twitter.#{method}"
        cursor = tmp.attrs[:next_cursor]
        ids << tmp.attrs[:ids]
      end
    rescue => e
      @@P.log.error($0) {@@P.log_message(e)}
      nil
    else
      ids.flatten
    end



    # クラスメソッドにはTwitter関連のを入れる
    class << self

      # 140以内に適当に分割する
      # Note: 改行で優先的にきっている
      # FIXME: なんか連投すると最初が空文字列になる
      def format_message(message, screen_name: "")
        screen_name = "@" + screen_name + "\n" unless screen_name == ""
        footer = " " + [*0..9].sample(3).join
        main_size = 140 - screen_name.size - footer.size - 1
        ans = [""]
        i = 0
        message.scan(/^\n|.{1,#{140 - screen_name.size - footer.size}}/)
        .map { |s| s << "\n" }.each do |str|
          if (ans[i] + str).size > 140 - screen_name.size - footer.size
            i += 1
            ans[i] = ""
          end
          ans[i] << str
        end
        ans.map {|str| screen_name + str.chomp + footer}
      end
    end



  rescue => e
    @@P.log.fatal($0) { @@P.log_message(e) }
    raise
  end
end



# debug
if $0 == __FILE__
  include Bot
  message = <<"EOS"
彼は本郷の叔父さんの家から僕と同じ本所ほんじょの第三中学校へ通かよっていた。彼が叔父さんの家にいたのは両親のいなかったためである。両親のいなかったためと云っても、母だけは死んではいなかったらしい。彼は父よりもこの母に、――このどこへか再縁さいえんした母に少年らしい情熱を感じていた。彼は確かある年の秋、僕の顔を見るが早いか、吃どもるように僕に話しかけた。
「僕はこの頃僕の妹が（妹が一人あったことはぼんやり覚えているんだがね。）縁えんづいた先を聞いて来たんだよ。今度の日曜にでも行って見ないか？」
　僕は早速さっそく彼と一しょに亀井戸かめいどに近い場末ばすえの町へ行った。彼の妹の縁づいた先は存外ぞんがい見つけるのに暇ひまどらなかった。それは床屋とこやの裏になった棟割むねわり長屋ながやの一軒だった。主人は近所の工場こうじょうか何かへ勤つとめに行った留守るすだったと見え、造作ぞうさくの悪い家の中には赤児あかごに乳房ちぶさを含ませた細君、――彼の妹のほかに人かげはなかった。彼の妹は妹と云っても、彼よりもずっと大人おとなじみていた。のみならず切れの長い目尻めじりのほかはほとんど彼に似ていなかった
EOS
  pp _obj = Bot::Bot.new(:dev).update(message)
end
