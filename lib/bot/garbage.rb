# coding: utf-8

require "date"
require "yaml"
require "pp"

require_relative "project"





module Bot
  include Project

  # Garbege クラス
  #   カレンダーから読み込んだデータをいい感じに取り扱うクラス
  class Garbage
    @@P = Project
    @@dist = [:North, :West, :East, :South]
    attr_reader :data, :date


    def initialize(date, lang: :ja)
      @date = date.to_date

      load_data(@date)
      load_data(@date >> 1) # 月をまたいだ時に困るから

      localize(lang)

      @@P.log.debug($0) { "Garbage のインスタンス生成 (@date = #{@date})" }
    end


    # 1日分の情報を配列にして返す
    def day(dist: @@dist, shift: 0)
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


    def next_collect(garb, dist = @@dist)
      dist = [dist].flatten
      ans = []

      garb = @category_name[garb]

      dist.each do |k|
        (0..30).each do |i|
          if garb == @data[k][date + i]
            ans << [@dist_name[k], @date + i, i]
            break
          end
        end
      end

      ans
    end


    # 回収があるかどうかを吐き出す
    def any_collect?(dist: @@dist, shift: 0)
      dist = [dist].flatten
      date = @date + shift
      flag = false
      dist.each do |k|
        flag = true if @data[k].has_key?(date)
      end
      flag
    end


    # 他言語対応のフリ
    def localize(language)
      lang           = @@P.lang[language]
      @dist_name     = lang[:dist_name]
      @category_name = lang[:category_name]

      @data.each_key do |k|
        @data[k].default = @category_name[:収集なし]
        @data[k].each do |key, val|
          @data[k][key] = @category_name[val]
        end
      end
    end


    private

    # yamlからデータを取り込んで返す
    def load_data(date)
      dir = @@P.root_dir + "db/calendar"
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
    rescue => e
    @@P.log.fatal($0) { @@P.log_message(e) }
      raise
    end


  rescue => e
    @@P.log.fatal($0) { @@P.log_message(e) }
    raise
  end
end



# デバッグ用
if $0 == __FILE__
  include Bot
  require "date"
  require_relative "../extend_date"
  obj = Bot::Garbage.new(Date.today)
  # obj = Bot::Garbage.new(Date.today, lang: :en)
  obj.data[:North][0]
  pp obj.day
  pp obj.week(:North)
  pp obj.next_collect(:ペットボトル)
  pp obj.any_collect?
end
