require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @Fixture                            = Mobilize::Fixture
    @gfile                              = @Fixture::Gfile.default
    @worker_name                        = Mobilize.config.fixture.box.worker_name
    @box                                = Mobilize::Box.find_or_create_remote_by_name @worker_name
    @script                             = @Fixture::Script.default   "print test_file_string"
    @script_session                     = Mobilize::Script.session
    @user                               = @Fixture::User.default
    @job                                = @Fixture::Job.default      @user, @box
    @gfile_session                      = Mobilize::Gfile.session
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
    @gfile.purge!                     @gfile_read_task
    @gfile                          = @Fixture::Gfile.default
    @gfile.find_or_create_remote      @gfile_session
    #delete DB version, start over, should find existing instance
    #with same key
    key                             = @gfile.key
    @gfile.delete
    @gfile                          = @Fixture::Gfile.default
    @gfile.find_or_create_remote      @gfile_session
    assert_equal                      @gfile.key, key
  end

  def test_write_and_read
    @script.run                       @script_task
    @test_input_string              = File.read "#{@script_task.dir}/stdout"
    @gfile.write                      @gfile_write_task
    @gfile.read                       @gfile_read_task
    @test_output_string             = File.read "#{@gfile_read_task.dir}/stdout"

    assert_equal                      @test_input_string, @test_output_string
  end
end
