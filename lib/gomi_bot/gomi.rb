require "date"
require "pathname"
require "pp"
require "singleton"
require "yaml"

module GomiBot
  class Gomi
    include Singleton

    OVERSIZED_TEL       = 2
    OVERSIZED_INTERNET  = 5

    attr_reader :calendar

    def initialize
      load_data
    rescue => e
      GomiBot.logger.fatal {
        "Gomiインスタンス生成失敗 #{GomiBot.logger_message(e)}"
      }
      raise
    end

    def day(dist: district, date: Date.today)
      @calendar
        .map { |k, v| {k => {date => v[date]}} }
        .inject { |m, i| merge_hash(m, i) }
        .select { |k, v| [dist].flatten.include?(k) }
    end

    def week(dist: district, start_date: Date.today)
      (0..6)
        .map { |i| day(dist: dist, date: start_date + i) }
        .flatten
        .inject { |m, i| merge_hash(m, i) }
    end

    def garb_collect_days(garb, dist: district)
      @calendar
        .map { |k, v| {k => v.select { |l, w| w == garb }} }
        .inject { |m, i| merge_hash(m, i) }
        .select { |k, v| [dist].flatten.include?(k) }
    end

    def next_garb_collect(garb, dist: district, start_date: Date.today)
      garb_collect_days(garb, dist: dist)
        .map { |k, v|
          next_day = v.keys.select { |i| i >= start_date }.sort.first
          {k => {next_day => v[next_day]}}
        }
        .inject { |m, i| merge_hash(m, i) }
    end

    # TODO: :収集なし がソースコードに書かれているので
    #   入れなくてよくなるように修正しよう
    def any_collect?(dist: district, date: Date.today)
      day(dist: dist, date: date)
        .map { |k, v| v.values.none? { |i| i == :収集なし } }
        .any? { |i| i }
    end

    def oversized_reservation_day?(dist: district, date: Date.today)
      garb_collect_days(:粗大ごみ, dist: dist)
        .map { |k, v|
          ans =
            case :粗大ごみ
            when v[date + OVERSIZED_TEL]      then :Tel
            when v[date + OVERSIZED_INTERNET] then :Internet
            else false
            end
          {k => ans}
        }
        .inject { |m, i| merge_hash(m, i) }
    end

    # private

    # TODO: :収集なし がソースコードに書かれているので
    #   入れなくてよくなるように修正しよう
    def load_data
      @calendar ||= begin
        calendar_dir = Pathname.new(GomiBot.db_dir + "calendar")
        data = calendar_dir.children.map { |i|
                 YAML.load_file(i.realpath.to_s)
               }
               .inject { |m, i| merge_hash(m, i) }
        data.each_key { |k| data[k].default = :収集なし }
        data
      end
    end

    def district
      @calendar.keys
    end

    def merge_hash(hash1, hash2)
      hash1.merge(hash2) { |key, v1, v2| merge_hash(v1, v2) }
    end
  end
end

