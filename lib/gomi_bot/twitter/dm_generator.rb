require "parallel"
require "thread"

module GomiBot
  module Twitter
    class DMGenerator
      def initialize(generators, client, status)
        @client = client
        @status = status
        @generators = generators
      end

      def call
        return false if myself?
        Thread.new do
          reply
        end
      end

      def reply
        Parallel.each(@generators) do |generator|
          generator_obj = generator.new(@status.text)
          reply_message = generator_obj.call
          if reply_message
            @client.dm(
              status_attrs[:sender][:screen_name],
              reply_message
            )
          end
        end
      end

      def status_attrs
        @status_attrs ||= @status.attrs
      end

      def myself?
        status_attrs[:sender][:id] == @client.id
      end
    end
  end
end