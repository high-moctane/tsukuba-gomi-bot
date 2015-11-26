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


    # TODO: この辺の繰り返しを綺麗にしたい
    def follower_ids(account = nil)
      ids = []
      cursor = -1
      while cursor != 0 do
        tmp = @twitter.follower_ids(account, {cursor: cursor})
        cursor = tmp.attrs[:next_cursor]
        ids << tmp.attrs[:ids]
      end
    rescue => e
      Project.log.error Project.log_message(e)
      nil
    else
      ids.flatten
    end


    def friend_ids(account = nil)
      ids = []
      cursor = -1
      while cursor != 0 do
        tmp = @twitter.friend_ids(account, {cursor: cursor})
        cursor = tmp.attrs[:next_cursor]
        ids << tmp.attrs[:ids]
      end
    rescue => e
      Project.log.error Project.log_message(e)
      nil
    else
      ids.flatten
    end


    def friendships_outgoing
      ids = []
      cursor = -1
      while cursor != 0 do
        tmp = @twitter.friendships_outgoing({cursor: cursor})
        cursor = tmp.attrs[:next_cursor]
        ids << tmp.attrs[:ids]
      end
    rescue => e
      Project.log.error Project.log_message(e)
      nil
    else
      ids.flatten
    end


    def follow(id)
      @twitter.follow(id)
    rescue => e
      Project.log.error Project.log_message(e)
      false
    else
      Project.log.info "follow: #{id}"
      true
    end


    def unfollow(id)
      @twitter.unfollow(id)
    rescue => e
      Project.log.error Project.log_message(e)
      false
    else
      Project.log.info "unfollow: #{id}"
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
        ans.map {|str| id_name + str}
      end
    end
  end
end



# debug
if $0 == __FILE__
  include Bot
  bot = Bot::Bot.new(:dev)
  pp bot.follower_ids
  pp bot.friend_ids
  pp bot.friendships_outgoing
end