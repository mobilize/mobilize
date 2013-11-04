require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @Fixture, @Gfile, @Script           = Mobilize::Fixture, Mobilize::Gfile, Mobilize::Script
    @Config                             = Mobilize.config.fixture
    @gfile_session, @script_session     = @Gfile.session, @Script.session

    @gfile_owner, @gfile_name           = Mobilize.config.google.owner.email, "test_gfile"
    @gfile                              = @Gfile.find_or_create_by_owner_and_name(
                                          @gfile_owner, @gfile_name, @gfile_session )

    @box                                = Mobilize::Box.find_or_create_by_name "mobilize-gfile-test"

    @script                             = @Script.find_or_create_by stdin: "echo test_file_string"

    @user                               = @Fixture::User.default
    @job                                = @Fixture::Job.default      @user, @box
    @stage01                            = @Fixture::Stage.default    @job, 1, "run"
    @stage02                            = @Fixture::Stage.default    @job, 2, "write"
    @stage03                            = @Fixture::Stage.default    @job, 3, "read"
    @script_task                        = @Fixture::Task.default     @stage01, @script, @script_session
    @gfile_write_task                   = @Fixture::Task.default     @stage02, @gfile, @gfile_session
    @gfile_read_task                    = @Fixture::Task.default     @stage03, @gfile, @gfile_session

    @gfile_write_task.update_attributes   input:  "#{@script_task.dir}/stdout"
  end

  def test_find_or_create_remote
    #remove all remotes for this file
    @gfile.terminate                  @gfile_session
    @gfile                          = @Gfile.find_or_create_by_owner_and_name(
                                      @gfile_owner, @gfile_name, @gfile_session )

    #delete DB version, start over, should find existing instance
    #with same key
    _remote_id                      = @gfile.remote_id
    @gfile.delete
    @gfile                          = @Gfile.find_or_create_by_owner_and_name(
                                      @gfile_owner, @gfile_name, @gfile_session )

    assert_equal                      @gfile.remote_id, _remote_id
  end

  def test_write_and_read
    @script.run                       @script_task
    _test_input_string              = File.read "#{ @script_task.dir }/stdout"
    @gfile.write                      @gfile_write_task
    @gfile.read                       @gfile_read_task
    _test_output_string             = File.read "#{ @gfile_read_task.dir }/stdout"

    assert_equal                      _test_input_string, _test_output_string
  end

  def teardown
    @box.terminate
  end
end
