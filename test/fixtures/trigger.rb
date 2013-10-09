module Mobilize
  module Fixture
    module Trigger
      def Trigger._once(job)
        @job                = job
        @trigger            = @job.create_trigger(
                              job_id:       @job.id,
                              once:         true
                              )
        return                true
      end

      #trigger methods return the expected results for @trigger.tripped?

      def Trigger._1h_completed_never(job)
        @job                 = job
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       1,
                               unit:         "hour"
                               )
        @job.update_attributes completed_at: nil
        return                 true
      end

      def Trigger._1h_completed_30m_ago(job)
        @job                 = job
        @current_time        = Time.now.utc
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       1,
                               unit:         "hour"
                               )
        @job.update_attributes completed_at: @current_time - 30.minutes
        return                 false
      end

      def Trigger._1h_completed_90m_ago(job)
        @job                 = job
        @current_time        = Time.now.utc
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       1,
                               unit:         "hour"
                               )
        @job.update_attributes completed_at: @current_time - 90.minutes
        return                 true
      end

      def Trigger._1h_after_15_completed_this_15_mark(job)
        @job                 = job
        @current_time        = Time.now.utc
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       1,
                               unit:         "hour",
                               hour_due:     nil,
                               minute_due:   (@current_time - 15.minutes).min
                               )
        @job.update_attributes completed_at: @trigger.due_at
        return                 false
      end

      def Trigger._1d_after_0135_completed_2_0135_marks_ago(job)
        @job                 = job
        @current_time        = Time.now.utc
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       1,
                               unit:         "day",
                               hour_due:     (@current_time - 1.hour).hour,
                               minute_due:   (@current_time - 35.minutes).min
                               )
        @job.update_attributes completed_at: @trigger.due_at - 1.day - 1.minute
        return                 true
      end

      def Trigger._1d_after_0135_completed_1_0135_mark_ago(job)
        @job                 = job
        @current_time        = Time.now.utc
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       1,
                               unit:         "day",
                               hour_due:     (@current_time - 1.hour).hour,
                               minute_due:   (@current_time - 35.minutes).min
                               )
        @job.update_attributes completed_at: @trigger.due_at
        return                 false
      end

      def Trigger._5d_after_0135_completed_4_0135_marks_ago(job)
        @job                 = job
        @current_time        = Time.now.utc
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       5,
                               unit:         "day",
                               hour_due:     (@current_time - 1.hour).hour,
                               minute_due:   (@current_time - 35.minutes).min
                               )
        @job.update_attributes completed_at: @trigger.due_at + 1.day
        return                 false
      end

      def Trigger._5d_after_0135_completed_6_0135_marks_ago(job)
        @job                 = job
        @current_time        = Time.now.utc
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       5,
                               unit:         "day",
                               hour_due:     (@current_time - 1.hour).hour,
                               minute_due:   (@current_time - 35.minutes).min
                               )
        @job.update_attributes completed_at: @trigger.due_at - 1.day
        return                 true
      end

      def Trigger._parent_completed_child_failed(job,parent_job)
        @job                        = job
        @parent_job                 = parent_job
        @current_time               = Time.now.utc
        @trigger                    = @job.create_trigger(
                                      job_id:        @job.id,
                                      parent_job_id: @parent_job.id
                                      )
        @parent_job.update_attributes completed_at: @current_time - 1.minute
        @job.update_attributes        failed_at:    @current_time - Mobilize.config.job.retry_delay - 30.seconds
        return                        true
      end

      def Trigger._parent_completed_child_completed(job,parent_job)
        @job                        = job
        @parent_job                 = parent_job
        @current_time               = Time.now.utc
        @trigger                    = @job.create_trigger(
                                      job_id:        @job.id,
                                      parent_job_id: @parent_job.id
                                      )
        @parent_job.update_attributes completed_at: @current_time - 1.minute
        @job.update_attributes        completed_at: @current_time - 30.seconds
        return                        false
      end

      def Trigger._day_of_month_triggered_date(job)
        @job                = job
        @current_time       = Time.now.utc
        @trigger            = @job.create_trigger(
                              job_id:       @job.id,
                              number:       @current_time.day,
                              unit:         "day_of_month"
                              )
        return                true
      end

      def Trigger._day_of_month_not_triggered_date(job)
        @job                = job
        @current_time       = Time.now.utc
        @trigger            = @job.create_trigger(
                              job_id:       @job.id,
                              number:       (@current_time - 1.day).day, #yesterday day
                              unit:         "day_of_month"
                              )
        return                false
      end

      def Trigger._day_of_month_after_0100_completed_1_month_ago(job)
        @job                 = job
        @current_time        = Time.now.utc
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       @current_time.day,
                               unit:         "day_of_month",
                               hour_due:     (@current_time - 1.hour).hour
                               )
        @job.update_attributes completed_at: @current_time - 1.month
        return                 true
      end

      def Trigger._day_of_month_after_0100_completed_0115(job)
        @job                 = job
        @current_time        = Time.now.utc
        @trigger             = @job.create_trigger(
                               job_id:       @job.id,
                               number:       @current_time.day,
                               unit:         "day_of_month",
                               hour_due:     (@current_time - 1.hour).hour
                               )
        @job.update_attributes completed_at: @trigger.due_at + 15.minutes
        return                 false
      end
    end
  end
end
