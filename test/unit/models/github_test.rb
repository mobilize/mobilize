require "test_helper"
class GithubTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @github_pub = TestHelper.github_pub
    @worker_name = Mobilize.config.minitest.ec2.worker_name
    @ec2 = TestHelper.new_ec2(@worker_name)
    @ec2.save!
    @user = TestHelper.user(@ec2)
    @github_priv = TestHelper.github_priv
  end

  #make sure defaults are working as expected
  def test_create
    assert_equal @github_pub.domain, "github.com"
    assert_equal @github_pub.owner_name, "mobilize"
    assert_equal @github_pub.repo_name, "mobilize"
    assert_equal @github_pub.http_url, "https://github.com/mobilize/mobilize"
    assert_equal @github_pub.git_http_url, "https://github.com/mobilize/mobilize.git"
    assert_equal @github_pub.git_ssh_url, "git@github.com:mobilize/mobilize.git"
  end

  def test_load
    repo_dir_pub = @github_pub.load
    assert_in_delta "cd #{repo_dir_pub} && git status".popen4.length, 1, 1000
    FileUtils.rm_r(repo_dir_pub, force: true)
    Mobilize::Logger.info("Deleted folder for #{@github_pub.id}")
    if @github_priv
      repo_dir_priv = @github_priv.load(@user.id)
      assert_in_delta "cd #{repo_dir_priv} && git status".popen4.length, 1, 1000
      FileUtils.rm_r(repo_dir_priv, force: true)
    end
  end
end
