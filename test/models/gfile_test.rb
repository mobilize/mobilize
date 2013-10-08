require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @gfile                     = Mobilize::Fixture::Gfile.default
    @worker_name               = Mobilize.config.minitest.ec2.worker_name
    @ec2                       = Mobilize::Fixture::Ec2.default(@worker_name)
    @ec2.find_or_create_instance Mobilize::Ec2.session
    @ssh                       = Mobilize::Fixture::Ssh.default(@ec2)
    @user                      = Mobilize::Fixture::User.default(@ec2)
    @job                       = Mobilize::Fixture::Job.default(@user)
    @gfile_session             = Mobilize::Gfile.session
    @gfile_read_task           = Mobilize::Fixture::Task.default(@job,@gfile,"read",@gfile_session)
    @gfile_write_task          = Mobilize::Fixture::Task.default(@job,@gfile,"write",@gfile_session,
                                                                 input: @gfile_read_task.worker.dir)
  end

  def test_find_or_create_remote
    #remove all remotes for this file
    @gfile.purge!                @gfile_read_task
    @gfile                     = Mobilize::Fixture::Gfile.default
    @gfile.find_or_create_remote @gfile_session
    #delete DB version, start over, should find existing instance
    #with same key
    key                        = @gfile.key
    @gfile.delete
    @gfile                     = Mobilize::Fixture::Gfile.default
    @gfile.find_or_create_remote @gfile_session
    assert_equal                 @gfile.key, key
  end

  def test_write_and_read
    test_input_string                = "test_file_string"
    @write_worker                    = @gfile_write_task.worker
    @write_worker.refresh
    @write_worker.purge

    @file                            = File.open(@write_worker.dir,'w')
    @file.print                        test_input_string
    @file.close

    @gfile.write                       @gfile_write_task
    @gfile.read                        @gfile_read_task
    test_output_string               = File.read(@gfile_read_task.worker.dir)

    assert_equal                     test_input_string, test_output_string

    test_cache_output_string         = @ssh.sh("cat #{@gfile_read_task.cache.dir}")[:stdout]

    assert_equal                     test_input_string, test_cache_output_string
  end
end
