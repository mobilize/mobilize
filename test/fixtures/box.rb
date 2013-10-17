module Mobilize
  module Fixture
    module Box
      def Box.default(name)
        return Mobilize::Box.find_or_create_by(name: name)
      end
    end
  end
end
