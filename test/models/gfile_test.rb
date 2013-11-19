require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    @test                               = self
    @Fixture, @Gfile, @Script           = Mobilize::Fixture, Mobilize::Gfile, Mobilize::Script
    @Config                             = Mobilize.config.fixture

    @gfile_owner, @gfile_name           = Mobilize.config.google.owner.email,     "test_gfile"
    @gfile                              = @Gfile.find_or_create_by_owner_and_name @gfile_owner, @gfile_name

    @script                             = @Script.find_or_create_by stdin: "echo test_file_string"

    @user                               = @Fixture::User.default
    @crontab                            = @Fixture::Crontab.default  @user
    @cron                               = @Fixture::Cron._once       @crontab,        "gfile_test"
    @run_stage                          = @Fixture::Stage.default    @cron,        1, "run"
    @write_stage                        = @Fixture::Stage.default    @cron,        2, "write"
    @read_stage                         = @Fixture::Stage.default    @cron,        3, "read"
    @script_task                        = @Fixture::Task.default     @run_stage,   1, @script
    @gfile_write_task                   = @Fixture::Task.default     @write_stage, 1, @gfile, input: "cat stage1/task1/stdout"
    @gfile_read_task                    = @Fixture::Task.default     @read_stage,  1, @gfile
  end

  def test_run
    Mobilize::Log.write                   "starting gfile test"
    _start_time                         = Time.now.utc
    Mobilize::Cli.perform                 [ "cron", "enqueue", @cron.id ]
    #monitor logs until expected messages are complete
    @test.expect _start_time
  end

  def teardown
    @gfile.delete
    @script.delete
  end

  def expect( _start_time, _end_time = _start_time + 600, _sleep_time = 10 )
    _expecteds = [
        { model_id: @cron.id,               message: "status set to started" },
        { model_id: @run_stage.id,          message: "cleared" },
        { model_id: @write_stage.id,        message: "cleared" },
        { model_id: @read_stage.id,         message: "cleared" },
        { model_id: @run_stage.id,          message: "status set to started" },
        { model_id: @script_task.id,        message: "cleared" },
        { model_id: @script_task.id,        message: "status set to started" },
        { model_id: @script_task.id,        message: "local dir refreshed" },
        { model_id: @script_task.id,        message: "stdin written to local dir" },
        { model_id: @script_task.id,        message: "status set to completed" },
        { model_id: @run_stage.id,          message: "status set to completed" },
        { model_id: @write_stage.id,        message: "status set to started" },
        { model_id: @gfile_write_task.id,   message: "cleared" },
        { model_id: @gfile_write_task.id,   message: "status set to started" },
        { model_id: @gfile_write_task.id,   message: "uploaded input to #{ @gfile_write_task.path.id }" },
        { model_id: @user.id,               message: "16 bytes" },
        { model_id: @gfile_write_task.id,   message: "status set to completed" },
        { model_id: @write_stage.id,        message: "status set to completed" },
        { model_id: @read_stage.id,         message: "status set to started" },
        { model_id: @gfile_read_task.id,    message: "cleared" },
        { model_id: @gfile_read_task.id,    message: "status set to started" },
        { model_id: @gfile_read_task.id,    message: "local dir refreshed" },
        { model_id: @gfile_read_task.id,    message: "downloaded #{ @gfile_read_task.path.id } to local dir" },
        { model_id: @user.id,               message: "16 bytes" },
        { model_id: @gfile_read_task.id,    message: "status set to completed" },
        { model_id: @read_stage.id,         message: "status set to completed" },
        { model_id: @cron.id,               message: "status set to completed" },
      ]

    _model_ids = _expecteds.map { |_expected| _expected[ :model_id ] }
    _logs      = []
    while _logs.length != _expecteds.length
      if Time.now.utc > _end_time
        Mobilize::Log.write "gfile test timed out!", "FATAL"
      elsif _logs.length > _expecteds.length
        Mobilize::Log.write "gfile test has #{ _logs.length }, expecting #{ _expecteds.length }; too many logs!", "FATAL"
      else
        Mobilize::Log.write "gfile test has #{ _logs.length }, expecting #{ _expecteds.length }; waiting #{ _sleep_time.to_s }s for completion", "INFO"
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
