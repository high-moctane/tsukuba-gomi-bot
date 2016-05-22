require "singleton"

module GomiBot
  module Twitter
    class ReplyLimitter
      include Singleton

      def initialize
        @replied_list = {}
        @dmd_list = {}
      end

      def add_replied_id(id)
        init_replied_list(id)
        @replied_list[id] << Time.now
      end

      def add_dmd_id(id)
        init_dmd_list(id)
        @dmd_list[id] << Time.now
      end

      def reply_limit?(id)
        init_replied_list(id)
        pp @replied_list
        @replied_list[id].reject! { |i|
          Time.now - i > GomiBot.config[:reply][:reply_limit_sec]
        }
        pp @replied_list
        if @replied_list[id].size >= GomiBot.config[:reply][:reply_limit_count]
          true
        else
          false
        end
      end

      def dm_limit?(id)
        init_dmd_list(id)
        @dmd_list[id].reject! { |i|
          Time.now - i > GomiBot.config[:reply][:dm_limit_sec]
        }
        if @dmd_list[id].size >= GomiBot.config[:reply][:dm_limit_count]
          true
        else
          false
        end
      end

      def init_replied_list(id)
        @replied_list[id] ||= []
      end

      def init_dmd_list(id)
        @dmd_list[id] ||= []
      end

    end
  end
end