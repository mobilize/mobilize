require "test_helper"
class TaskTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @worker_name = Mobilize.config.minitest.ec2.worker_name
    @ec2 = TestHelper.ec2(@worker_name)
    @ec2.save!
    #create user from owner
    @user = TestHelper.user(@ec2)
    #create public github instance for job
    @github = TestHelper.github_pub
    #create job
    @task = TestHelper.task(@user,@github,@gfile)
  end

end
