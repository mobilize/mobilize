module Mobilize
  module Fixture
    module Github
      def Github.public
        return Mobilize::Github.find_or_create_by(
             owner_name: Mobilize.config.minitest.github.public.owner_name,
             repo_name: Mobilize.config.minitest.github.public.repo_name,
           )
      end
      def Github.public
        domain = Mobilize.config.minitest.github.private.domain
        owner_name = Mobilize.config.minitest.github.private.owner_name
        repo_name = Mobilize.config.minitest.github.private.repo_name
        if domain and owner_name and repo_name
          return Mobilize::Github.find_or_create_by(
            domain: domain,
            owner_name: owner_name,
            repo_name: repo_name
          )
        else
          Logger.info("missing private github params, returning nil for @github_private")
          return nil
        end
      end
    end
  end
end
