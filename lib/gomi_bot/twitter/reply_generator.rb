require "parallel"
require "thread"

module GomiBot
  module Twitter
    class ReplyGenerator
      def initialize(generators, client, status)
        @client = client
        @status = status
        @generators = generators
      end

      def call
        return false if retweet? || reply_to_others? || myself?
        Thread.new do
          reply
        end
      end

      def reply
        Parallel.each(@generators) do |generator|
          generator_obj = generator.new(prefix_removed)
          next if generator_obj.only_to_me? && has_prefix?.!
          reply_message = generator_obj.call
          if reply_message
            @client.update(
              reply_message,
              in_reply_to_status_id: @status.id,
              screen_name: @status.user.screen_name
            )
          end
        end
      end

      def retweet?
        status_attrs.key?(:retweeted_status)
      end

      def reply_to_others?
        @status_attrs[:in_reply_to_user_id].nil?.! &&
          @status_attrs[:in_reply_to_screen_name] != @client.screen_name
      end

      def myself?
        @status.user.id == @client.id
      end

      def status_attrs
        @status_attrs ||= @status.attrs
      end

      # TODO: 外部で指定することにしたい
      def prefix
        @prefix = ["@#{@client.screen_name}", "ごみの日"]
      end

      def has_prefix?
        prefix.map { |i| /\A#{i}[\s\p{blank}]+/ =~ @status.text } .include?(0)
      end

      def prefix_removed
        regexp = /(#{prefix.join("|")})[\s\p{blank}]+/
        @status.text.gsub(regexp, "")
      end

    end
  end
end