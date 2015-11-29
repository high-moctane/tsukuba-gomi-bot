# Date を拡張する

# NOTE: モジュール使ってやろうとすると p とか pp とかがエラー吐いてダメ
# TODO: P がなんか外部ファイルにも影響してるっぽいからどうにかしたい

require "date"
require_relative "bot/project"

include Bot::Project

P = Bot::Project


module Extend_Date
  def __strings__
    <<-'EOS'
    alias :__to_s__ :to_s
    def to_s(lang = nil)
      case lang
      when :ja
        "#{self.day}日(#{P.lang[:ja][:day_name][self.wday]})"
      when :en
        str =
          case day.to_s.split(//).pop
          when "1" then :st
          when "2" then :nd
          when "3" then :rd
          else :th
          end
        "#{P.lang[:en][:day_name][self.wday]}, #{self.day}#{str}"
      else
        __to_s__
      end
    end
    EOS
  end
end

include Extend_Date


class Date
  include Extend_Date
  eval Extend_Date.__strings__
end




class DateTime
  include Extend_Date
  eval Extend_Date.__strings__
end



if $0 == __FILE__
  p today = DateTime.now
  p today.to_s
  p today.to_s(:ja)
  p today.to_s(:en)
end

