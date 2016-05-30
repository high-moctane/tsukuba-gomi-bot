require "clockwork"

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

  every(
    GomiBot.config[:auto][:auto_tweets_interval].minutes,
    ::GomiBot::Twitter::AutoTweets.new
  )
  every(
    GomiBot.config[:auto][:auto_following_interval].minutes,
    ::GomiBot::Twitter::Following.new
  )
  every(
    1.day,
    GomiBot::Statistics.new,
    at: "00:00"
  )
end
