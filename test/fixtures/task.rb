module Mobilize
  module Fixture
    module Task
      def Task.default(job,path,call,session,args={})
        @task = job.tasks.find_or_create_by(
          job_id: job.id, path_id: path.id, call: call
        )
        @task.session = session
        @task.update_attributes(args)
        @task
      end
    end
  end
end
