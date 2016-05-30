require "date"
require "pp"

module GomiBot
  module Message
    class GomiWeek < GomiBot::Message::GeneratorTemplate

      def condition
        parse_district
      end

      def gen_message
        header + body + footer
      end

      def header
        "#{district}の今後1週間のごみは\n"
      end

      def footer
        "です"
      end

      def generate_date
        if Time.now.hour < 12
          Date.today
        else
          Date.today.next
        end
      end

      def body
        district_data = data[district]
        district_data.map { |k, v| "#{k.to_s_ja}：#{v}\n" }.join
      end

      def data
        @data ||= GomiBot::Gomi.instance.week(start_date: generate_date)
      end

      def district
        parse_district
      end

      def parse_district
        case @message
        when /東|ひがし|ヒガシ/ then :東地区
        when /西|にし|にし/     then :西地区
        when /南|みなみ|ミナミ/ then :南地区
        when /北|きた|キタ/     then :北地区
        else false
        end
      end

    end
  end
end
