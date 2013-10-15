require "test_helper"
class ScriptTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @Fixture                   = Mobilize::Fixture
    @github_public             = @Fixture::Github.public
    @worker_name               = Mobilize.config.fixture.ec2.worker_name
    @ec2                       = @Fixture::Ec2.default     @worker_name
    @ec2_session               = Mobilize::Ec2.session
    @ec2.find_or_create_instance @ec2_session
    @user                      = @Fixture::User.default    @ec2
    @script                    = @Fixture::Script.default  @ec2
    @script_session            = Mobilize::Script.session
    @github_session            = Mobilize::Github.session
    @job                       = @Fixture::Job.default     @user
    @stage                     = @Fixture::Stage.default   @job, 1, "read"
    @github_public_task        = @Fixture::Task.default    @stage, @github_public, @github_session
    @input_cmd                 = "(echo 'log this to the log' > log) && ls path1"
    @script_task               = @Fixture::Task.default    @stage, @script, @script_session,
                                                           input: @input_cmd,
                                                           subs: {
                                                           path1: @github_public_task.dir
                                                                       }
  end

  def test_run
    @github_public.read          @github_public_task
    @script.run                  @script_task
    result                     = @script_task.streams
    assert_in_delta              result[:stdin].length, 1, 1000
    assert_in_delta              result[:stdout].length, 1, 1000
    assert_equal                 result[:stderr], ""
    assert_equal                 result[:exit_signal], "0"
    assert_equal                 result[:log], "log this to the log"
  end
end
