module Mobilize
  module Fixture
    module Job
      def Job.default(user)
        user.jobs.create(user_id: user.id, name: "test_job")
      end
    end
  end
end
