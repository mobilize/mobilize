require "test_helper"
class GithubTest < MiniTest::Unit::TestCase
  def setup
    @test                      = self
    @Fixture                   = Mobilize::Fixture
    @github_public             = @Fixture::Github.public
    @user                      = @Fixture::User.default
    @crontab                   = @Fixture::Crontab.default  @user
    @cron                      = @Fixture::Cron._once       @crontab,    "github_test"
    @github_private            = @Fixture::Github.private
    @stage                     = @Fixture::Stage.default    @cron,    1, "read"
    #assign same session to both githubs
    @github_public_task        = @Fixture::Task.default     @stage,   1, @github_public
    @github_private_task       = @Fixture::Task.default     @stage,   2, @github_private
  end

  def test_run
    Mobilize::Log.write                   "starting github test"
    _start_time                         = Time.now.utc
    Mobilize::Cli.perform                 [ "cron", "enqueue", @cron.id ]
    #monitor logs until expected messages are complete
    @test.expect _start_time
  end

  def expect( _start_time, _end_time = _start_time + 600, _sleep_time = 10 )

    _start_expecteds = [
        { model_id: @cron.id,                 message: "sent remote enqueue" },
        { model_id: @cron.id,                 message: "status set to started" },
        { model_id: @stage.id,                message: "cleared" },
        { model_id: @cron.id,                 message: "enqueued locally" },
        { model_id: @stage.id,                message: "status set to started" },
        ]

    _task1_expecteds = [
        { model_id: @github_public_task.id,   message: "cleared" },
        { model_id: @github_public_task.id,   message: "status set to started" },
        { model_id: @github_public_task.id,   message: "local dir refreshed" },
        { model_id: @github_public.id,        message: "attempting public read" },
        { model_id: @github_public.id,        message: "read complete" },
        { model_id: @github_public.id,        message: "read into task dir" },
        { model_id: @github_public_task.id,   message: "status set to completed" },
    ]

    _task2_expecteds = [
        { model_id: @github_private_task.id,  message: "cleared" },
        { model_id: @github_private_task.id,  message: "status set to started" },
        { model_id: @github_private_task.id,  message: "local dir refreshed" },
        { model_id: @github_private.id,       message: "attempting public read" },
        { model_id: @github_private.id,       message: "public read failed, attempting private read" },
        { model_id: @github_private.id,       message: "list.collaborators successful" },
        { model_id: @github_private.id,       message: "#{ @user.id } has access" },
        { model_id: @github_private.id,       message: "read private repo" },
        { model_id: @github_private.id,       message: "read into task dir" },
        { model_id: @github_private_task.id,  message: "status set to completed" },
    ]

    _end_expecteds = [
        { model_id: @stage.id,                message: "status set to completed" },
        { model_id: @cron.id,                 message: "status set to completed" },
      ]

    _expecteds = _start_expecteds  + _task1_expecteds + _task2_expecteds + _end_expecteds

    _model_ids = _expecteds.map { |_expected| _expected[ :model_id ] }
    _logs      = []

    while _logs.length != _expecteds.length
      if Time.now.utc > _end_time
        Mobilize::Log.write "github test timed out!", "FATAL"
      elsif _logs.length > _expecteds.length
        Mobilize::Log.write "github test has #{ _logs.length }, expecting #{ _expecteds.length }; too many logs!", "FATAL"
      else
        Mobilize::Log.write "github test has #{ _logs.length }, expecting #{ _expecteds.length }; waiting #{ _sleep_time.to_s }s for completion", "INFO"
      end
      sleep _sleep_time
      _logs = Mobilize::Log.where( :time.gte => _start_time, :model_id.in => _model_ids ).asc( :time ).to_a
    end

    _task1_i, _task2_i = 0, 0
    _logs.each_with_index do |_log, _log_i|
      if _log_i < _start_expecteds.length or
         _log_i > ( _start_expecteds + _task1_expecteds + _task2_expecteds ).length
        #before or after all task logs evaluated
        _expected = _expecteds[ _log_i ]
        assert_equal _expected[ :model_id ], _log[ :model_id ]
        assert_equal _expected[ :message ], _log[ :message ]
      else
        _task1_expected = _task1_expecteds[ _task1_i]
        _task2_expected = _task2_expecteds[ _task2_i]
        #must follow order of task logs
        if _task1_expected and _task1_expected[ :model_id ] == _log[ :model_id ]
          assert_equal   _task1_expected[ :message ], _log[ :message ]
          _task1_i += 1
        else
          assert_equal _task2_expected[ :message ], _log[ :message ]
          _task2_i += 1
        end
      end
    end
  end
end
