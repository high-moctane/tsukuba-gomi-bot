module GomiBot
  module Message
    # TODO: いろいろなタイプのごみくじに対応したい
    class Gomikuji < GomiBot::Message::GeneratorTemplate
      STRIKE_RATE = 0.1

      def condition
        /\A((ごみ|ゴミ)(くじ|クジ|籤)|gomikuji)/i === @message
      end

      def only_to_me?
        false
      end

      def gen_message
        strike_list = (1..8).map { |i| strike_element }
        is_strike = strike_list.all?(&:itself)
        "ごみくじスタート(｀･ω･´)！！！\n\nﾃﾞﾃﾞﾝ!!!\n\n" +
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
        is_strike ? "🔥" : "❄"
      end

      def core
        "💌"
      end

      def strike_element
        Random.rand(0...1000) < strike_element_rate * 1000
      end

      def strike_element_rate
        STRIKE_RATE ** (1.0/8.0)
      end

      def strike_message
        "あなたは思い出の手紙を燃やせるごみにできました"
      end

      def nonstrike_message
        "あなたは思い出の手紙を燃やせるごみにできませんでした"
      end

      def conclusion_message(is_strike)
        if is_strike
          strike_message
        else
          nonstrike_message
        end
      end
    end
  end
end