require_relative "bot/bot"
require_relative "bot/garbage"
require_relative "bot/project"
require_relative "bot/message"

if $0 == __FILE__
  include Bot
  pp Bot::Project.root_dir
end