require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    @Fixture, @Gfile, @Script           = Mobilize::Fixture, Mobilize::Gfile, Mobilize::Script
    @Config                             = Mobilize.config.fixture

    @gfile_owner, @gfile_name           = Mobilize.config.google.owner.email, "test_gfile"
    @gfile                              = @Gfile.find_or_create_by_owner_and_name @gfile_owner, @gfile_name

    @box                                = Mobilize::Box.find_or_create_by_name "mobilize-gfile-test"

    @script                             = @Script.find_or_create_by stdin: "echo test_file_string"

    @user                               = @Fixture::User.default
    @crontab                            = @Fixture::Crontab.default  @user
    @cron                               = @Fixture::Cron._once       @crontab, "gfile_test"
    @run_stage                          = @Fixture::Stage.default    @cron,     1, "run"
    @write_stage                        = @Fixture::Stage.default    @cron,     2, "write"
    @read_stage                         = @Fixture::Stage.default    @cron,     3, "read"
    @script_task                        = @Fixture::Task.default     @run_stage,   1, @script
    @gfile_write_task                   = @Fixture::Task.default     @write_stage,  1, @gfile, input: "cat stage1/task1/stdout"
    @gfile_read_task                    = @Fixture::Task.default     @read_stage, 1, @gfile
  end

  def test_write_and_read
    Cli.perform                       [ "cron","enqueue", @cron.id ]
    #monitor logs until expected messages are complete
  end

  def teardown
    @box.terminate
    @job.purge!
    @gfile.delete
    @script.delete
  end
end
