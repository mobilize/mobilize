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

  #make sure defaults are working as expected
  def test_create
    assert_equal @github_public.domain, "github.com"
    assert_equal @github_public.owner_name, "mobilize"
    assert_equal @github_public.repo_name, "mobilize"
    assert_equal @github_public.http_url, "https://github.com/mobilize/mobilize"
    assert_equal @github_public.git_http_url, "https://github.com/mobilize/mobilize.git"
    assert_equal @github_public.git_ssh_url, "git@github.com:mobilize/mobilize.git"
  end

  def test_read
    @github_public.clear_cache(@github_public_task)
    @github_public.read(@github_public_task)
    assert_in_delta "cd #{@github_public.cache(@github_public_task)} && git status".popen4.length, 1, 1000
    if @github_private
      @github_private.clear_cache(@github_private_task)
      @github_private.read(@github_private_task)
      assert_in_delta "cd #{@github_private.cache(@github_private_task)} && git status".popen4.length, 1, 1000
    end
  end

  def teardown
    FileUtils.rm_r(@job.cache, force: true)
  end
end
