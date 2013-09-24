require "test_helper"
class GithubTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @github_public = TestHelper.github_public
    @worker_name = Mobilize.config.minitest.ec2.worker_name
    @ec2 = TestHelper.ec2(@worker_name)
    @user = TestHelper.user(@ec2)
    @github_private = TestHelper.github_private
    @github_session = Github.login
    @job = TestHelper.job(@user)
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
    dir_public = "#{@job.worker_cache}/#{@github_public.repo_name}"
    FileUtils.mkdir_p(dir_public)
    repo_dir_public = @github_public.read(@github_session,@user,dir_public)
    assert_in_delta "cd #{repo_dir_public} && git status".popen4.length, 1, 1000
    Mobilize::Logger.info("Deleted folder for #{@github_public.id}")
    if @github_private
      dir_private = "#{@job.worker_cache}/#{@github_private.repo_name}"
      FileUtils.mkdir_p(dir_private)
      repo_dir_private = @github_private.read(@github_session,@user,dir_private)
      assert_in_delta "cd #{repo_dir_private} && git status".popen4.length, 1, 1000
    end
  end

  def teardown
    FileUtils.rm_r(@job.worker_cache, force: true)
  end
end
