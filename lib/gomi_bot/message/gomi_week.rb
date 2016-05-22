require "date"
require "pp"

module GomiBot
  module Message
    class GomiWeek < GomiBot::Message::GeneratorTemplate

      def condition
        GomiBot::Gomi.instance.district.include?(district)
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
        @message.gsub(/\s\p{blank}/, "").to_sym
      end

    end
  end
end
