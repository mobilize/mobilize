require "test_helper"
class TriggerTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @box                       = Mobilize::Box.find_or_create_by_name Mobilize.config.fixture.box.name
    @user                      = Mobilize::Fixture::User.default
    @job                       = Mobilize::Fixture::Job.default     @user, @box
    @parent_job                = Mobilize::Fixture::Job.parent      @user, @box
  end

  def test_tripped
    @class_methods             = Mobilize::Fixture::Trigger.methods false
    @trip_methods              = @class_methods.select{|m| m.to_s.starts_with?("_")}
    @trip_methods.each        { |trip_method|
      if                         trip_method.to_s.index("parent")
        @parent_job.delete
        @parent_job            = Mobilize::Fixture::Job.parent @user, @box
        @job.delete
        @job                   = Mobilize::Fixture::Job.default @user, @box
        @expected              = Mobilize::Fixture::Trigger.send(trip_method, @job, @parent_job)
      else
        @job.delete
        @job                   = Mobilize::Fixture::Job.default @user, @box
        @expected              = Mobilize::Fixture::Trigger.send(trip_method, @job)
      end
      Mobilize::Logger.write     "Checking Trigger #{trip_method.to_s}"
      assert_equal               @expected, @job.trigger.tripped?
                              }
  end

end
