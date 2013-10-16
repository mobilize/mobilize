require "test_helper"
class ScriptTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @Fixture                   = Mobilize::Fixture
    @worker_name               = Mobilize.config.fixture.ec2.worker_name
    @ec2                       = @Fixture::Ec2.default     @worker_name
    @ec2_session               = Mobilize::Ec2.session
    @ec2.find_or_create_instance @ec2_session
    @user                      = @Fixture::User.default
    @stdin                     = "(echo 'log this to the log' > log) && cmd"
    @script                    = @Fixture::Script.default(@stdin)
    @script_session            = Mobilize::Script.session
    @job                       = @Fixture::Job.default     @user, @ec2
    @stage                     = @Fixture::Stage.default   @job, 1, "run"
    @script_task               = @Fixture::Task.default    @stage, @script, @script_session,
                                                           subs: {
                                                           cmd: 'pwd'
                                                                       }
  end

  def test_run
    @script.run                  @script_task
    @result                    = @script.streams          @script_task
    assert_equal                 @result[:stdin],         @stdin.gsub("cmd","pwd")
    assert_equal                 @result[:stdout],        @script_task.dir
    assert_equal                 @result[:stderr],        ""
    assert_equal                 @result[:exit_signal],   "0"
    assert_equal                 @result[:log],           "log this to the log"
  end
end
