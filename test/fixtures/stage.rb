module Mobilize
  module Fixture
    module Stage
      def Stage.default( _job, _order, _call )
        _stage = _job.stages.find_or_create_by(
          job_id: _job.id, order: _order, call: _call
        )
        _stage
      end
    end
  end
end
