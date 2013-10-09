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
      @trigger            = self
      @job                = @trigger.job
      @parent             = @job.parent
      if @parent
        #child can't be tripped if parent is working or never completed
        return false     if @parent.working? or @parent.completed_at.nil?
        #child is triggered if it's never completed and parent has
        if                  @job.completed_at.nil?
          Logger.info       "#{@job.id} triggered by completed parent, never completed child"
          return true
        end
        #child is triggered if parent completed more recently
        if                  @parent.completed_at > @job.completed_at
          Logger.info       "#{@job.id} triggered by more recently completed parent"
          return true
        end
      end
      return false
    end

    def tripped_once?
      @trigger        = self
      @job            = @trigger.job
      if                @job.completed_at.nil?
        Logger.info     "#{@job.id} triggered by once, " +
                        "job never completed"
        return true
      elsif             @job.completed_at < @job.touched_at
        Logger.info     "#{@job.id} triggered by once, " +
                        "touched since last completion"
        return true
      else
        return false
      end
    end

    def disallowed?
      @trigger            = self
      @unit               = @trigger.unit
      @number             = @trigger.number
      @job                = @trigger.job
      #inactive jobs can't be triggered
      return true    unless @job.active
      #working jobs can't be triggered
      return true    if     @job.working?
      #day_of_month jobs can't be triggered unless it's today
      return true    if     @unit == "day_of_month" and Time.now.utc.day != @number
      #return false if failed more recently or more frequently than tolerance
      return true    if     @job.failed_at and
                           (@job.failed_at > Time.now.utc - @job.retry_delay or
                            @job.retries >= @job.max_retries)

    end

    def tripped?
      @trigger           = self
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
      @trigger               = self
      @job                   = @trigger.job
      @number                = @trigger.number
      @unit                  = @trigger.unit
      #triggered if unit is day/hour and never completed
      @due_at                = @trigger.due_at

      if                       @job.completed_at.nil? or
                               @job.completed_at < @due_at
        return                 @trigger.time_trip
      else
        return                 false
      end
    end

    def time_trip
      @trigger                = self
      @job                    = @trigger.job
      @call_method            = caller(1).first.split(" ").last[1..-2]
      @current_time           = Time.now.utc
      @due_time_msg           = "due at #{@trigger.due_at}"
      @job_msg                = if @job.completed_at
                                  "job last completed #{@job.completed_at.utc}"
                                else
                                  "job never completed"
                                end
      Logger.info               "#{@trigger.id} from #{@call_method} #{@due_time_msg}; #{@job_msg}"
      return true
    end

    def due_time_format
      @trigger                 = self
      @unit                    = @trigger.unit
      @number                  = @trigger.number
      @day_due                 = @unit=="day_of_month" ? @number.to_s.rjust(2,'0') : nil
      @minute_due              = @trigger.minute_due ? @trigger.minute_due.to_s.rjust(2,'0') : "00"
      @hour_due                = @trigger.hour_due   ? @trigger.hour_due.to_s.rjust(2,'0')   : "00"
      @hour_minute_due         = "#{@hour_due}:#{@minute_due}"
      @due_time_format         = case @unit
                                 when "day_of_month"
                                   "%Y-%m-#{@day_due} #{@hour_minute_due} UTC"
                                 when "day"
                                   "%Y-%m-%d #{@hour_minute_due} UTC"
                                 when "hour"
                                   "%Y-%m-%d %H:#{@minute_due} UTC"
                                 end
      return @due_time_format
    end

    def due_at
      @trigger                 = self
      @current_time            = Time.now.utc
      @due_time_format         = @trigger.due_time_format
      @base_due_at             = Time.parse(@current_time.strftime(@due_time_format))
      @time_ago                = if unit == "day_of_month"
                                   0
                                 elsif @current_time > @base_due_at
                                 (@number-1).send(@unit) #due time has already happened today; use -1 unit ago
                                 else
                                  @number.send(@unit)    #due time has not happened yet today; use day,hour ago
                                 end
      @due_at                  = @base_due_at - @time_ago
      return                     @due_at
    end
  end
end
