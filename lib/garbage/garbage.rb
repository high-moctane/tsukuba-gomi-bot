# coding: utf-8

require "date"
require "yaml"
require "pp"

module Garbage

  # Garbege クラス
  #   カレンダーから読み込んだデータをいい感じに取り扱うクラス
  class Garbage
    attr_reader :data, :date

    # Todo:
    #   この辺はそのうち外部ファイルに置けるようにしたい
    @@dist_name = {
      ja: {
        North: :北地区,
        West:  :西地区,
        East:  :東地区,
        South: :南地区,
      },
    }

    @@day_name = {
      ja: %i(日 月 火 水 木 金 土),
    }

    @@date_format = {
      ja: :日,
    }

    # Todo:
    #   "燃やせない" とかも多言語にする？

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
    def localize(lang)
      @dist_name   = @@dist_name[lang]
      @day_name    = @@day_name[lang]
      @date_format = @@date_format[lang]
    end

    # 何日後の情報を文字列で出す
    def day(shift = 0)
      date = @date + shift

      date_format =
        "#{date.day}#{@date_format}(#{@day_name[date.wday]})"
      ans = "#{date_format}\n"

      @data.each_key do |k|
        ans << "#{@dist_name[k]}: #{@data[k][date]}\n"
      end

      ans
    end

    # その週の情報を出す
    # Todo: そのうち書く
    def week(shift = 0)
    end
  end
end


# デバッグ用
if $0 == __FILE__
  require "date"
  # pp a = Garbage::Garbage.new(Date.new(2015, 11, 29))
  a = Garbage::Garbage.new(Date.today)
  # a = Garbage::Garbage.new(DateTime.now.to_date)
  pp a
  str = ""
  str << "今日 #{a.day}"
  str << "\n"
  str << "明日 #{a.day(1)}"
  puts str
end
