require "test_helper"
class ScriptTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @Fixture                   = Mobilize::Fixture
    @box                       = Mobilize::Box.find_or_create_by_name "mobilize-github-test"
    @user                      = @Fixture::User.default
    @stdin                     = "(echo 'log this to the log' > log) && cmd"
    @script                    = Mobilize::Script.find_or_create_by stdin: @stdin
    @script_session            = Mobilize::Script.session
    @job                       = @Fixture::Job.default     @user, @box
    @stage                     = @Fixture::Stage.default   @job, 1, "run"
    @script_task               = @Fixture::Task.default    @stage, @script, @script_session,
                                                           subs: {
                                                           cmd: 'pwd'
                                                                       }
  end

  def test_run
    @script.run                  @script_task
    @result                    = @script.streams                @script_task
    assert_equal                 @result[:stdin].strip,         @stdin.gsub("cmd","pwd")
    assert_equal                 @result[:stdout].strip,        @script_task.dir
    assert_equal                 @result[:stderr].strip,        ""
    assert_equal                 @result[:exit_signal].strip,   "0"
    assert_equal                 @result[:log].strip,           "log this to the log"
  end

  def teardown
    @box.terminate
  end
end
