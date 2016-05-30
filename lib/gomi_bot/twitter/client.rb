require "tweetstream"
require "twitter"
require "yaml"

module GomiBot
  module Twitter
    class Client
      attr_reader :twitter, :stream

      RETRY_COUNT = 3
      RETRY_INTERVAL = 3
      MAX_MESSAGE_LENGTH = 140

      def initialize(account: nil, stream: false)
        account ||=
          $DEBUG ? GomiBot.config[:account][:debug] : GomiBot.config[:account][:default]
        keys        = load_keys(account)
        @twitter    = init_twitter(keys)
        @stream     = init_tweetstream(keys) if stream

      rescue => e
        GomiBot.logger.fatal {
          "#{account} のTwitterインスタンス生成失敗 #{GomiBot.logger_message(e)}"
        }
        raise

      else
        GomiBot.logger.debug "#{account} のTwitterインスタンス生成完了"
      end

      def id
        @client_id ||= @twitter.user.id
      end

      def screen_name
        @client_screen_name ||= @twitter.user.screen_name
      end

      def update(message, in_reply_to_status_id: nil, screen_name: nil)
        id = in_reply_to_status_id
        retry_count     ||= RETRY_COUNT
        gen_message(message, screen_name: screen_name).each do |str|
          status = @twitter.update!(str, in_reply_to_status_id: id)
          id = status.id
        end

      rescue ::Twitter::Error => e
        GomiBot.logger.error {
         "投稿エラー | #{screen_name} | #{message.inspect} #{GomiBot.logger_message(e)}"
        }
        sleep RETRY_INTERVAL
        retry_count = retry_count - 1
        retry if retry_count >= 0

      else
        GomiBot.logger.info "つぶやき完了 | #{screen_name} | #{message.inspect}"
      end

      def dm(user, message)
        retry_count ||= RETRY_COUNT
        @twitter.create_direct_message(user, message.chomp + gen_footer)

      rescue ::Twitter::Error => e
        GomiBot.logger.error {
         "DMエラー | #{message.inspect} #{GomiBot.logger_message(e)}"
        }
        sleep RETRY_INTERVAL
        retry_count = retry_count - 1
        retry if retry_count >= 0

      else
        GomiBot.logger.info "DM完了 | #{user.inspect} | #{message.inspect}"
      end

      def follow(id)
        @twitter.follow(id)
      rescue ::Twitter::Error => e
        GomiBot.logger.error {
         "followエラー | id: #{id} #{GomiBot.logger_message(e)}"
        }
      else
        GomiBot.logger.info "follow完了 | id: #{id}"
      end

      def unfollow(id)
        @twitter.unfollow(id)
      rescue ::Twitter::Error => e
        GomiBot.logger.error {
         "unfollowエラー | id: #{id} #{GomiBot.logger_message(e)}"
        }
      else
        GomiBot.logger.info "unfollow完了 | id: #{id}"
      end

      def follower_ids
        chain_cursor(:follower_ids)
      end

      def friend_ids
        chain_cursor(:friend_ids)
      end

      def friendships_outgoing
        chain_cursor(:friendships_outgoing)
      end

      # private

      def init_twitter(keys)
        ::Twitter::REST::Client.new do |config|
          config.consumer_key         = keys[:consumer_key]
          config.consumer_secret      = keys[:consumer_secret]
          config.access_token         = keys[:access_token]
          config.access_token_secret  = keys[:access_token_secret]
        end
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
      end

      def load_keys(account)
        YAML.load_file(GomiBot.config_dir + ".twitter_keys.yml")[account]
      end

      def gen_header(screen_name)
        if screen_name.nil?
          ""
        else
          "@#{screen_name}\n"
        end
      end

      def gen_footer
        footer_fiber.resume
      end

      def footer_fiber
        footer_list ||= YAML.load_file(GomiBot.db_dir + "footer_emoji.yml")
        next_time ||= footer_list
        fib ||= Fiber.new do
          this_time = next_time.sample
          next_time = footer_list.reject { |v| v == this_time }
          Fiber.yield this_time
        end
      end

      def gen_message(message, screen_name:)
        header            = gen_header(screen_name)
        footer            = gen_footer
        length            = MAX_MESSAGE_LENGTH - header.size - footer.size
        splited_message   = split_message(message, length)
        splited_message.map { |body| header + body + footer }
      end

      def split_message(message, length)
        message.scan(/.{1,#{length}}/m).map(&:chomp)
      end

      def chain_cursor(method)
        ans = []
        cursor = -1
        until cursor == 0
          obj = @twitter.send(method, {cursor: cursor})
          cursor = obj.attrs[:next_cursor]
          ans << obj.attrs[:ids]
        end
        ans.flatten

      rescue ::Twitter::Error => e
        GomiBot.logger.error {
         "chain_cursorエラー | method: #{method} #{GomiBot.logger_message(e)}"
        }
      end

    end
  end
end
