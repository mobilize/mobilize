module Mobilize
  module Fixture
    module Job
      def Job.default(user)
        user.jobs.create(user_id: user.id, name: "test_job", active: true)
      end
      def Job.parent(user)
        user.jobs.create(user_id: user.id, name: "test_job_parent", active: true)
      end
    end
  end
end
