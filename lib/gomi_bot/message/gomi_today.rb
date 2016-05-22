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
        header + body + footer
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
        "です"
      end

      def body
        data.map { |k, v| "#{k}：#{v.values.first}\n" }.join
      end

      def data
        @data ||= GomiBot::Gomi.instance.day(date: generate_date)
      end

    end
  end
end
