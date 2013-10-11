module Mobilize
  module Fixture
    module Github

      @@config = Mobilize.config.fixture.github

      def Github.public
        return Mobilize::Github.find_or_create_by    owner_name:  @@config.public.owner_name,
                                                     repo_name:   @@config.public.repo_name
      end
      def Github.private
        @domain                                    = @@config.private.domain
        @owner_name                                = @@config.private.owner_name
        @repo_name                                 = @@config.private.repo_name
        if @domain and @owner_name and @repo_name
          return Mobilize::Github.find_or_create_by  domain:     @domain,
                                                     owner_name: @owner_name,
                                                     repo_name:  @repo_name
        else
          Logger.info("missing private github params, returning nil for @github_private")
          return nil
        end
      end
    end
  end
end
