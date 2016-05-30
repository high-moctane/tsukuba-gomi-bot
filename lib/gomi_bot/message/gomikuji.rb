module GomiBot
  module Message
    # TODO: いろいろなタイプのごみくじに対応したい
    class Gomikuji < GomiBot::Message::GeneratorTemplate

      def condition
        /\A((ごみ|ゴミ)(くじ|クジ|籤)|gomikuji)/i === @message
      end

      def only_to_me?
        false
      end

      def gen_message
        strike_list = (1..8).map { |i| strike_element }
        is_strike = strike_list.all?(&:itself)
        "ごみくじスタート(｀･ω･´)！！！\n\n" +
        "ﾃｯﾃｯﾃｰ↑ﾃｯﾃｯﾃｰ↓ﾃｯﾃｯﾃｰ↑ﾃｯﾃｯﾃｰ↓\n\n" +
        "ﾃﾞﾃﾞﾝ!!!\n\n" +
        "#{body(strike_list)}\n\n#{conclusion_message(is_strike)}"
      end

      def default
        gen_message
      end

      # private

      def body(strike_list)
        elems = strike_list.map { |i| element(i) }
        "  " + elems[0..2].join + "\n" +
          "  " + elems[3] + core + elems[4] + "\n" +
          "  " + elems[5..7].join
      end

      def element(is_strike)
        is_strike ? package[:strike_element] : package[:nonstrike_element]
      end

      def core
        package[:core]
      end

      def strike_element
        Random.rand(0...1000) < strike_element_rate * 1000
      end

      def strike_element_rate
        strike_rate ** (1.0/8.0)
      end

      def strike_message
        package[:strike_message]
      end

      def nonstrike_message
        package[:nonstrike_message]
      end

      def conclusion_message(is_strike)
        if is_strike
          "🎊🎯あたり🎯🎊\n\n" + strike_message
        else
          nonstrike_message
        end
      end

      def database
        @database ||= YAML.load_file(GomiBot.db_dir + "gomikuji.yml")
      end

      def package
        @package ||= database[:packages].sample
      end

      def strike_rate
        @strike_rate ||= database[:strike_rate]
      end

    end
  end
end
