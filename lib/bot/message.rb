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

      if @garb.any_collect?(shift: @garb_shift)
        <<-"EOS"
#{%w(今日 明日)[@garb_shift]} #{(@now + @garb_shift).to_lang(:ja)}
#{@garb.day(shift: @garb_shift).map { |a| a * ": " } * "\n"}
です#{shakiin}
        EOS
      else
        <<-"EOS"
#{%w(今日 明日)[@garb_shift]} #{(@now + @garb_shift).to_lang(:ja)} の収集はありません#{shakiin}
        EOS
      end

    end



    # 地区ごとの返事
    def garb_dist(dist)
      garb_update

      <<-"EOS"
#{dist}のごみは
#{%w(今日 明日)[@garb_shift]} #{@garb.week(dist, shift: @garb_shift).map { |a| "#{a[0].to_lang(:ja)}: #{a[1]}" } * "\n"}
です#{shakiin}
      EOS
    end



    # 次のごみ検索
    def garb_search(category)
      garb_update

      <<-"EOS"
次の#{category}の回収日は、今日を含め#{%w(る ない)[@garb_shift]}と
#{@garb.next_collect(category, shift: @garb_shift)
.map { |a| "#{a[0]}: #{a[1].to_lang(:ja)} (#{"%d" % a[2]}日後)" } * "\n"}
です#{shakiin}
      EOS
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
end

