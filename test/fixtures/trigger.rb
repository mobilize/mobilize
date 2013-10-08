module Mobilize
  module Fixture
    module Trigger
      def Trigger._once(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end

      def Trigger._1h_completed_never(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end

      def Trigger._1h_completed_half_h_ago(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end

      def Trigger._1h_completed_1_and_half_h_ago(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end

      def Trigger._1h_after_45_completed_1_45_mark_ago(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end

      def Trigger._1d_after_0135_completed_2_0135_marks_ago(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end

      def Trigger._1d_after_0135_completed_1_0135_mark_ago(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end

      def Trigger._5d_after_0135_completed_5_0135_marks_ago(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end

      def Trigger._5d_after_0135_completed_6_0135_marks_ago(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end

      def Trigger._parent_completed_child_failed(job)
        job.create_trigger(
          job_id:   job.id,
          once:     true
        )
      end
    end
  end
end
