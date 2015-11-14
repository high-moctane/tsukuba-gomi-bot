# coding: utf-8

require "yaml"
require "twitter"
require "tweetstream"
require "pp"

# Bot module
module Bot
  class Bot
    attr_reader :twitter, :stream

    def initialize(app_name)
      # ディレクトリ構造を考え付いたらここを書き換える
      keys = YAML.load_file("./#{app_name}_config.yml")

      @twitter = Twitter::REST::Client.new do |config|
        config.consumer_key        = keys[:consumer_key]
        config.consumer_secret     = keys[:consumer_secret]
        config.access_token        = keys[:access_token]
        config.access_token_secret = keys[:access_token_secret]
      end

      TweetStream.configure do |config|
        config.consumer_key       = keys[:consumer_key]
        config.consumer_secret    = keys[:consumer_secret]
        config.oauth_token        = keys[:access_token]
        config.oauth_token_secret = keys[:access_token_secret]
        config.auth_method        = :oauth
      end

      @stream = TweetStream::Client.new
    end

    def put_stream
      @stream.userstream do |status|
        printf("%s\n\n", status.text)
      end
    end

    def post(string)
      @twitter.update(string)
    end
  end
end


