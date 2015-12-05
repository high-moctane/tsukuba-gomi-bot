require "yaml"
require "logger"
require "pp"

# このプロジェクトに関する情報を扱う
module Bot

  module Project
    def root_dir
      @root_dir ||= File.expand_path("../../../", __FILE__) + "/"
    end


    def config
      @config ||= YAML.load_file(root_dir + "config/config.yml")
    end


    def lang
      @lang ||= YAML.load_file(root_dir + "db/language.yml")
    end


    def log
      return @logger unless @logger.nil?

      level = {
        FATAL: Logger::FATAL,
        ERROR: Logger::ERROR,
        WARN:  Logger::WARN,
        INFO:  Logger::INFO,
        DEBUG: Logger::DEBUG,
      }

      Dir.mkdir(root_dir + "log") unless Dir.exist?(root_dir + "log")

      case $DEBUG
      when true
        @logger = Logger.new(root_dir + "log/" + config[:logfile_debug])
        @logger.level = level[config[:log_level_debug]]
      else
        @logger = Logger.new(root_dir + "log/" + config[:logfile])
        @logger.level = level[config[:log_level]]
      end

      @logger

    end


    def log_message(e)
      "#{e.backtrace.inspect} #{e.message}"
    end
  end
end





if $0 == __FILE__
  include Bot
  include Project

  pp obj = Bot::Project

  pp obj.root_dir
  pp obj.config
  pp obj.lang
  pp obj.log

  begin
    raise
  rescue => e
    pp obj.log.info($0) { obj.log_message(e) }
  end
end
