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
    Mobilize::Log.write                   "starting script test"
    _start_time                         = Time.now.utc
    Mobilize::Cli.perform                 [ "cron", "enqueue", @cron.id ]
    #monitor logs until expected messages are complete
    @test.expect _start_time
  end

  def expect( _start_time, _end_time = _start_time + 600, _sleep_time = 10 )
    _expecteds = [
          { model_id: @cron.id,               message: "sent remote enqueue" },
          { model_id: @cron.id,               message: "status set to started" },
          { model_id: @stage.id,              message: "cleared" },
          { model_id: @cron.id,               message: "enqueued locally" },
          { model_id: @stage.id,              message: "status set to started" },
          { model_id: @script_task.id,        message: "cleared" },
          { model_id: @script_task.id,        message: "status set to started" },
          { model_id: @script_task.id,        message: "local dir refreshed" },
          { model_id: @script_task.id,        message: "stdin written to local dir" },
          { model_id: @script_task.id,        message: "replaced cmd with pwd in dir" },
          { model_id: @script_task.id,        message: "status set to completed" },
          { model_id: @stage.id,              message: "status set to completed" },
          { model_id: @cron.id,               message: "status set to completed" },
        ]

    _model_ids = _expecteds.map { |_expected| _expected[ :model_id ] }
    _logs      = []
    while _logs.length != _expecteds.length
      if Time.now.utc > _end_time
        Mobilize::Log.write "script test timed out!", "FATAL"
      elsif _logs.length > _expecteds.length
        Mobilize::Log.write "script test has #{ _logs.length }, expecting #{ _expecteds.length }; too many logs!", "FATAL"
      else
        Mobilize::Log.write "script test has #{ _logs.length }, expecting #{ _expecteds.length }; waiting #{ _sleep_time.to_s }s for completion", "INFO"
      end
      sleep _sleep_time
      _logs = Mobilize::Log.where( :time.gte => _start_time, :model_id.in => _model_ids ).asc( :time ).to_a
    end

    _logs.each_with_index do |_log, _log_i|
      _expected = _expecteds[ _log_i ]
      assert_equal _expected[ :model_id ], _log[ :model_id ]
      assert_equal _expected[ :message ], _log[ :message ]
    end
  end
end
