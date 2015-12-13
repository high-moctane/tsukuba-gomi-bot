# coding: utf-8

require "date"
require "pp"

require_relative "project"
require_relative "garbage"
require_relative "../extend_date"

include Bot::Project




module Bot
  
  # よく使うメッセージを文字列で吐き出すためのクラス
  class Message
    @@P = Project
    @@lucky_item_list = @@P.config[:gomikuji_item]


    def initialize
      garb_update
      @@P.log.debug($0) { "Message: インスタンス生成完了" }
    end



    # よくある一般的なツイート
    def garb_regular
      garb_update
      mes = ""
      mes << %w(今日 明日)[@garb_shift]
      mes << (@now + @garb_shift).to_lang(:ja)

      if @garb.any_collect?(shift: @garb_shift)
        mes << "\n"
        @garb.day(shift: @garb_shift).each { |k, v|
          mes << "#{k}: #{v}\n"
        }
        mes << "です#{shakiin}\n"
      else
        mes << "の収集はありません#{shakiin}\n"
      end
      mes
    end



    # 地区ごとの返事
    def garb_dist(dist = [:北地区, :西地区, :東地区, :南地区])
      garb_update
      mes = ""
      @garb.week(dist: dist, shift: @garb_shift).each do |k, v|
        mes << "#{k}のごみは\n#{%w(今日 明日)[@garb_shift]} "
        v.each do |k1, v1|
          mes << "#{k1.to_lang(:ja)}: #{v1}\n"
        end
        mes << "です#{shakiin}\n"
      end

      mes
    end



    # 次のごみ検索
    def garb_search(category)
      garb_update
      mes = "次の#{category}の回収日は、今日を含め#{%w(る ない)[@garb_shift]}と\n"
      @garb.next_collect(category, shift: @garb_shift).each do |k, v|
        mes << "#{k}: #{v[:date].to_lang(:ja)}（#{"%d" % v[:offset]}日後）\n"
      end
      mes << "です#{shakiin}\n"
    end



    # 粗大ごみのお知らせ
    def garb_og_day(dist = [:北地区, :西地区, :東地区, :南地区])
      garb_update
      dist = [dist].flatten
      data = @garb.reservation_day_oversized(dist: dist)
      mes = ""
      return "" if data.reject { |_, v| v == nil }.empty?
      internet = []
      tel = []

      data.each do |k, v|
        case v
        when :Internet then internet << k
        when :Tel      then tel << k
        else #NOP
        end
      end

      unless internet.empty?
        mes << "#{internet.join("、")}の粗大ごみインターネット予約は今日までです#{shakiin}\n"
      end
      unless tel.empty?
        mes << "#{tel.join("、")}の粗大ごみの電話予約は今日の17:15までです#{shakiin}\n"
      end

      mes
    end



    # 日付検索
    def garb_particular_day(str)
      garb_update
      mes = ""
      data = @garb.particular_day(str)
      if data.nil?
        mes << "無効な日付です(´; ω ;｀)\n"
      elsif data[:data].nil?
        mes << "#{(@garb.date >> 1).month}月までしか対応してません(´; ω ;｀)\n"
      else
        mes << "#{data[:date].to_lang(:ja)}は\n"
        data[:data].each do |k, v|
          mes << "#{k}: #{v}\n"
        end
        mes << "です#{shakiin}\n"
      end
    end



    # ごみくじ
    def lucky_item
      item_list = []
      @@lucky_item_list.each_with_index do |a, i|
        item_list << [i, a].flatten
      end

      item = item_list.map { |a| [a[0]] * a[1] }.flatten.sample

      # TODO: レア度の実装をちゃんとしたい
      prob = item_list[item][1].fdiv(item_list.inject(0) {|sum, a| sum + a[1]})

      <<-"EOS"
今日のラッキーアイテムは
  #{item_list[item][2]} (レア度 #{"★" * (4 - item_list[item][1])}#{"☆" * (item_list[item][1] - 1)})
です#{shakiin}
      EOS
    end



    # (｀･ω･´) が現在時刻によって寝る
    def shakiin
      @now = DateTime.now
      @now.hour.between?(6, 22) ? "(｀･ω･´)" : "(｀-ω-´)zzZ"
    end



    private


    # @garbをアップデートする必要があるとき使う
    def garb_update
      @now        = DateTime.now
      @garb       = Garbage.new(@now) if @garb.nil? || @garb.date != @now.to_date
      @garb_shift = @now.hour.between?(0, 11) ? 0 : 1
    end



  end
end





if $0 == __FILE__
  # debug
  include Bot
  obj = Bot::Message.new
  puts obj.garb_regular
  puts obj.garb_dist(:北地区)
  puts obj.garb_search(:ペットボトル)
  puts obj.lucky_item
  puts obj.shakiin
  puts obj.garb_og_day
  puts obj.garb_particular_day("1/3")
end

