module Mobilize
  module Fixture
    module Task
      def Task.default( _stage, _order, _path, _args = {} )
        _task = _stage.tasks.find_or_create_by(
          stage_id: _stage.id, path_id: _path.id, order: _order
        )
        _task.update_attributes( _args ) unless _args.empty?
        _task
      end
    end
  end
end
