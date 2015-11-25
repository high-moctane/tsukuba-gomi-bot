# Date を拡張する
# TODO: とりあえず実装したので後でいい方法に書き換える

require "date"

class Date
  alias :__to_s__ :to_s
  def to_s(lang = nil)
    case lang
    when :ja
      "#{self.day}日(#{%w(日 月 火 水 木 金 土)[self.wday]})"
    else
      __to_s__
    end
  end
end


class DateTime
  alias :__to_s__ :to_s
  def to_s(lang = nil)
    case lang
    when :ja
      "#{self.day}日(#{%w(日 月 火 水 木 金 土)[self.wday]})"
    else
      __to_s__
    end
  end
end

if $0 == __FILE__
  p today = Date.today
  p today.to_s(:ja)
end
