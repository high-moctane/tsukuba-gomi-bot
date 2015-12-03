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
      garb_init
      @@P.log.debug($0) { "Message: インスタンス生成完了" }
    end



    # よくある一般的なツイート
    def garb_regular
      garb_update

      shift = @now.hour.between?(0, 11) ? 0 : 1

      <<-"EOS"
#{%w(今日 明日)[shift]} #{@now.to_lang(:ja)}
#{@garb.day(shift: shift).map { |a| a * ": " } * "\n"}
です(｀･ω･´)
      EOS
    end



    # 地区ごとの返事
    def garb_dist(dist)
      garb_update

      <<-"EOS"
#{dist}のごみは
今日 #{@garb.week(dist).map { |a| "#{a[0].to_lang(:ja)}: #{a[1]}" } * "\n"}
です(｀･ω･´)
      EOS
    end



    # 次のごみ検索
    def garb_search(category)
      garb_update

      <<-"EOS"
次の#{category}の回収日は
#{@garb.next_collect(category).map { |a| "#{a[0]}: #{a[1].to_lang(:ja)} (#{"%d" % a[2]}日後)" } * "\n"}
です(｀･ω･´)
      EOS
    end



    # ごみくじ
    def lucky_item
      item_list = []
      @@lucky_item_list.each_with_index do |a, i|
        item_list << [i, a].flatten
      end

      item = item_list.map { |a| [a[0]] * a[1] }.flatten.sample

      # TODO: レア度の実装をしたい
      prob = item_list[item][1].fdiv(item_list.inject(0) {|sum, a| sum + a[1]})

      <<-"EOS"
今日のラッキーアイテムは
  #{item_list[item][2]} (出現率#{"%.1f" % (prob * 100)}％)
です(｀･ω･´)
      EOS
    end




    private


    def garb_init
      @now  = DateTime.now
      @garb = Garbage.new(@now)
    end



    # @garbをアップデートする必要があるとき使う
    def garb_update
      @now  = DateTime.now
      @garb = Garbage.new(@now) unless @garb.date == @now.to_date
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
end
