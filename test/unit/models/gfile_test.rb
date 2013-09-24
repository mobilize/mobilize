require "test_helper"
class GfileTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @gfile = TestHelper.gfile
    @worker_name = Mobilize.config.minitest.ec2.worker_name
    @ec2 = TestHelper.ec2(@worker_name)
    @user = TestHelper.user(@ec2)
    @job = TestHelper.job(@user)
    @gfile_session = Gfile.login
  end

  #make sure defaults are working as expected
  def test_create
    assert_equal @gfile.domain, "github.com"
    assert_equal @github_public.owner_name, "mobilize"
    assert_equal @github_public.repo_name, "mobilize"
    assert_equal @github_public.http_url, "https://github.com/mobilize/mobilize"
    assert_equal @github_public.git_http_url, "https://github.com/mobilize/mobilize.git"
    assert_equal @github_public.git_ssh_url, "git@github.com:mobilize/mobilize.git"
  end

  def test_load
    dir_public = "#{@job.worker_cache}/#{@github_public.repo_name}"
    @github_public.read(@session,dir_public)
    assert_in_delta "cd #{dir_public} && git status".popen4.length, 1, 1000
    FileUtils.rm_r(dir_public, force: true)
    Mobilize::Logger.info("Deleted folder for #{@github_public.id}")
    if @github_private
      dir_private = "#{@job.worker_cache}/#{@github_private.repo_name}"
      assert_in_delta "cd #{dir_private} && git status".popen4.length, 1, 1000
      FileUtils.rm_r(dir_private, force: true)
    end
  end
end
