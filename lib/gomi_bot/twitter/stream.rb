require "active_support/core_ext/class/subclasses"
require "thread"

module GomiBot
  module Twitter
    class Stream
      def initialize(account = nil)
        @client = GomiBot::Twitter::Client.new(account: account, stream: true)
        @client_id = @client.twitter.user.id
        @threads = []
        @tweets = Queue.new
        @dms    = Queue.new
      end

      def run
        if @threads.empty?
          @threads << Thread.new { generate_reply }
          @threads << Thread.new { generate_dm }
          @threads << Thread.new { stream }
        else
          false
        end
      end

      def kill
        unless @threads.empty?
          @threads.map(&:kill)
        end
      end

      # private

      def generate_reply
        loop do
          tweet = @tweets.pop
          reply_generator.new(tweet_generator_list, @client, tweet.attrs).call
        end
      end

      def generate_dm
        loop do
          dm = @dms.pop
          dm_generator.new(dm_generator_list, @client, dm.attrs).call
        end
      end

      def stream
        @client.stream
        .on_inited {
          GomiBot.logger.info "Stream: サーバ接続完了"

        }.on_limit { |skip_count|
          GomiBot.logger.error "Stream: API規制 | #{skip_count}"

        }.on_error { |message|
          GomiBot.logger.error "Stream: エラー | #{message.inspect}"

        }.on_reconnect { |timeout, retries|
          GomiBot.logger.error "Stream: 再接続 | #{timeout}, #{retries}"

        }.on_direct_message { |dm|
          @dms << dm

        }.userstream { |tweet|
          @tweets << tweet

        }
      end

      def reply_generator
        @reply_generator ||= GomiBot::Twitter::ReplyGenerator
      end

      def dm_generator
        @dm_generator ||= GomiBot::Twitter::DMGenerator
      end

      def all_message_generator
        GomiBot::Message::GeneratorTemplate.subclasses
      end

      # TODO: ここにavoidのリストを受け付けるようにする
      def tweet_generator_list
        all_message_generator
      end

      def dm_generator_list
        all_message_generator
      end

    end
  end
end