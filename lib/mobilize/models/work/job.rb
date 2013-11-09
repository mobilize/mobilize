# a job describes a single cron run. it is archived & deleted on completion
module Mobilize
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
    field      :cron_id,          type: String
    field      :box_id,           type: String
    field      :name,             type: String, default:->{ Time.alphanunder_now }
    field      :_id,              type: String, default:->{ "#{ cron_id }/#{ box_id }/#{ name }"}
    belongs_to :cron

    after_initialize :set_self
    def set_self; @job = self;end

    def Job.perform( _cron_id, _box_id = nil, _job_id = nil )
      @cron                     = Cron.find _cron_id
      if _job_id
        _job                    = Job.find _job_id
      else
        _job                    = @cron.create_job cron_id: _cron_id, box_id:  _box_id
      end

      until _job.is { complete? or timed_out? }
            _job.cron.next_stage.perform
      end
    end
  end
end
