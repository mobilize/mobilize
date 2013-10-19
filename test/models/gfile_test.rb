require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    Mobilize::Job.purge!
    @Fixture, @Gfile, @Script           = Mobilize::Fixture, Mobilize::Gfile, Mobilize::Script
    @Config                             = Mobilize.config.fixture
    @gfile_session, @script_session     = @Gfile.session, @Script.session

    @gfile_owner, @gfile_name           = @Config.gfile.ie{|gfile| [gfile.owner, gfile.name] }
    @gfile                              = @Gfile.find_or_create_by_owner_and_name(
                                          @gfile_owner, @gfile_name, @gfile_session)

    @box                                = Mobilize::Box.find_or_create_by_name @Config.box.worker_name

    @script                             = @Script.find_or_create_by stdin: "print test_file_string"

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
