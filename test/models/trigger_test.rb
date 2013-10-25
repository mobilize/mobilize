require "test_helper"
class TriggerTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @box                       = Mobilize::Box.find_or_create_by_name "mobilize-trigger-test"
    @user                      = Mobilize::Fixture::User.default
  end

  def test_tripped
    _job                       = Mobilize::Fixture::Job.default     @user, @box
    _parent_job                = Mobilize::Fixture::Job.parent      @user, @box
    _class_methods             = Mobilize::Fixture::Trigger.methods false
    _trip_methods              = _class_methods.select{|_method| _method.to_s.starts_with?("_")}
    _trip_methods.each        { |_trip_method|
      if                         _trip_method.to_s.index("parent")
        _parent_job.delete
        _parent_job            = Mobilize::Fixture::Job.parent   @user, @box
        _job.delete
        _job                   = Mobilize::Fixture::Job.default  @user, @box
        _expected              = Mobilize::Fixture::Trigger.send _trip_method, _job, _parent_job
      else
        _job.delete
        _job                   = Mobilize::Fixture::Job.default @user, @box
        _expected              = Mobilize::Fixture::Trigger.send(_trip_method, _job)
      end
      Mobilize::Logger.write     "Checking Trigger #{_trip_method.to_s}"
      assert_equal               _expected, _job.trigger.tripped?
                              }
  end

  def teardown
    @box.terminate
  end
end
