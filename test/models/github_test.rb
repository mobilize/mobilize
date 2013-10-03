require "test_helper"
class GithubTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @github_public        = TestHelper.github_public
    @worker_name          = Mobilize.config.minitest.ec2.worker_name
    @ec2                  = TestHelper.ec2(@worker_name)
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
    if @github_private
      @github_private.read(@github_private_task)
      assert_in_delta "cd #{@github_private_task.worker.dir} && git status".popen4.length, 1, 1000
    end
  end
end
