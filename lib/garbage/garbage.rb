# coding: utf-8

require "yaml"
require "pp"

module Garbage

  # Garbege クラス
  #   カレンダーから読み込んだデータをいい感じに取り扱うクラス
  class Garbage
    attr_reader :data

    def initialize(date)
      @date = date

      dir = File.expand_path("../../data/calendar", __FILE__)
      @data = YAML.load_file("#{dir}/#{date.strftime("%Y_%m")}.yml")
      data_next = YAML.load_file("#{dir}/#{(date >> 1).strftime("%Y_%m")}.yml")

      @data.each_key do |key|
        @data[key].merge!(data_next[key])
      end
    end

    def day(date = @date)
      ans = {}
      @data.each do |k, v|
        ans[k] = v[date]
      end
      ans
    end

  end
end


