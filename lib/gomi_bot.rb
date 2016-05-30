require "logger"
require "pathname"
require "pp"
require "thread"
require "yaml"

module GomiBot
  class << self
    def root_dir
      @root_dir ||= File.expand_path("../..", __FILE__) + "/"
    end

    def config_dir
      @config_dir ||= root_dir + "config/"
    end

    def db_dir
      @db_dir ||= root_dir + "db/"
    end

    def config
      YAML.load_file(config_dir + "config.yml")
    end

    def logger
      @logger ||= begin
        Dir.mkdir(root_dir + "log") unless Dir.exist?(root_dir + "log")
        is_debug = $DEBUG ? :debug : :default
        logger = Logger.new(root_dir + "log/" + config[:logger][is_debug][:logfile])
        logger.level = config[:logger][is_debug][:log_level].to_i
        logger
      end
    end

    def logger_message(e)
      "| #{e.backtrace.first} | #{e.message}"
    end
  end
end

require_relative "date"
require_relative "gomi_bot/gomi"
require_relative "gomi_bot/twitter/client"
require_relative "gomi_bot/twitter/reply_generator"
require_relative "gomi_bot/twitter/dm_generator"
require_relative "gomi_bot/twitter/stream"
require_relative "gomi_bot/twitter/following"
require_relative "gomi_bot/twitter/reply_limitter"
require_relative "gomi_bot/twitter/auto_tweets"
require_relative "gomi_bot/message/generator_template"
require_relative "gomi_bot/message/gomikuji"
require_relative "gomi_bot/message/gomi_today"
require_relative "gomi_bot/message/gomi_week"
require_relative "gomi_bot/message/gomi_search"
require_relative "gomi_bot/statistics"
require_relative "clockwork"


# --------------------------------------------------------------------------------
# main
#

begin
  GomiBot.logger.info "ごみbot 起動 (｀･ω･´)！"
  Thread.abort_on_exception = true
  GomiBot::Twitter::Stream.new.run
  sleep if $DEBUG

rescue StandardError => e
  GomiBot.logger.fatal "エラー(´; ω ;｀) #{GomiBot.logger_message(e)}"
  raise

end
