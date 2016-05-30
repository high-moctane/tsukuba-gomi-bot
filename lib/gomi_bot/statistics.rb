require "date"

module GomiBot
  class Statistics

    def call
      GomiBot.logger.info "Statistics 開始"
      logger.fatal YAML.dump(data)
    end

    def client
      @client ||= GomiBot::Twitter::Client.new
    end

    def logger
      @logger ||= begin
        Dir.mkdir(GomiBot.root_dir + "log") unless Dir.exist?(GomiBot.root_dir + "log")
        logger = Logger.new(GomiBot.root_dir + "log/statistics.log")
        logger.formatter = -> (severity, datetime, progname, message) {
          "# #{"-" * 60}\n# #{datetime}\n#{message.chomp}\n\n"
        }
        logger
      end
    end

    def twitter_user_data
      twitter_user_attrs.select { |k, v|
        [:followers_count, :friends_count, :listed_count,
         :favourites_count, :statuses_count].include?(k)
      }
    end

    def twitter_user_attrs
      @twitter_user_attrs ||= client.twitter.user.attrs
    end

    def now
      DateTime.now
    end

    def data
      {
        date: now,
        twitter_user_data: twitter_user_data,
        friendships: {
          follower_ids: client.follower_ids,
          friend_ids: client.friend_ids,
          friendships_outgoing: client.friendships_outgoing,
        },
      }
    end

  end
end
