require "yaml"
require "logger"
require "pp"

# このプロジェクトに関する情報を扱う
module Project
  def root
    File.expand_path("../../../", __FILE__)
  end


  def config
    YAML.load_file(root + "/lib/config/config.yml")
  end


  def lang
    YAML.load_file(root + "/lib/data/language.yml")
  end


  def log
    level = {
      FATAL: Logger::FATAL,
      ERROR: Logger::ERROR,
      WARN:  Logger::WARN,
      INFO:  Logger::INFO,
      DEBUG: Logger::DEBUG,
    }

    Dir.mkdir(root + "/log") unless Dir.exist?(root + "/log")

    case $DEBUG
    when true
      logger = Logger.new(root + "/log/" + config[:logfile_debug])
      logger.level = level[config[:log_level_debug]]
    else
      logger = Logger.new(root + "/log/" + config[:logfile])
      logger.level = level[config[:log_level]]
    end

    logger
  end


  def log_message(e)
    "#{e.backtrace[0]} #{e.message}"
  end
end



if $0 == __FILE__
  include Project
  pp Project.root
  pp Project.lang
  pp Project.config
  pp Project.log.debug "test"
end
