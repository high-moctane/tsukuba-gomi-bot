require "date"
require "pp"

module GomiBot
  module Message
    class GomiSearch < GomiBot::Message::GeneratorTemplate

      def condition
        parse_gomi
      end

      def gen_message
        header + body + footer
      end

      def parse_gomi
        case @message
        when /\A(も|燃|萌)(え|やせ)る/
          :燃やせるごみ
        when /\A(も|燃|萌)(え|やせ)ない/
          :燃やせないごみ
        when /\Aかん|缶|カン/
          :かん
        when /\A粗大|そだい/
          :粗大ごみ
        when /\A古(紙|布)/
          :古紙・古布
        when /\Aペット/
          :ペットボトル
        when /\A(びん|瓶|ビン|スプレー)/
          :びん・スプレー容器
        else
          false
        end
      end

      def date
        if Time.now.hour < 12
          Date.today
        else
          Date.today.next
        end
      end

      def data
        @data ||= GomiBot::Gomi.instance.next_garb_collect(
          parse_gomi, start_date: date
        )
      end

      def header
        "次の #{parse_gomi} の回収日は\n"
      end

      def body
        data.map { |k, v|
          "#{k}：#{v.keys.first.to_s_ja}（#{(v.keys.first - Date.today).to_i}日後）\n"
        }.join
      end

      def footer
        "です"
      end

    end
  end
end
