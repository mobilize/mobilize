module Mobilize
  module Fixture
    module User
      def User.default
        Mobilize::User.find_or_create_by(
          active: true,
          google_login: Mobilize.config.fixture.google.email,
          github_login: Mobilize.config.fixture.github.login,
        )
      end
    end
  end
end
