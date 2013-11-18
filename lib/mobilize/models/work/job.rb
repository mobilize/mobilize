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
      Log.write "archived", "INFO", @job
    end

    def start
      @job.update_status       :started
    end

    def complete
      @job.update_status       :completed
    end

    def Job.perform( _cron_id, _box_id = nil, _job_id = nil )
      @cron                     = Cron.find _cron_id
      if _job_id
        @job                    = Job.find _job_id
      else
        _box_id                 = Box.find_self.id
        @job                    = @cron.create_job cron_id: _cron_id, box_id:  _box_id
        @job.start
      end
      @job.process
    end

    def process
      while 1 == 1
        @job.reload
        if @job.complete?
          @job.archive
          return true
        elsif @job.timed_out?
          Log.write "Timed out", "FATAL", @job
          return false
        elsif @job.failed?
          Log.write "Failed", "FATAL", @job
          return false
        elsif _next_stage = @job.cron.next_stage and
              _next_stage.status.nil?
          @job.cron.next_stage.perform
        end
        sleep 2
      end
    end
  end
end
