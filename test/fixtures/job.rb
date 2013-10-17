module Mobilize
  module Fixture
    module Job
      def Job.default(user, box)
        user.jobs.create user_id: user.id, box_id: box.id, name: "test_job",        active: true
      end
      def Job.parent(user, box)
        user.jobs.create user_id: user.id, box_id: box.id, name: "test_job_parent", active: true
      end
    end
  end
end
