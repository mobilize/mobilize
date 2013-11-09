module Mobilize
  module Fixture
    module Cron
      def Crontab.default( _user )
        _user.crontabs.find_or_create_by user_id:  _user.id,
                                         name:     Mobilize.config.fixture.crontab.name,
                                         gbook_id: Mobilize.config.fixture.crontab.gbook_id
      end
    end
  end
end
