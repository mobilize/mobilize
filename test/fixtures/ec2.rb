module Mobilize
  module Fixture
    module Ec2
      def Ec2.default(name)
        return Mobilize::Ec2.find_or_create_by(name: name)
      end
    end
  end
end
