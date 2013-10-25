module Mobilize
  module Fixture
    module User
      def User.default
        Mobilize::User.find_or_create_by(
          active: true,
          google_login: Mobilize.config.google.owner.email,
          github_login: Mobilize.config.github.owner_login,
        )
      end
    end
  end
end
