require "parallel"
require "thread"

module GomiBot
  module Twitter
    class DMGenerator
      def initialize(generators, client, status)
        @client = client
        @status = status
        @generators = generators
        @reply_limitter = GomiBot::Twitter::ReplyLimitter.instance
      end

      def call
        return false if myself?
        Thread.new do
          reply
        end
      end

      def reply
        messages =
          Parallel.map(@generators, in_threads: @generators.size) { |generator|
            generator_obj = generator.new(@status[:text])
            reply_message = generator_obj.call
            dm(reply_message) if reply_message
            reply_message
          }
        dm(default_message) if messages.none?(&:itself)
      end

      def myself?
        @status[:sender][:id] == @client.id
      end

      def dm(str)
        if @reply_limitter.dm_limit?(@status[:sender_id])
          false
        else
          @reply_limitter.add_dmd_id(@status[:sender_id])
          @client.dm(@status[:sender][:screen_name], str)
        end
      end

      def default_message
        GomiBot::Message::GomiToday.new.default
      end
    end
  end
end