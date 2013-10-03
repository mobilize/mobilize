require "test_helper"
class GithubTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @github_public        = TestHelper.github_public
    @worker_name          = Mobilize.config.minitest.ec2.worker_name
    @ec2                  = TestHelper.ec2(@worker_name)
    @ec2.find_or_create_instance(Mobilize::Ec2.session)
    @ssh                  = TestHelper.ssh(@ec2)
    @user                 = TestHelper.user(@ec2)
    @github_private       = TestHelper.github_private
    @job                  = TestHelper.job(@user)
    #assign same session to both githubs
    @github_session       = Mobilize::Github.session
    @github_public_task   = TestHelper.task(@job,@github_public,"read",@github_session)
    @github_private_task  = TestHelper.task(@job,@github_private,"read",@github_session)
  end

  def test_read
    @github_public.read(@github_public_task)
    assert_in_delta "cd #{@github_public_task.worker.dir} && git status".popen4.length, 1, 1000
    assert_in_delta @ssh.sh("cd #{@github_public_task.cache.dir} && sudo apt-get install -y git; git status")[:stdout].length, 1, 2000
    if @github_private
      @github_private.read(@github_private_task)
      assert_in_delta "cd #{@github_private_task.worker.dir} && git status".popen4.length, 1, 1000
      assert_in_delta @ssh.sh("cd #{@github_private_task.cache.dir} && sudo apt-get install -y git; git status")[:stdout].length, 1, 2000
    end
  end
end
