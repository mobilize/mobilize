module Mobilize
  module Fixture
    module Task
      def Task.default(stage,path,session,args={})
        _task = stage.tasks.find_or_create_by(
          stage_id: stage.id, path_id: path.id
        )
        _task.session = session
        _task.update_attributes(args) unless args.empty?
        _task
      end
    end
  end
end
