# Date, DateTime を拡張する

# NOTE: 既存のメソッドは上書きしない方針


module Extend_Date
  require_relative "bot/project"
  include Bot::Project

  def to_lang(lang)
    case lang
    when :ja
      "#{self.month}月#{self.day}日(#{Bot::Project.lang[:ja][:day_name][self.wday]})"
    when :en
      str =
        case day.to_s.split(//).pop
        when "1" then :st
        when "2" then :nd
        when "3" then :rd
        else :th
        end
      "#{Bot::Project.lang[:en][:day_name][self.wday]}, #{self.day}#{str}"
    else
      to_s
    end
  end
end


Date.send(:prepend, Extend_Date)
DateTime.send(:prepend, Extend_Date)


if $0 == __FILE__
  include Extend_Date
  p today = DateTime.now
  p today.to_s
  p today.to_lang(:ja)
  p today.to_lang(:en)
end

