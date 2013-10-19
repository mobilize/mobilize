module Mobilize
  module Fixture
    module Stage
      def Stage.default(job,order,call)
        _stage = job.stages.find_or_create_by(
          job_id: job.id, order: order, call: call
        )
        _stage
      end
    end
  end
end
