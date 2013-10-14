module Mobilize
  module Fixture
    module Task
      def Task.default(stage,path,session,args={})
        @task = stage.tasks.find_or_create_by(
          stage_id: stage.id, path_id: path.id
        )
        @task.session = session
        @task.update_attributes(args) unless args.empty?
        @task
      end
    end
  end
end
