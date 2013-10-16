require "test_helper"
class TriggerTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @worker_name               = Mobilize.config.fixture.ec2.worker_name
    @ec2                       = Mobilize::Fixture::Ec2.default     @worker_name
    @ec2_session               = Mobilize::Ec2.session
    @ec2.find_or_create_instance @ec2_session
    @user                      = Mobilize::Fixture::User.default
    @job                       = Mobilize::Fixture::Job.default     @user, @ec2
    @parent_job                = Mobilize::Fixture::Job.parent      @user, @ec2
  end

  def test_tripped
    @class_methods             = Mobilize::Fixture::Trigger.methods false
    @trip_methods              = @class_methods.select{|m| m.to_s.starts_with?("_")}
    @trip_methods.each        { |trip_method|
      if                         trip_method.to_s.index("parent")
        @parent_job.delete
        @parent_job            = Mobilize::Fixture::Job.parent @user, @ec2
        @job.delete
        @job                   = Mobilize::Fixture::Job.default @user, @ec2
        @expected              = Mobilize::Fixture::Trigger.send(trip_method, @job, @parent_job)
      else
        @job.delete
        @job                   = Mobilize::Fixture::Job.default @user, @ec2
        @expected              = Mobilize::Fixture::Trigger.send(trip_method, @job)
      end
      Mobilize::Logger.info      "Checking Trigger #{trip_method.to_s}"
      assert_equal               @expected, @job.trigger.tripped?
                              }
  end

end
