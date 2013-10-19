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

    def tripped_by_parent?
      _trigger            = self
      _job                = _trigger.job
      _parent             = _job.parent
      if _parent
        #child can't be tripped if parent is working or never completed
        return false     if _parent.working? or _parent.completed_at.nil?
        #child is triggered if it's never completed and parent has
        if                  _job.completed_at.nil?
          Logger.write      "#{_job.id} triggered by completed parent, never completed child"
          return true
        end
        #child is triggered if parent completed more recently
        if                  _parent.completed_at > _job.completed_at
          Logger.write      "#{_job.id} triggered by more recently completed parent"
          return true
        end
      end
      return false
    end

    def tripped_once?
      _trigger        = self
      _job            = _trigger.job
      if                _job.completed_at.nil?
        Logger.write    "#{_job.id} triggered by once, " +
                        "job never completed"
        return true
      elsif             _job.completed_at < _job.touched_at
        Logger.write    "#{_job.id} triggered by once, " +
                        "touched since last completion"
        return true
      else
        return false
      end
    end

    def disallowed?
      _trigger            = self
      _unit               = _trigger.unit
      _number             = _trigger.number
      _job                = _trigger.job
      #inactive jobs can't be triggered
      return true    unless _job.active
      #working jobs can't be triggered
      return true    if     _job.working?
      #day_of_month jobs can't be triggered unless it's today
      return true    if     _unit == "day_of_month" and Time.now.utc.day != _number
      #return false if failed more recently or more frequently than tolerance
      return true    if     _job.failed_at and
                           (_job.failed_at > Time.now.utc - _job.retry_delay or
                            _job.retries >= _job.max_retries)

    end

    def tripped?
      _trigger           = self
      return false if      _trigger.disallowed?
      #"once" jobs are triggered by user touched_at more recent than completed_at
      if                   _trigger.once
        return             _trigger.tripped_once?
      end
      #parent trigger
      if                   _trigger.parent_job_id
        return             _trigger.tripped_by_parent?
      end
      #time trigger
      if                   _trigger.number and _trigger.unit
        return             _trigger.tripped_by_time?
      end
      #nothing has triggered the job
      return false
    end

    def tripped_by_time?
      _trigger               = self
      _job                   = _trigger.job
      #triggered if unit is day/hour and never completed
      _due_at                = _trigger.due_at

      if                       _job.completed_at.nil? or
                               _job.completed_at < _due_at
        return                 _trigger.time_trip
      else
        return                 false
      end
    end

    def time_trip
      _trigger                = self
      _job                    = _trigger.job
      _call_method            = caller(1).first.split(" ").last[1..-2]
      _due_time_msg           = "due at #{_trigger.due_at}"
      _job_msg                = if _job.completed_at
                                  "job last completed #{_job.completed_at.utc}"
                                else
                                  "job never completed"
                                end
      Logger.write              "#{_trigger.id} from #{_call_method} #{_due_time_msg}; #{_job_msg}"
      return true
    end

    def due_field_format(field)
      _trigger                = self
      _job                    = _trigger.job
      _unit                   = _trigger.unit
      if                        field == "day"
        return                  _unit == "day_of_month" ? _trigger.number.to_s.rjust(2,'0') : nil
      else
        _field_number         = if _trigger.send "#{field}_due"
                                   _trigger.send "#{field}_due"
                                elsif _job.completed_at and _unit != "day_of_month"
                                   _job.completed_at.min
                                else
                                   0
                                end
        return                  _field_number.to_s.rjust(2,'0')
      end
    end

    def due_time_format
      _trigger                 = self
      #use base completed at of 00:00 for due comparison later
      _unit                    = _trigger.unit
      _day_due                 = _trigger.due_field_format("day")
      _minute_due              = _trigger.due_field_format("minute")
      _hour_due                = _trigger.due_field_format("hour")
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
      _trigger                 = self
      _current_time            = Time.now.utc
      _due_time_format         = _trigger.due_time_format
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
