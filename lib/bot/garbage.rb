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
    @@dist = [:北地区, :西地区, :東地区, :南地区]
    attr_reader :data, :date


    def initialize(date)
      @date = date.to_date

      load_data(@date)
      load_data(@date >> 1) # 月をまたいだ時に困るから

      @@P.log.debug($0) { "Garbage のインスタンス生成 (@date = #{@date})" }
    end


    # 1日分の情報を配列にして返す
    def day(dist: @@dist, shift: 0)
      dist = [dist].flatten
      date = @date + shift
      ans = []
      dist.each do |k|
        ans << [k, @data[k][date]]
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


    def next_collect(garb, dist = @@dist, shift: 0)
      dist = [dist].flatten
      ans = []

      dist.each do |k|
        (0..30).each do |i|
          if garb == @data[k][date + shift + i]
            ans << [k, @date + shift + i, shift + i]
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


    def reservation_day_oversized(dist: @@dist, shift: 0)
      dist = [dist].flatten
      date = @date + shift
      ans  = {}

      dist.each do |k|
        ans[k] =
          case :粗大ごみ
          when @data[k][date + @@P.config[:og_Tel]]      then :Tel
          when @data[k][date + @@P.config[:og_Internet]] then :Internet
          else nil
          end
      end
      ans
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
  pp obj.data[:北地区][0]
  pp obj.day
  pp obj.week(:東地区)
  pp obj.next_collect(:ペットボトル, shift: 5)
  pp obj.any_collect?
  pp obj.reservation_day_oversized
end
