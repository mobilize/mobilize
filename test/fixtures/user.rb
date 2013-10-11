module Mobilize
  module Fixture
    module User
      def User.default(ec2)
        ec2.users.find_or_create_by(
          active: true,
          google_login: Mobilize.config.fixture.google.email,
          github_login: Mobilize.config.fixture.github.login,
          ec2_id: ec2.id
        )
      end
    end
  end
end
