module Mobilize
  class Trigger
    include Mongoid::Document
    include Mongoid::Timestamps
    field :job_id
    #once trigger
    field :once,                 type: Boolean
    #parent trigger
    field :parent_job_id,        type: String
    #time trigger fields
    #e.g. every 12 hour after 23:45
    field :number,               type: Fixnum #12
    field :unit,                 type: String #hour, day, day_of_month
    field :hour_due,             type: Fixnum #23
    field :minute_due,           type: Fixnum #45
    field :_id,                  type: String, default:->{"#{job_id}.trigger"}
    belongs_to :job

    after_initialize :set_self
    def set_self
      @trigger = self
      @job     = @trigger.job
    end

    def tripped_by_parent?
      _parent             = @job.parent
      if _parent
        #child can't be tripped if parent is working or never completed
        return false     if _parent.working? or _parent.completed_at.nil?
        #child is triggered if it's never completed and parent has
        if                  @job.completed_at.nil?
          Log.write         "#{@job.id} triggered by completed parent, never completed child"
          return true
        end
        #child is triggered if parent completed more recently
        if                  _parent.completed_at > @job.completed_at
          Log.write         "#{@job.id} triggered by more recently completed parent"
          return true
        end
      end
      return false
    end

    def tripped_once?
      if                @job.completed_at.nil?
        Log.write       "#{@job.id} triggered by once, " +
                        "job never completed"
        return true
      elsif             @job.completed_at < @job.touched_at
        Log.write       "#{@job.id} triggered by once, " +
                        "touched since last completion"
        return true
      else
        return false
      end
    end

    def disallowed?
      _unit, _number = @trigger.unit, @trigger.number
      #inactive jobs can't be triggered
      return true   unless  @job.active
      #working jobs can't be triggered
      return true    if     @job.working?
      #day_of_month jobs can't be triggered unless it's today
      return true    if     _unit == "day_of_month" and Time.now.utc.day != _number
      return true    if     @trigger.too_soon_for_retry? or @trigger.too_many_failures?
    end

    def too_soon_for_retry?
      @job.failed_at and @job.failed_at > Time.now.utc - @job.retry_delay
    end

    def too_many_failures?
      @job.failed_at and @job.retries >= @job.max_retries
    end

    def tripped?
      return false if      @trigger.disallowed?
      #"once" jobs are triggered by user touched_at more recent than completed_at
      if                   @trigger.once
        return             @trigger.tripped_once?
      end
      #parent trigger
      if                   @trigger.parent_job_id
        return             @trigger.tripped_by_parent?
      end
      #time trigger
      if                   @trigger.number and @trigger.unit
        return             @trigger.tripped_by_time?
      end
      #nothing has triggered the job
      return false
    end

    def tripped_by_time?
      #triggered if unit is day/hour and never completed
      _due_at                = @trigger.due_at

      if                       @job.completed_at.nil? or
                               @job.completed_at < _due_at
        return                 @trigger.time_trip
      else
        return                 false
      end
    end

    def time_trip
      _call_method            = caller(1).first.split(" ").last[1..-2]
      _due_time_msg           = "due at #{@trigger.due_at}"
      _job_msg                = if @job.completed_at
                                  "job last completed #{@job.completed_at.utc}"
                                else
                                  "job never completed"
                                end
      Log.write                 "#{@trigger.id} from #{_call_method} #{_due_time_msg}; #{_job_msg}"
      return true
    end

    def due_field_format( _field )
      _unit                   = @trigger.unit
      if                        _field == "day"
        return                  _unit == "day_of_month" ? @trigger.number.to_s.rjust(2,'0') : nil
      else
        return                  @trigger.field_number( _field, _unit ).to_s.rjust(2,'0')
      end
    end

    def field_number( _field, _unit )
      if @trigger.send "#{ _field }_due"
        @trigger.send "#{ _field }_due"
      elsif @job.completed_at and _unit != "day_of_month"
        @job.completed_at.min
      else
        0
      end
    end

    def due_time_format
      #use base completed at of 00:00 for due comparison later
      _unit                    = @trigger.unit
      _day_due                 = @trigger.due_field_format("day")
      _minute_due              = @trigger.due_field_format("minute")
      _hour_due                = @trigger.due_field_format("hour")
      _hour_minute_due         = "#{_hour_due}:#{_minute_due}"
      _due_time_format         = case _unit
                                 when "day_of_month"
                                   "%Y-%m-#{_day_due} #{_hour_minute_due} UTC"
                                 when "day"
                                   "%Y-%m-%d #{_hour_minute_due} UTC"
                                 when "hour"
                                   "%Y-%m-%d %H:#{_minute_due} UTC"
                                 end
      return                     _due_time_format
    end

    def due_at
      _current_time            = Time.now.utc
      _number, _unit           = @trigger.number, @trigger.unit
      _due_time_format         = @trigger.due_time_format
      _base_due_at             = Time.parse(_current_time.strftime(_due_time_format))
      _time_ago                = if unit == "day_of_month"
                                   0
                                 elsif _current_time > _base_due_at
                                 (_number-1).send(_unit) #due time has already happened today; use -1 unit ago
                                 else
                                  _number.send(_unit)    #due time has not happened yet today; use day,hour ago
                                 end
      _due_at                  = _base_due_at - _time_ago
      return                     _due_at
    end
  end
end
