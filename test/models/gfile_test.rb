require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    @Fixture, @Gfile, @Script           = Mobilize::Fixture, Mobilize::Gfile, Mobilize::Script
    @Config                             = Mobilize.config.fixture
    @gfile_session, @script_session     = @Gfile.session, @Script.session

    @gfile_owner, @gfile_name           = Mobilize.config.google.owner.email, "test_gfile"
    @gfile                              = @Gfile.find_or_create_by_owner_and_name @gfile_owner, @gfile_name

    @box                                = Mobilize::Box.find_or_create_by_name "mobilize-gfile-test"

    @script                             = @Script.find_or_create_by stdin: "echo test_file_string"

    @user                               = @Fixture::User.default
    @crontab                            = @Fixture::Crontab.default  @user
    @cron                               = @Fixture::Cron.default     @crontab, "gfile_test"
    @run_stage                          = @Fixture::Stage.default    @cron,     1, "run"
    @write_stage                        = @Fixture::Stage.default    @cron,     2, "write"
    @read_stage                         = @Fixture::Stage.default    @cron,     3, "read"
    @script_task                        = @Fixture::Task.default     @run_stage,   @script, @script_session
    @gfile_write_task                   = @Fixture::Task.default     @read_stage,  @gfile,  @gfile_session
    @gfile_read_task                    = @Fixture::Task.default     @write_stage, @gfile,  @gfile_session

    @gfile_write_task.update_attributes   input:  "#{ @script_task.dir }/stdout"
  end

  def test_find_or_create_remote
    #remove all remotes for this file
    @gfile.terminate
    @gfile                          = @Gfile.find_or_create_by_owner_and_name @gfile_owner, @gfile_name

    #delete DB version, start over, should find existing instance
    #with same key
    _remote_id                      = @gfile.remote_id
    @gfile.delete
    @gfile                          = @Gfile.find_or_create_by_owner_and_name @gfile_owner, @gfile_name

    assert_equal                      @gfile.remote_id, _remote_id
  end

  def test_write_and_read
    Cli.perform                       [ "master","enqueue", @cron.id ]
    _test_input_string              = File.read "#{ @script_task.dir }/stdout"
    @gfile.write                      @gfile_write_task
    @gfile.read                       @gfile_read_task
    _test_output_string             = File.read "#{ @gfile_read_task.dir }/stdout"

    assert_equal                      _test_input_string, _test_output_string
  end

  def teardown
    @box.terminate
    @job.purge!
    @gfile.delete
    @script.delete
  end
end
