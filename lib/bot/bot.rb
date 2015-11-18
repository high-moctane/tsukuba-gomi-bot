# coding: utf-8

require "yaml"
require "twitter"
require "tweetstream"
require "pp"
require "logger"



# Bot module
module Bot
  # あたかもなんかのインスタンスのようにつかう
  def root
    File.expand_path("../../../", __FILE__)
  end

  def config
    YAML.load_file(root + "/lib/config/config.yml")
  end

  def log
    level = {
      FATAL: Logger::FATAL,
      ERROR: Logger::ERROR,
      WARN:  Logger::WARN,
      INFO:  Logger::INFO,
      DEBUG: Logger::DEBUG,
    }

    logger = Logger.new(root + "/log/" + config[:logfile_name])

    logger.level =
      if $DEBUG
        level[config[:log_level_debug]]
      else
        level[config[:log_level]]
      end

    logger
  end


  # twitterアカウント関連のことをする
  class Bot
    attr_reader :twitter, :stream

    def initialize(app_name)
      dir  = File.expand_path("../../config/#{app_name}_config.yml", __FILE__)
      keys = YAML.load_file(dir)

      @twitter = init_twitter(keys)
      @stream  = init_tweetstream(keys)
    rescue => e
      Bot.log.fatal "#{e.message} (file: #{__FILE__}, line: #{__LINE__})"
      raise
    else
      Bot.log.info "Bot のインスタンス生成完了"
    end

    def init_twitter(keys)
      Twitter::REST::Client.new do |config|
        config.consumer_key        = keys[:consumer_key]
        config.consumer_secret     = keys[:consumer_secret]
        config.access_token        = keys[:access_token]
        config.access_token_secret = keys[:access_token_secret]
      end
    rescue => e
      Bot.log.fatal "#{e.message} (file: #{__FILE__}, line: #{__LINE__})"
      raise
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
    rescue => e
      Bot.log.fatal "#{e.message} (file: #{__FILE__}, line: #{__LINE__})"
      raise
    end


    def put_stream
      @stream.userstream do |status|
        printf("%s\n\n", status.text)
      end
    rescue => e
      Bot.log.fatal "#{e.message} (file: #{__FILE__}, line: #{__LINE__})"
      raise
    end

    def post(string)
      @twitter.update(string)
      Bot.log.info("post: #{string}")
    rescue => e
      Bot.log.fatal "#{e.message} (file: #{__FILE__}, line: #{__LINE__})"
      raise
    end
  end

end



# debug
if $0 == __FILE__
  include Bot
  a = Bot::Bot.new(:shakiin)
  a.stream.userstream.track("ぽわ") do |obj|
    puts "text " + obj.text
    puts "favorite_count " + obj.favorite_count.to_s
    puts "filter_level " + obj.filter_level
    puts "in_reply_to_screen_name " + obj.in_reply_to_screen_name
    puts "in_reply_to_status_id " + obj.in_reply_to_status_id.to_s
    puts "in_reply_to_user_id " + obj.in_reply_to_user_id.to_s
    puts "lang " + obj.lang
    puts "retweet_count " + obj.retweet_count.to_s
    puts "source " + obj.source
    puts "full_text " + obj.full_text
    puts "uri " + obj.uri
    puts ""

    # if /ぽわ/ === obj.text
      a.twitter.favorite(obj)
    # end
  end
end
