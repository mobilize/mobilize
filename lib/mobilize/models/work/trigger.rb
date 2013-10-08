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
    field :hour_mark,            type: Fixnum #23
    field :minute_mark,          type: Fixnum #45
    field :_id,                  type: String, default:->{"#{job_id}.trigger"}
    belongs_to :job

    def tripped_by_parent?
      @trigger           = self
      @job               = @trigger.job
      @parent            = @job.parent
      if @parent
        #child can't be tripped if parent is working or never completed
        return false     if @parent.is_working? or @parent.completed_at.nil?
        #child is triggered if it's never completed and parent has
        if @job.completed_at.nil?
          Logger.info    "#{@job.id} triggered by completed parent, never completed child"
          return true
        end
        #child is triggered if parent completed more recently
        if @parent.completed_at > @job.completed_at
          Logger.info    "#{@job.id} triggered by more recently completed parent"
          return true
        end
      end
      return false
    end

    def tripped?
      @trigger           = self
      @job               = @trigger.job
      #inactive jobs can't be triggered
      return false  unless @job.active
      #working jobs can't be triggered
      return false  if     @job.working?
      #"once" jobs are triggered by user touched_at more recent than completed_at
      if                   @trigger.once
        return             @job.completed_at < @job.touched_at ? true : false
      end
      #return false if failed more recently than retry tolerance
      return false  if     @job.failed_at > Time.now.utc - @job.retry_delay
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
      @trigger                 = self
      @job                     = @trigger.job
      @unit                    = @trigger.unit
      if                         @unit == "hour" or @unit == "day"
        return                   @trigger.tripped_by_hour_or_day?
      elsif                      @unit == "day_of_month"
        return                   @trigger.tripped_by_day_of_month?
      end
      #if nothing happens, return false
      return false
    end

    def tripped_by_day_of_month?
      @trigger                 = self
      @job                     = @trigger.job
      @number                  = @trigger.number
      @current_time            = Time.now.utc
      #never triggered unless it's the correct day
      return false unless        @current_time.day == @number.to_i
      @mark_time               = @job.mark_time(@current_time)
      if                         @mark_time
        if                       @current_time > @mark_time
          if                     @job.completed_at.nil?
            Logger.info          "#{@job.id} triggered by day_of_month, " +
                                 "mark time before current time, job never completed"
            return true
          elsif                  @job.completed_at.to_date < @current_time.to_date
            Logger.info          "#{@job.id} triggered by day_of_month, " +
                                 "mark time before current time, job not yet completed today"
            return true
          else
            return false
          end
        else
          return false
        end
      elsif                      @job.completed_at.to_date < @current_time.to_date
        Logger.info              "#{@job.id} triggered by day_of_month, job not yet completed today"
        return true
      else
        return false
      end
    end


    def tripped_by_hour_or_day?
      @trigger               = self
      @job                   = @trigger.job
      @number                = @trigger.number
      @unit                  = @trigger.unit
      @current_time          = Time.now.utc
      #triggered if unit is day/hour and never completed
      if                       @job.completed_at.nil?
        Logger.info            "#{@job.id} triggered by hour/day unit, never completed"
        return true
      end
      @marked_at             = @job.marked_at
      if                       @marked_at
        if                     @job.completed_at < @marked_at
          Logger.info          "#{@job.id} triggered by marked at: #{@marked_at} " +
                               "more recent than completed at: #{@job.completed_at}"
          return true
        else
          return false
        end
      else
        @time_ago            = @number.to_i.send(@unit)
        if                   @job.completed_at < (@current_time - @time_ago)
          Logger.info        "#{@job.id} triggered by job completed longer than specified hour/day ago"
          return true
        else
          #not triggered
          return false
        end
      end
    end

    private

    #if mark is 00:45, current mark time is YYYY-MM-DD 00:45
    def mark_time(current_time)
      @trigger                 = self
      @job                     = @trigger.job
      @current_time            = current_time
      @unit                    = @trigger.unit
      #get mark time
      @mark_hour               = @trigger.hour_mark.to_s.rjust(2,'0')
      @mark_minute             = @trigger.minute_mark ? @trigger.minute_mark.to_s.rjust(2,'0') : "00"
      @mark_time               = "#{@mark_hour}:#{@mark_minute}"
      #figure out current mark time for hour or day by inserting mark time into time string
      @time_string             = case @unit
                                 when "day","day_of_month"
                                   "%Y-%m-%d #{@mark_time} UTC"
                                 when "hour"
                                   "%Y-%m-%d %H:#{@mark_minute} UTC"
                                 end
      return                     Time.parse(@current_time.strftime(@time_string))
    end

    def marked_at
      @trigger                 = self
      @job                     = @trigger.job
      return nil               unless @trigger.hour_mark
      @number                  = @trigger.number
      @unit                    = @trigger.unit

      @current_time            = Time.now.utc
      @mark_time               = @job.mark_time(@current_time)

      @time_ago                = if @current_time > @mark_time
                                   (@number-1).send(@unit) #mark has already happened; use (day,month)-1 ago
                                 else
                                    @number.send(@unit) #mark has not happened yet; use (day,month) ago
                                 end

      @marked_at               = @mark_time - @time_ago
      return                     @marked_at
    end
  end
end
