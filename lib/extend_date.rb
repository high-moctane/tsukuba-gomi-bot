# Date を拡張する

# NOTE: モジュール使ってやろうとすると p とか pp とかがエラー吐いてダメ

require "date"
require_relative "bot/project"

include Bot::Project

P = Bot::Project



class Date
  eval DATA.read
end



class DateTime
  eval DATA.read
end



if $0 == __FILE__
  p today = Date.today
  p today.to_s
  p today.to_s(:ja)
  p today.to_s(:en)
end



__END__
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
