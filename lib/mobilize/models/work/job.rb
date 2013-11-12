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

    def dir
      "~/.mobilize/jobs/#{ @job.id }".expand_path
    end

    def fail
      @job.update_status         :failed
    end

    def archive
      @job.delete #for now there is no archiving
      Log.write "Job #{ @job.id } archived."
    end

    def start
      @job.update_status       :started
    end

    def Job.perform( _cron_id, _box_id = nil, _job_id = nil )
      @cron                     = Cron.find _cron_id
      if _job_id
        _job                    = Job.find _job_id
      else
        _box_id                 = Box.find_self.id
        _job                    = @cron.create_job cron_id: _cron_id, box_id:  _box_id
        _job.start
      end
      _job.process
    end

    def process
      while 1 == 1
        _job.reload
        if _job.complete?
          Log.write "Job #{ _job.id } complete"
          return true
        elsif _job.timed_out?
          Log.write "Job #{ _job.id } timed out", "FATAL"
          return false
        elsif _job.failed?
          Log.write "Job #{ _job.id } failed", "FATAL"
          return false
        else
          _next_stage = _job.cron.next_stage
          _job.cron.next_stage.perform if _next_stage.status.nil?
        end
        sleep 2
      end
    end
  end
end
