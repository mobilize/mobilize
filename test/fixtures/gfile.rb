module Mobilize
  module Fixture
    module Gfile
      def Gfile.default
        Mobilize::Gfile.find_or_create_by(
        owner: Mobilize.config.minitest.google.email,
        name: "test_file"
        )
      end
    end
  end
end
