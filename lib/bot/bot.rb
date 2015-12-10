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
    def update(string, id: nil, screen_name: "", try: 3, footer: "")
      footer = self.class.random_footer
      self.class.format_message(string, screen_name: screen_name, footer: footer).each do |str|
        obj = @twitter.update!(str, {in_reply_to_status_id: id})
        id = obj.id

        @@P.log.info($0) {"post: #{str.inspect}"}
        warn "post:\n" + str + "\n"
      end

    rescue Twitter::Error::DuplicateStatus => e
      @@P.log.error($0) { "post_error: DuplicateStatus: #{string}" }
        warn "duplicate:\n" + string + "\n"
      if try > 1
        warn "post_retry: #{string}\n"
        update(string, id: id, screen_name: screen_name, try: try - 1, footer: self.class.random_footer)
      end
      false

    rescue => e
      @@P.log.error($0) {@@P.log_message(e)}
      false

    else
      true

    end



    # DM
    def dm(user, message)
      message += " #{self.class.random_footer}"
      @twitter.create_direct_message(user, message)
    rescue => e
      @@P.log.error($0) { @@P.log_message(e) }
      warn "DM_error: #{@@P.log_message(e)}"
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
      puts "Twitter_id #{id} をフォローしました"
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
      puts "Twitter_id #{id} をリムーブしました"
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
      def format_message(message, screen_name: "", footer: "")
        screen_name = "@" + screen_name + "\n" unless screen_name == ""
        footer = " " + footer unless footer == ""
        main_size = 140 - screen_name.size - footer.size
        ans = [""]
        i = 0
        message.scan(/.{,#{main_size}}\n|.{1,#{main_size}}/).each do |str|
          if (ans[i] + str).size > main_size + 1
            i += 1
            ans[i] = ""
          end
          ans[i] << str
        end
        ans.map {|str| screen_name + str.chomp.chomp + footer}
      end



      def random_footer
        [*0..9].sample(3).join
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
end
