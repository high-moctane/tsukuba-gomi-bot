module GomiBot
  module Message
    class GeneratorTemplate
      def initialize(message = "")
        @message = message
      end

      def call
        if condition
          gen_message
        else
          false
        end
      end

      def call!
        default
      end

      def condition
        false
      end

      def gen_message
        false
      end

      def default
        false
      end

      def only_to_me?
        true
      end
    end
  end
end