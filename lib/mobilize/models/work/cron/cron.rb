module Mobilize
  class Cron
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mobilize::Work
    include Mobilize::Cron::Trigger
    field      :name,                 type: String
    field      :active,               type: Boolean
    field      :crontab_id,           type: String
    field      :once,                 type: Boolean
    field      :parent_cron_id,       type: String
    #cron fields
    #e.g. every 12 hour after 23:45
    field      :number,               type: Fixnum #12
    field      :unit,                 type: String #hour, day, day_of_month
    field      :hour_due,             type: Fixnum #23
    field      :minute_due,           type: Fixnum #45
    field      :_id,                  type: String, default:->{ "#{ crontab_id }/#{ name }" }

    belongs_to :crontab
    has_one    :job
    has_many   :stages

    after_initialize :set_self
    def set_self
      @cron = self
    end

    def parent
      if @cron.parent_cron_id
        _parent_cron             = Cron.find @cron.parent_cron_id
        return                     _parent_cron
      end
    end

    def working?
      _next_stage                = @cron.next_stage
      _next_stage.working?      if _next_stage
    end

    def next_stage
      _stages                   = @cron.stages.sort_by { |_stage| _stage.order }
      _next_stage               = _stages.select { |_stage| !_stage.complete? }.first
      _next_stage
    end

    def complete
      @cron.update_status         :completed
    end

    def fail
      @cron.update_status         :failed
    end

    def purge!
      @cron.stages.each { |_stage| _stage.purge! }
      @cron.delete
      Log.write            "Purged cron #{ @cron.id }"
    end

    def Cron.enqueue( _cron_id )
      @cron                      = Cron.find _cron_id
      if _job                    = @cron.job
        _box                     = _job.box
        _queue                   = _box.queue
      else
        _job, _box               = nil, nil
        _queue                   = Mobilize.queue
      end

      if Box.find_self.nil?
        Log.write                "Enqueueing #{ @cron.id } remotely from #{ Socket.gethostname }"
        Cluster.master.sh        "mob cron enqueue #{ @cron.id }"
      else
        Resque.enqueue_to        _queue, Job, @cron.id, _box.id, _job.id
        Log.write                "Enqueued #{ @cron.id }"
      end


    end
  end
end
