module GomiBot
  module Twitter
    class AutoTweets

      def initialize
        @client = GomiBot::Twitter::Client.new
      end

      def call
        @client.update(message)
      end

      def message
        gomi_today
      end

      def gomi_today
        GomiBot::Message::GomiToday.new.default
      end

    end
  end
end