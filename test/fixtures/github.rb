module Mobilize
  module Fixture
    module Github

      def Github.public
        return Mobilize::Github.find_or_create_by    owner_name:  Mobilize.config.fixture.github.public.owner_name,
                                                     repo_name:   Mobilize.config.fixture.github.public.repo_name
      end
      def Github.private
        _domain                                    = Mobilize.config.fixture.github.private.domain
        _owner_name                                = Mobilize.config.fixture.github.private.owner_name
        _repo_name                                 = Mobilize.config.fixture.github.private.repo_name
        if _domain and _owner_name and _repo_name
          return Mobilize::Github.find_or_create_by  domain:     _domain,
                                                     owner_name: _owner_name,
                                                     repo_name:  _repo_name
        else
          Logger.write                               "missing private github params, " +
                                                     "returning nil for _github_private"
          return nil
        end
      end
    end
  end
end
