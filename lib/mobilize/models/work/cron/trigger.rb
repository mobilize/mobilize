#defines triggering methods for the cron model
module Mobilize
  class Cron
    module Trigger
      def triggered_by_parent?
        _parent             = @cron.parent
        if _parent
          #child can't be triggered if parent is working or never completed
          return false     if _parent.working? or _parent.completed_at.nil?
          #child is triggered if it's never completed and parent has
          if                  @cron.completed_at.nil?
            Log.write         "triggered by completed parent, never completed child", "INFO", @cron
            return true
          end
          #child is triggered if parent completed more recently
          if                  _parent.completed_at > @cron.completed_at
            Log.write         "triggered by more recently completed parent", "INFO", @cron
            return true
          end
        end
        return false
      end

      def triggered_once?
        if                @cron.never_completed?
          Log.write       "triggered by once, cron never completed", "INFO", @cron
          return true
        elsif             @cron.completed_at < @cron.touched_at
          Log.write       "triggered by once, touched since last completion", "INFO", @cron
          return true
        else
          return false
        end
      end

      def disallowed?
        _unit, _number      = @cron.unit, @cron.number
        #inactive crons can't be triggered
        return true   unless  @cron.active
        #crons w working jobs can't be triggered
        return true    if     @cron.job.working?
        #day_of_month crons can't be triggered unless it's today
        return true    if     _unit == "day_of_month" and Time.now.utc.day != _number
        return true    if     @cron.too_soon_for_retry? or @cron.too_many_failures?
        false
      end

      def triggered?
        return false if      @cron.disallowed?
        #"once" jobs are triggered by user touched_at more recent than completed_at
        if                   @cron.once
          return             @cron.triggered_once?
        end
        #parent trigger
        if                   @cron.parent_cron_id
          return             @cron.triggered_by_parent?
        end
        #time trigger
        if                   @cron.number and @cron.unit
          return             @cron.triggered_by_time?
        end
        #nothing has triggered the cron
        false
      end

      def triggered_by_time?
        #triggered if unit is day/hour and never completed
        if                       @cron.completed_at.nil? or
                                 @cron.completed_at < @cron.due_at
          return                 @cron.time_trip
        else
          return                 false
        end
      end

      def time_trip
        _call_method            = caller( 1 ).first.split( " " ).last[ 1..-2 ]
        _due_time_msg           = "due at #{ @cron.due_at }"
        _cron_msg               = if @cron.completed_at
                                    "cron last completed #{ @cron.completed_at.utc }"
                                  else
                                    "cron never completed"
                                  end
        Log.write                 "from #{ _call_method } #{ _due_time_msg }; #{ _cron_msg }", "INFO", @cron
        return true
      end

      def due_field_format( _field )
        _unit                   = @cron.unit
        if                        _field == "day"
          return                  _unit == "day_of_month" ? @cron.number.to_s.rjust( 2,'0' ) : nil
        else
          return                  @cron.field_number( _field, _unit ).to_s.rjust( 2,'0' )
        end
      end

      def field_number( _field, _unit )
        if @cron.send "#{ _field }_due"
          @cron.send "#{ _field }_due"
        elsif @cron.completed_at and _unit != "day_of_month"
          @cron.completed_at.min
        else
          0
        end
      end

      def due_time_format
        #use base completed at of 00:00 for due comparison later
        _unit                    = @cron.unit
        _day_due                 = @cron.due_field_format "day"
        _minute_due              = @cron.due_field_format "minute"
        _hour_due                = @cron.due_field_format "hour"
        _hour_minute_due         = "#{ _hour_due }:#{ _minute_due }"
        _due_time_format         = case _unit
                                   when "day_of_month"
                                     "%Y-%m-#{ _day_due } #{ _hour_minute_due } UTC"
                                   when "day"
                                     "%Y-%m-%d #{ _hour_minute_due } UTC"
                                   when "hour"
                                     "%Y-%m-%d %H:#{ _minute_due } UTC"
                                   end
        return                     _due_time_format
      end

      def due_at
        _current_time            = Time.now.utc
        _number, _unit           = @cron.number, @cron.unit
        _due_time_format         = @cron.due_time_format
        _base_due_at             = Time.parse( _current_time.strftime( _due_time_format ) )
        _time_ago                = if unit == "day_of_month"
                                     0
                                   elsif _current_time > _base_due_at
                                   ( _number-1 ).send _unit #due time has already happened today; use -1 unit ago
                                   else
                                    _number.send _unit    #due time has not happened yet today; use day,hour ago
                                   end
        _due_at                  = _base_due_at - _time_ago
        return                     _due_at
      end

      def too_soon_for_retry?
        @cron.failed_at and @cron.failed_at > Time.now.utc - @cron.retry_delay
      end

      def too_many_failures?
        @cron.failed_at and @cron.retries >= @cron.max_retries
      end
    end
  end
end
