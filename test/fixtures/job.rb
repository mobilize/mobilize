module Mobilize
  module Fixture
    module Job
      def Job.default(user, ec2)
        user.jobs.create user_id: user.id, ec2_id: ec2.id, name: "test_job",        active: true
      end
      def Job.parent(user, ec2)
        user.jobs.create user_id: user.id, ec2_id: ec2.id, name: "test_job_parent", active: true
      end
    end
  end
end
