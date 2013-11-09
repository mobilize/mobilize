module Mobilize
  module Fixture
    module Cron
      def Cron.default( _crontab, _name )
        _crontab.crons.find_or_create_by crontab_id: _crontab.id, name: _name, once: true
      end
    end
  end
end
