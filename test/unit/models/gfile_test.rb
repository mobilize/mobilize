require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @gfile             = TestHelper.gfile
    @worker_name       = Mobilize.config.minitest.ec2.worker_name
    @ec2               = TestHelper.ec2(@worker_name)
    @user              = TestHelper.user(@ec2)
    @job               = TestHelper.job(@user)
    @gfile_session     = Mobilize::Gfile.session
    @gfile_input_path  = "#{@job.cache}/#{@gfile.name}.in"
    @gfile_read_task   = TestHelper.task(@job,@gfile,"read",@gfile_session)
    @gfile_write_task  = TestHelper.task(@job,@gfile,"write",@gfile_session, input: @gfile_input_path)
  end

  def test_find_or_create_remote
    #remove all remotes for this file
    @gfile.purge!(@gfile_read_task)
    @gfile = TestHelper.gfile
    @remote = @gfile.find_or_create_remote(@gfile_session)
    #delete DB version, start over, should find existing instance
    #with same key
    key = @gfile.key
    @gfile.delete
    @gfile = TestHelper.gfile
    @gfile.find_or_create_remote(@gfile_session)
    assert_equal @gfile.key, key
  end

  def test_write_and_read
    test_input_string = "test_file_string"
    @job.clear_cache
    File.open(@gfile_input_path,'w') {|f| f.print(test_input_string)}
    @gfile.write(@gfile_write_task)
    @gfile.read(@gfile_read_task)
    test_output_string = File.read(@gfile.cache(@gfile_read_task))
    assert_equal test_input_string, test_output_string
  end
  
  def teardown
    FileUtils.rm_r(@job.cache, force: true)
  end
end
