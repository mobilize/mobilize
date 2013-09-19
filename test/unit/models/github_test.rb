require "test_helper"
class GithubTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @git_pub = Mobilize::Github.find_or_create_by(
      owner_name: Mobilize.config.minitest.github.public.owner_name,
      repo_name: Mobilize.config.minitest.github.public.repo_name,
    )
    @ec2 = Mobilize::Ec2.find_or_create_by(
      name: Mobilize.config.minitest.ec2.worker_name
    )
    @user = Mobilize::User.find_or_create_by(
      active: true,
      google_login: Mobilize.config.minitest.google.login,
      github_login: Mobilize.config.minitest.github.login,
      ec2_id: @ec2.id
    )
    #populate the envs below if you need to test
    #private repository accessibility
    priv_git_hash = {
        domain: Mobilize.config.minitest.github.private.domain,
        owner_name: Mobilize.config.minitest.github.private.owner_name,
        repo_name: Mobilize.config.minitest.github.private.repo_name
      }
    #make sure everything is defined as expected
    if priv_git_hash.values.compact.length==3
      @git_priv = Mobilize::Github.find_or_create_by(priv_git_hash)
    end
  end

  #make sure defaults are working as expected
  def test_create
    assert_equal @git_pub.domain, "github.com"
    assert_equal @git_pub.owner_name, "mobilize"
    assert_equal @git_pub.repo_name, "mobilize"
    assert_equal @git_pub.http_url, "https://github.com/mobilize/mobilize"
    assert_equal @git_pub.git_http_url, "https://github.com/mobilize/mobilize.git"
    assert_equal @git_pub.git_ssh_url, "git@github.com:mobilize/mobilize.git"
  end

  def test_load
    repo_dir_pub = @git_pub.load
    assert_in_delta "cd #{repo_dir_pub} && git status".popen4.length, 1, 1000
    FileUtils.rm_r(repo_dir_pub, force: true)
    Mobilize::Logger.info("Deleted folder for #{@git_pub.id}")
    if @git_priv
      repo_dir_priv = @git_priv.load(@user.id)
      assert_in_delta "cd #{repo_dir_priv} && git status".popen4.length, 1, 1000
      FileUtils.rm_r(repo_dir_priv, force: true)
    end
  end
end
