module Mobilize
  module Fixture
    module Cron
      def Cron._once( _crontab, _name )
        _crontab.crons.find_or_create_by crontab_id: _crontab.id, once: true, name: _name
      end

      #cron methods return the expected results for @cron.tripped?

      def Cron._1h_completed_never( _crontab )
        _cron                     = _crontab.crons.find_or_create_by crontab_id:   _crontab.id,
                                         number:       1,
                                         unit:         "hour"

        _cron.update_attributes completed_at: nil
        true
      end

      def Cron._1h_completed_30m_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by crontab_id:       _crontab.id,
                                                                number:       1,
                                                                unit:         "hour"

        _cron.update_attributes completed_at: _current_time - 30.minutes
        false
      end

      def Cron._1h_completed_90m_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by crontab_id:   _crontab.id,
                                                                number:       1,
                                                                unit:         "hour"
        _cron.update_attributes completed_at: _current_time - 90.minutes
        true
      end

      def Cron._1h_after_15_completed_this_15_mark( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by(
                               crontab_id:       _crontab.id,
                               number:       1,
                               unit:         "hour",
                               hour_due:     nil,
                               minute_due:   (_current_time - 15.minutes).min
                               )
        _cron.update_attributes completed_at: _cron.due_at
        false
      end

      def Cron._1d_after_0135_completed_2_0135_marks_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by(
                               crontab_id:       _crontab.id,
                               number:       1,
                               unit:         "day",
                               hour_due:     ( _current_time - 1.hour ).hour,
                               minute_due:   ( _current_time - 35.minutes ).min
                               )
        _cron.update_attributes completed_at: _cron.due_at - 1.day - 1.minute
        true
      end

      def Cron._1d_after_0135_completed_1_0135_mark_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by(
                               crontab_id:       _crontab.id,
                               number:       1,
                               unit:         "day",
                               hour_due:     ( _current_time - 1.hour ).hour,
                               minute_due:   ( _current_time - 35.minutes ).min
                               )
        _cron.update_attributes completed_at: _cron.due_at
        false
      end

      def Cron._5d_after_0135_completed_4_0135_marks_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by(
                               crontab_id:       _crontab.id,
                               number:       5,
                               unit:         "day",
                               hour_due:     ( _current_time - 1.hour ).hour,
                               minute_due:   ( _current_time - 35.minutes ).min )

        _cron.update_attributes completed_at: _cron.due_at + 1.day
        false
      end

      def Cron._5d_after_0135_completed_6_0135_marks_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by(
                               crontab_id:       _crontab.id,
                               number:       5,
                               unit:         "day",
                               hour_due:     ( _current_time - 1.hour ).hour,
                               minute_due:   ( _current_time - 35.minutes ).min )

        _cron.update_attributes completed_at: _cron.due_at - 1.day
        true
      end

      def Cron._parent_completed_child_failed( _crontab, _parent_cron )
        _current_time               = Time.now.utc
        _crontab.crons.find_or_create_by crontab_id:        _crontab.id,
                                         parent_cron_id:    _parent_cron.id

        _parent_cron.update_attributes   completed_at: _current_time - 1.minute
        _crontab.update_attributes       failed_at:    _current_time - Mobilize.config.work.retry_delay - 30.seconds
        true
      end

      def Cron._parent_completed_child_completed( _crontab, _parent_crontab )
        _current_time               = Time.now.utc
        _crontab.crons.find_or_create_by(          crontab_id:        _crontab.id,
                                      parent_crontab_id: _parent_crontab.id )

        _parent_crontab.update_attributes completed_at: _current_time - 1.minute
        _crontab.update_attributes        completed_at: _current_time - 30.seconds
        false
      end

      def Cron._day_of_month_croned_date( _crontab )
        _current_time       = Time.now.utc
        _crontab.crons.find_or_create_by(
                              crontab_id:       _crontab.id,
                              number:       _current_time.day,
                              unit:         "day_of_month" )

        true
      end

      def Cron._day_of_month_not_croned_date( _crontab )
        _current_time       = Time.now.utc
        _crontab.crons.find_or_create_by(  crontab_id:       _crontab.id,
                              number:       ( _current_time - 1.day ).day, #yesterday day
                              unit:         "day_of_month" )

        false
      end

      def Cron._day_of_month_after_0100_completed_1_month_ago( _crontab )
        _current_time        = Time.now.utc
        _crontab.crons.find_or_create_by(   crontab_id:       _crontab.id,
                               number:       _current_time.day,
                               unit:         "day_of_month",
                               hour_due:     ( _current_time - 1.hour ).hour )

        _crontab.update_attributes completed_at: _current_time - 1.month
        true
      end

      def Cron._day_of_month_after_0100_completed_0115( _crontab )
        _current_time        = Time.now.utc
        _cron             = _crontab.crons.find_or_create_by(
                               crontab_id:       _crontab.id,
                               number:       _current_time.day,
                               unit:         "day_of_month",
                               hour_due:     ( _current_time - 1.hour ).hour )

        _crontab.update_attributes completed_at: _cron.due_at + 15.minutes
        false
      end
    end
  end
end
