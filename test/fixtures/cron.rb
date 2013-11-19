module Mobilize
  module Fixture
    module Cron
      def Cron.default( _crontab, _name )
        _cron                     = _crontab.crons.find_or_create_by active:     true,
                                                                     crontab_id: _crontab.id,
                                                                     once:       true,
                                                                     name:       _name
        _cron
      end

      def Cron._once( _crontab )
        _cron                     = _crontab.crons.find_or_create_by active:     true,
                                                                     crontab_id: _crontab.id,
                                                                     once:       true,
                                                                     name:       "cron_test",
                                                                     expected:   true
        _cron
      end

      def Cron._1h_completed_never( _crontab )
        _cron                     = _crontab.crons.find_or_create_by active:       true,
                                                                     crontab_id:   _crontab.id,
                                                                     number:       1,
                                                                     unit:         "hour",
                                                                     name:         "cron_test"

        _cron.update_attributes                                      completed_at: nil,
                                                                     expected: true
        _cron
      end

      def Cron._1h_completed_30m_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by active:      true,
                                                                crontab_id:  _crontab.id,
                                                                number:      1,
                                                                unit:        "hour",
                                                                name:        "cron_test"

        _cron.update_attributes                                 completed_at: _current_time - 30.minutes,
                                                                expected:     false
        _cron
      end

      def Cron._1h_completed_90m_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by active:      true,
                                                                crontab_id:  _crontab.id,
                                                                number:      1,
                                                                unit:        "hour",
                                                                name:        "cron_test"

        _cron.update_attributes                                 completed_at: _current_time - 90.minutes,
                                                                expected:     true
        _cron
      end

      def Cron._1h_after_15_completed_this_15_mark( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by active: true,
                                                                crontab_id: _crontab.id,
                                                                number:       1,
                                                                unit:         "hour",
                                                                hour_due:     nil,
                                                                minute_due:   (_current_time - 15.minutes).min,
                                                                name:         "cron_test"

        _cron.update_attributes                                 completed_at: _cron.due_at,
                                                                expected:     false
        _cron
      end

      def Cron._1d_after_0135_completed_2_0135_marks_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by active: true,
                                                                crontab_id: _crontab.id,
                                                                number:       1,
                                                                unit:         "day",
                                                                hour_due:     ( _current_time - 1.hour ).hour,
                                                                minute_due:   ( _current_time - 35.minutes ).min,
                                                                name:         "cron_test"

        _cron.update_attributes                                 completed_at: _cron.due_at - 1.day - 1.minute,
                                                                expected:     true
        _cron
      end

      def Cron._1d_after_0135_completed_1_0135_mark_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by active: true,
                                                                crontab_id: _crontab.id,
                                                                number:       1,
                                                                unit:         "day",
                                                                hour_due:     ( _current_time - 1.hour ).hour,
                                                                minute_due:   ( _current_time - 35.minutes ).min,
                                                                name:         "cron_test"

        _cron.update_attributes                                 completed_at: _cron.due_at,
                                                                expected:     false
        _cron
      end

      def Cron._5d_after_0135_completed_4_0135_marks_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by  active: true,
                                                                 crontab_id: _crontab.id,
                                                                 number:       5,
                                                                 unit:         "day",
                                                                 hour_due:     ( _current_time - 1.hour ).hour,
                                                                 minute_due:   ( _current_time - 35.minutes ).min,
                                                                 name:         "cron_test"

        _cron.update_attributes                                  completed_at: _cron.due_at + 1.day,
                                                                 expected: false
        _cron
      end

      def Cron._5d_after_0135_completed_6_0135_marks_ago( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by  active: true,
                                                                 crontab_id: _crontab.id,
                                                                 number:       5,
                                                                 unit:         "day",
                                                                 hour_due:     ( _current_time - 1.hour ).hour,
                                                                 minute_due:   ( _current_time - 35.minutes ).min,
                                                                 name:         "cron_test"

        _cron.update_attributes                                  completed_at: _cron.due_at - 1.day,
                                                                 expected:     true
        _cron
      end

      def Cron._parent_completed_child_failed( _crontab )
        _current_time               = Time.now.utc
        _parent_cron                = Cron.default _crontab, "parent_cron_test"
        _cron                       = _crontab.crons.find_or_create_by active: true,
                                                                       crontab_id:        _crontab.id,
                                                                       parent_cron_id:    _parent_cron.id,
                                                                       name:              "cron_test"

        _parent_cron.update_attributes                                 completed_at: _current_time - 1.minute

        _cron.update_attributes                                        failed_at:    _current_time -
                                                                                     Mobilize.config.work.retry_delay -
                                                                                     30.seconds,
                                                                       expected:     true
        [ _cron, _parent_cron ]
      end

      def Cron._parent_completed_child_completed( _crontab )
        _current_time               = Time.now.utc
        _parent_cron                = Cron.default _crontab, "parent_cron_test"
        _cron                       = _crontab.crons.find_or_create_by active:            true,
                                                                       crontab_id:        _crontab.id,
                                                                       parent_cron_id:    _parent_cron.id,
                                                                       name:              "cron_test"

        _parent_cron.update_attributes                                 completed_at: _current_time - 1.minute

        _cron.update_attributes                                        completed_at: _current_time - 30.seconds,
                                                                       expected:     false
        [ _cron, _parent_cron ]
      end

      def Cron._day_of_month_croned_date( _crontab )
        _current_time               = Time.now.utc
        _cron                       = _crontab.crons.find_or_create_by active:       true,
                                                                       crontab_id:   _crontab.id,
                                                                       number:       _current_time.day,
                                                                       unit:         "day_of_month",
                                                                       name:         "cron_test",
                                                                       expected:     true
        _cron
      end

      def Cron._day_of_month_not_croned_date( _crontab )
        _current_time               = Time.now.utc
        _cron                       = _crontab.crons.find_or_create_by active:       true,
                                                                       crontab_id:   _crontab.id,
                                                                       number:       ( _current_time - 1.day ).day,
                                                                       unit:         "day_of_month",
                                                                       name:         "cron_test",
                                                                       expected:     false
        _cron
      end

      def Cron._day_of_month_after_0100_completed_1_month_ago( _crontab )
        _current_time                   = Time.now.utc
        _cron                           = _crontab.crons.find_or_create_by active:       true,
                                                                           crontab_id:   _crontab.id,
                                                                           number:       _current_time.day,
                                                                           unit:         "day_of_month",
                                                                           hour_due:     ( _current_time - 1.hour ).hour,
                                                                           name: "cron_test"

        _cron.update_attributes                                            completed_at: _current_time - 1.month,
                                                                           expected:     true
        _cron
      end

      def Cron._day_of_month_after_0100_completed_0115( _crontab )
        _current_time        = Time.now.utc
        _cron                = _crontab.crons.find_or_create_by active:       true,
                                                                crontab_id:   _crontab.id,
                                                                number:       _current_time.day,
                                                                unit:         "day_of_month",
                                                                hour_due:     ( _current_time - 1.hour ).hour,
                                                                name:         "cron_test"

        _cron.update_attributes                                 completed_at: _cron.due_at + 15.minutes,
                                                                expected:     false
        _cron
      end
    end
  end
end
