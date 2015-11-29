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


    def update(string, id: nil, id_name: "")
      self.class.format_message(string, id_name: id_name).each do |str|
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


    def follower_ids(account = nil)
      chain_cursor("follower_ids(#{account ? %{"#{account}"} : "nil"}, {cursor: cursor})")
    end


    def friend_ids(account = nil)
      chain_cursor("friend_ids(#{account ? %{"#{account}"} : "nil"}, {cursor: cursor})")
    end


    def friendships_outgoing
      chain_cursor("friendships_outgoing({cursor: cursor})")
    end


    def follow(id)
      @twitter.follow(id)
    rescue => e
      @@P.log.error($0) {@@P.log_message(e)}
      false
    else
      @@P.log.info($0) {"follow: #{id}"}
      true
    end


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
        ans.map {|str| id_name + str}
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
  pp _obj = Bot::Bot.new(:dev)
end
