require "date"

class Date
  class << self
    def parse_ja(str)
      new_str = str.tr("０-９", "0-9").gsub(/年|ねん|月|つき/, "/")
      self.parse(new_str)
    end
  end

  def to_s_ja
    "#{self.month}月#{self.day}日（#{%w(日 月 火 水 木 金 土)[self.wday]}）"
  end
end
