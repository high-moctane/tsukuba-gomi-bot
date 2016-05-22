require "parallel"
require "thread"

module GomiBot
  module Twitter
    class ReplyGenerator
      def initialize(generators, client, status)
        @client = client
        @status = status
        @generators = generators
        @reply_limitter = GomiBot::Twitter::ReplyLimitter.instance
      end

      def call
        return false if retweet? || reply_to_others? || myself?
        Thread.new do
          reply
        end
      end

      def reply
        messages =
          Parallel.map(@generators, in_threads: @generators.size) { |generator|
            generator_obj = generator.new(prefix_removed)
            next if generator_obj.only_to_me? && has_prefix?.!
            reply_message = generator_obj.call
            update(reply_message) if reply_message
            reply_message
          }
        if messages.none?(&:itself) && has_prefix?
          update(default_message)
        end
      end

      def retweet?
        @status.key?(:retweeted_status)
      end

      def reply_to_others?
        @status[:in_reply_to_user_id].nil?.! &&
          @status[:in_reply_to_screen_name] != @client.screen_name
      end

      def myself?
        @status[:user][:id] == @client.id
      end

      # TODO: 外部で指定することにしたい
      def prefix
        @prefix = ["@#{@client.screen_name}", "ごみの日"]
      end

      def has_prefix?
        prefix.map { |i| /\A#{i}[\s\p{blank}]+/ =~ @status[:text] } .include?(0)
      end

      def prefix_removed
        regexp = /(#{prefix.join("|")})[\s\p{blank}]+/
        @status[:text].gsub(regexp, "")
      end

      def default_message
        GomiBot::Message::GomiToday.new.default
      end

      def update(str)
        if @reply_limitter.reply_limit?(@status[:user][:id])
          false
        else
          @reply_limitter.add_replied_id(@status[:user][:id])
          @client.update(
            str,
            in_reply_to_status_id: @status[:user][:id],
            screen_name: @status[:user][:screen_name]
          )
        end
      end

    end
  end
end