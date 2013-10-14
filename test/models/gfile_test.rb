require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @Fixture                            = Mobilize::Fixture
    @gfile                              = @Fixture::Gfile.default
    @worker_name                        = Mobilize.config.fixture.ec2.worker_name
    @ec2                                = @Fixture::Ec2.default      @worker_name
    @ec2.find_or_create_instance          Mobilize::Ec2.session
    @ssh                                = @Fixture::Ssh.default      @ec2
    @user                               = @Fixture::User.default     @ec2
    @job                                = @Fixture::Job.default      @user
    @gfile_session                      = Mobilize::Gfile.session
    @stage01                            = @Fixture::Stage.default    @job, 1, "write"
    @stage02                            = @Fixture::Stage.default    @job, 2, "read"
    @gfile_write_task                   = @Fixture::Task.default     @stage01, @gfile, @gfile_session
    @gfile_read_task                    = @Fixture::Task.default     @stage02, @gfile, @gfile_session
    @write_worker                       = @gfile_write_task.worker
    @gfile_write_task.update_attributes   input:  @write_worker.dir
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
    @test_input_string               = "test_file_string"
    @write_worker.refresh
    @write_worker.purge

    @file                            = File.open @write_worker.dir,'w'
    @file.print                        @test_input_string
    @file.close

    @gfile.write                       @gfile_write_task
    @gfile.read                        @gfile_read_task
    @test_output_string              = File.read @gfile_read_task.worker.dir

    assert_equal                       @test_input_string, @test_output_string

    @test_cache_output_string        = @ssh.sh("cat #{@gfile_read_task.cache.dir}")[:stdout]

    assert_equal                       @test_input_string, @test_cache_output_string
  end
end
