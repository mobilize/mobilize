module Mobilize
  module Fixture
    module Stage
      def Stage.default( _cron, _order, _call )
        _stage = _cron.stages.find_or_create_by(
          cron_id: _cron.id, order: _order, call: _call
        )
        _stage
      end
    end
  end
end
