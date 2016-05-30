require "date"
require "pp"

module GomiBot
  module Message
    class GomiToday < GomiBot::Message::GeneratorTemplate

      def condition
        parsed_date = begin
          Date.parse_ja(@message)
        rescue ArgumentError
          false
        end
        /(今日|きょう|明日|あした|明後日|あさって)/ === @message || parsed_date
      end

      def gen_message
        header + body + footer + oversized_message
      end

      def default
        @message = if Time.now.hour < 12 then "今日" else "明日" end
        gen_message
      end

      def generate_date
        @generate_date ||=
          case @message
          when /今日|きょう/
            Date.today
          when /明日|あした/
            Date.today.next
          when /明後日|あさって/
            Date.today.next.next
          else
            Date.parse_ja(@message)
          end
      end

      def header
        "#{generate_date.to_s_ja}のごみは\n"
      end

      def footer
        "です\n"
      end

      def body
        data.map { |k, v| "#{k}：#{v.values.first}\n" }.join
      end

      def data
        @data ||= GomiBot::Gomi.instance.day(date: generate_date)
      end

      def oversized_header
        "また、#{generate_date.to_s_ja}は以下の地区の粗大ごみ予約締切日です\n"
      end

      def oversized_body
        oversized_data
          .select { |_, v| v }
          .map { |k, v| "#{k}（#{internet_tel(v)}）"}
          .join("\n")
      end

      def is_oversized?
        oversized_data.values.any? { |v| v }
      end

      def oversized_data
        @oversized_data ||=
          GomiBot::Gomi.instance.oversized_reservation_day?(date: generate_date)
      end

      def internet_tel(val)
        case val
        when :Internet then "インターネット"
        when :Tel      then "電話"
        end
      end

      def oversized_message
        if is_oversized?
          oversized_header + oversized_body
        else
          ""
        end
      end

    end
  end
end
