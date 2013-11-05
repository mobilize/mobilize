module Mobilize
  module Fixture
    module Trigger
      def Trigger._once( _job )
        _job.create_trigger( job_id: _job.id,
                             once:   true )
        true
      end

      #trigger methods return the expected results for @trigger.tripped?

      def Trigger._1h_completed_never( _job )
        _job.create_trigger( job_id:       _job.id,
                             number:       1,
                             unit:         "hour" )

        _job.update_attributes completed_at: nil
        true
      end

      def Trigger._1h_completed_30m_ago( _job )
        _current_time        = Time.now.utc
        _job.create_trigger( job_id:       _job.id,
                             number:       1,
                             unit:         "hour" )

        _job.update_attributes completed_at: _current_time - 30.minutes
        false
      end

      def Trigger._1h_completed_90m_ago( _job )
        _current_time        = Time.now.utc
        _job.create_trigger( job_id:       _job.id,
                             number:       1,
                             unit:         "hour" )

        _job.update_attributes completed_at: _current_time - 90.minutes
        true
      end

      def Trigger._1h_after_15_completed_this_15_mark( _job )
        _current_time        = Time.now.utc
        _trigger             = _job.create_trigger(
                               job_id:       _job.id,
                               number:       1,
                               unit:         "hour",
                               hour_due:     nil,
                               minute_due:   (_current_time - 15.minutes).min
                               )
        _job.update_attributes completed_at: _trigger.due_at
        false
      end

      def Trigger._1d_after_0135_completed_2_0135_marks_ago( _job )
        _current_time        = Time.now.utc
        _trigger             = _job.create_trigger(
                               job_id:       _job.id,
                               number:       1,
                               unit:         "day",
                               hour_due:     ( _current_time - 1.hour ).hour,
                               minute_due:   ( _current_time - 35.minutes ).min
                               )
        _job.update_attributes completed_at: _trigger.due_at - 1.day - 1.minute
        true
      end

      def Trigger._1d_after_0135_completed_1_0135_mark_ago( _job )
        _current_time        = Time.now.utc
        _trigger             = _job.create_trigger(
                               job_id:       _job.id,
                               number:       1,
                               unit:         "day",
                               hour_due:     ( _current_time - 1.hour ).hour,
                               minute_due:   ( _current_time - 35.minutes ).min
                               )
        _job.update_attributes completed_at: _trigger.due_at
        false
      end

      def Trigger._5d_after_0135_completed_4_0135_marks_ago( _job )
        _current_time        = Time.now.utc
        _trigger             = _job.create_trigger(
                               job_id:       _job.id,
                               number:       5,
                               unit:         "day",
                               hour_due:     ( _current_time - 1.hour ).hour,
                               minute_due:   ( _current_time - 35.minutes ).min )

        _job.update_attributes completed_at: _trigger.due_at + 1.day
        false
      end

      def Trigger._5d_after_0135_completed_6_0135_marks_ago( _job )
        _current_time        = Time.now.utc
        _trigger             = _job.create_trigger(
                               job_id:       _job.id,
                               number:       5,
                               unit:         "day",
                               hour_due:     ( _current_time - 1.hour ).hour,
                               minute_due:   ( _current_time - 35.minutes ).min )

        _job.update_attributes completed_at: _trigger.due_at - 1.day
        true
      end

      def Trigger._parent_completed_child_failed( _job, _parent_job )
        _current_time               = Time.now.utc
        _job.create_trigger(          job_id:        _job.id,
                                      parent_job_id: _parent_job.id )

        _parent_job.update_attributes completed_at: _current_time - 1.minute
        _job.update_attributes        failed_at:    _current_time - Mobilize.config.work.retry_delay - 30.seconds
        true
      end

      def Trigger._parent_completed_child_completed( _job, _parent_job )
        _current_time               = Time.now.utc
        _job.create_trigger(          job_id:        _job.id,
                                      parent_job_id: _parent_job.id )

        _parent_job.update_attributes completed_at: _current_time - 1.minute
        _job.update_attributes        completed_at: _current_time - 30.seconds
        false
      end

      def Trigger._day_of_month_triggered_date( _job )
        _current_time       = Time.now.utc
        _job.create_trigger(
                              job_id:       _job.id,
                              number:       _current_time.day,
                              unit:         "day_of_month" )

        true
      end

      def Trigger._day_of_month_not_triggered_date( _job )
        _current_time       = Time.now.utc
        _job.create_trigger(  job_id:       _job.id,
                              number:       ( _current_time - 1.day ).day, #yesterday day
                              unit:         "day_of_month" )

        false
      end

      def Trigger._day_of_month_after_0100_completed_1_month_ago( _job )
        _current_time        = Time.now.utc
        _job.create_trigger(   job_id:       _job.id,
                               number:       _current_time.day,
                               unit:         "day_of_month",
                               hour_due:     ( _current_time - 1.hour ).hour )

        _job.update_attributes completed_at: _current_time - 1.month
        true
      end

      def Trigger._day_of_month_after_0100_completed_0115( _job )
        _current_time        = Time.now.utc
        _trigger             = _job.create_trigger(
                               job_id:       _job.id,
                               number:       _current_time.day,
                               unit:         "day_of_month",
                               hour_due:     ( _current_time - 1.hour ).hour )

        _job.update_attributes completed_at: _trigger.due_at + 15.minutes
        false
      end
    end
  end
end
