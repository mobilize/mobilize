module Mobilize
  module Fixture
    module Script
      def Script.default(stdin)
        Mobilize::Script.find_or_create_by(
          stdin: stdin
        )
      end
    end
  end
end
