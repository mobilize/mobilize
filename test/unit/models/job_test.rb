require "test_helper"
class JobTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @worker_name = Mobilize.config.minitest.ec2.worker_name
    @ec2 = TestHelper.new_ec2(@worker_name)
    @ec2.save!
    #create user from owner
    @user = TestHelper.user(@ec2)
    #create public github instance for job
    @github = TestHelper.github_pub
    #create job
    @job = TestHelper.job(@user,@github,@gfile)
  end

  def test_execute
    stdout = @job.execute
    assert_in_delta stdout.length, 1, 1000
  end
end
