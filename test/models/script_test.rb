require "test_helper"
class ScriptTest < MiniTest::Unit::TestCase
  def setup
    @test                      = self
    @Fixture                   = Mobilize::Fixture
    @user                      = @Fixture::User.default
    @crontab                   = @Fixture::Crontab.default  @user
    @cron                      = @Fixture::Cron._once       @crontab,    "script_test"
    @stdin                     = "(echo 'log this to the log' > log) && cmd"
    @script                    = Mobilize::Script.find_or_create_by stdin: @stdin
    @stage                     = @Fixture::Stage.default   @cron, 1, "run"
    @script_task               = @Fixture::Task.default    @stage, 1, @script, subs: { cmd: 'pwd' }
  end

  def test_run
    Mobilize::Log.write                   "starting github test"
    #_start_time                         = Time.now.utc
    Mobilize::Cli.perform                 [ "cron", "enqueue", @cron.id ]
    #monitor logs until expected messages are complete
    #@test.expect _start_time
  end
end
