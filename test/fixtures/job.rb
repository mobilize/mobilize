module Mobilize
  module Fixture
    module Job
      def Job.default( _user, _box, _name)
        _user.jobs.create user_id: _user.id, box_id: _box.id, name: _name, active: true
      end
    end
  end
end
