require "yaml"

module GomiBot
  module Twitter
    class Following

      def initialize(
        following: GomiBot.config[:following][:auto_following],
        unfollowing: GomiBot.config[:following][:auto_unfollowing]
      )
        @following = following
        @unfollowing = unfollowing
        @client   = GomiBot::Twitter::Client.new
      end

      def call
        GomiBot.logger.info "Following 開始"
        follow if @following
        unfollow if @unfollowing
        refresh_skip_following_list
      end

      def follow
        new_skip_following = []
        to_follow_list.sample(following_limit).each do |i|
          new_skip_following << i
          user_data = @client.twitter.user(i).attrs
          @client.follow(i) if judge_following(user_data)
        end
        unless new_skip_following.empty?
          new_config = config
          new_config[:skip_following] += new_skip_following
          dump_config(new_config)
        end
      end

      def unfollow
        to_unfollow_list.sample(unfollowing_limit).each do |i|
          @client.unfollow(i)
        end
      end

      # private

      def follower_ids
        @follower_ids ||= @client.follower_ids
      end

      def friend_ids
        @friend_ids ||= @client.friend_ids
      end

      def friendships_outgoing
        @friendships_outgoing ||= @client.friendships_outgoing
      end

      def to_follow_list
        follower_ids - friend_ids - friendships_outgoing - ignore_following_list
      end

      def to_unfollow_list
        friend_ids - follower_ids - friendships_outgoing - ignore_unfollowing_list
      end

      def ignore_following_list
        config[:skip_following] + config[:blacklist]
      end

      def ignore_unfollowing_list
        config[:whitelist]
      end

      def refresh_skip_following_list
        new_config = config
        new_nonfollower = config[:skip_following] - follower_ids - friendships_outgoing
        new_list = config[:skip_following] - new_nonfollower
        new_config[:skip_following] = new_list
        dump_config(new_config)
      end

      def judge_following(data)
        bot_regexp = /[^r][^o]bot|[^ろ]ぼっと|[^ロ]ボット/i
        data[:lang] = "ja" &&
          data[:screen_name] !~ bot_regexp &&
          data[:name] !~ bot_regexp &&
          data[:description] !~ bot_regexp &&
          data[:favourites_count] > 0 &&
          data[:friends_count] < 10 * data[:followers_count]
      end

      def config_file
        GomiBot.config_dir + "friendship.yml"
      end

      def config
        @config ||= YAML.load_file(config_file)
      end

      def dump_config(new_conf)
        File.open(config_file, "w") { |f| YAML.dump(new_conf, f) }
        @config = new_conf
      end

      def following_limit
        GomiBot.config[:following][:following_limit]
      end

      def unfollowing_limit
        GomiBot.config[:following][:unfollowing_limit]
      end

    end
  end
end
