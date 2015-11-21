# coding: utf-8

require "date"
require "yaml"
require "pp"

require_relative "../project/project"

include Project




module Garbage

  # Garbege クラス
  #   カレンダーから読み込んだデータをいい感じに取り扱うクラス
  class Garbage
    attr_reader :data, :date


    def initialize(date, lang = :ja)
      @date = date.to_date

      load_data(@date)
      load_data(@date + 7) # 月をまたいだ時に困るから

      localize(lang)
    end


    # yamlからデータを取り込んで返す
    def load_data(date)
      dir = File.expand_path("../../data/calendar", __FILE__)
      data_tmp = YAML.load_file("#{dir}/#{date.strftime("%Y_%m")}.yml")

      if @data
        @data.each_key do |k|
          @data[k].merge!(data_tmp[k])
        end
      else
        @data = data_tmp
      end

      @data.each_key do |k|
        @data[k].default = :収集なし
      end
    end


    # 他言語対応のフリ
    def localize(language)
      lang = Project.lang[:ja]
      @dist_name   = lang[:dist_name]
    end


    # 1日分の情報を配列にして返す
    def day(dist: [:North, :West, :East, :South], shift: 0)
      dist = [dist].flatten
      date = @date + shift
      ans = []
      dist.each do |k|
        ans << [@dist_name[k], @data[k][date]]
      end
      ans
    end


    # 7日分の情報を配列で出す
    # Todo: そのうち書く
    def week(dist, shift: 0)
      ans = []
      date = @date + shift

      (0..6).each do |i|
        ans << [date + i, @data[dist][date + i]]
      end

      ans
    end
  end
end



# デバッグ用
if $0 == __FILE__
  require "date"
require_relative "../extend_date/extend_date"
  pp a = Garbage::Garbage.new(Date.new(2015, 11, 29))
  a = Garbage::Garbage.new(Date.today)
  a = Garbage::Garbage.new(DateTime.now.to_date)
  pp a
  str = ""
  str << "今日 #{a.day}"
  str << "\n"
  str << "明日 #{a.day(shift: 1)}"
  puts str
  pp a.week(:East).map { |b| b[0].strftime("%d日") + " #{b[1]}" }
  puts a.day(dist: :West).map {|i| i.join(": ")}.join("\n")
  puts a.day.map {|i| i.join(": ")}.join("\n")
  puts a.week(:East).map {|i| i[0].to_s(:ja) + i[1].to_s }.join("\n")
end
