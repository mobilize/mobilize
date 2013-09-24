require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @gfile_name = Mobilize.config.minitest.gfile.name
    @gfile = TestHelper.gfile(@gfile_name)
    @worker_name = Mobilize.config.minitest.ec2.worker_name
    @ec2 = TestHelper.ec2(@worker_name)
    @user = TestHelper.user(@ec2)
    @job = TestHelper.job(@user)
    @gfile_session = Gfile.login
  end

  def test_find_or_create_remote
    #remove all remotes for this file
    @gfile.purge!(@gfile_session)
    @gfile = TestHelper.gfile(@gfile_name)
    @remote = @gfile.find_or_create_remote(@gfile_session)
    #delete DB version, start over, should find existing instance
    #with same key
    key = @gfile.key
    @gfile.delete
    @gfile = TestHelper.gfile(@gfile_name)
    @gfile.find_or_create_remote(@gfile_session)
    assert_equal @gfile.key, key
  end

  def test_write_and_read
    test_dir = "#{@job.worker_cache}/gdrive"
    test_input_string = "test_file_string"
    test_input_path = "#{@test_dir}/#{@gfile_name}.in"
    FileUtils.mkdir_p(test_dir)
    File.open(test_input_path,'w') {|f| f.print(test_file_string)}
    @gfile.write(@gfile_session,@user,test_input_path)
    @gfile.read(@gfile_session,@user,test_dir)
    test_output_path = "#{test_dir}/#{@gfile.name}"
    test_output_string = File.read(test_output_path)
    assert_equal test_input_string, test_output_string
  end
  
  def teardown
    FileUtils.rm_r(@job.worker_cache, force: true)
  end
end
