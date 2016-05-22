require "clockwork"
require_relative "gomi_bot"

module Clockwork
  configure { |config|
    config[:max_threads] = 100
    config[:logger] = ::GomiBot.logger
    config[:thread] = true
  }

  handler { |job|
    sleep [*0..600].sample
    job.call
  }

  every(1.5.hours, ::GomiBot::Twitter::AutoTweets.new)
  every(2.hours, ::GomiBot::Twitter::Following.new)
end