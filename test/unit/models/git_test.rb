require "test_helper"
class GitTest < MiniTest::Unit::TestCase
  def setup
    @git_pub = Mobilize::Git.find_or_create_by(
      owner_name: "mobilize",
      repo_name: "mobilize",
    )
    @u = Mobilize::User.find_or_create_by(
      active: true,
      name: "user",
      domain: "gmail.com",
      is_owner: true
    )
    #populate the 5 envs below if you need to test
    #private repository accessibility
    priv_git_hash = {
        owner_name: ENV['MOB_TEST_PRIVATE_GIT_OWNER'],
        repo_name: ENV['MOB_TEST_PRIVATE_GIT_REPO']
      }

    priv_user_cred_hash = {
      user_id: "user@gmail.com",
      service: "git",
      key: "ssh_private_key",
      value: (File.read(ENV['MOB_TEST_PRIVATE_SSH_KEY_PATH']) if ENV['MOB_TEST_PRIVATE_SSH_KEY_PATH'])
    }
    #make sure everything is defined as expected
    if priv_git_hash.values.compact.length==4 and
      priv_user_cred_hash.values.compact.length==4
      @git_priv = Mobilize::Git.find_or_create_by(priv_git_hash)
      @uc_priv = Mobilize::UserCred.find_or_create_by(priv_user_cred_hash)
    end
  end

  #make sure defaults are working as expected
  def test_create
    assert_equal @git_pub.domain, "github.com"
    assert_equal @git_pub.owner_name, "mobilize"
    assert_equal @git_pub.repo_name, "mobilize"
    assert_equal @git_pub.http_url, "https://github.com/mobilize/mobilize"
    assert_equal @git_pub.git_http_url, "https://github.com/mobilize/mobilize.git"
    assert_equal @git_pub.ssh_user_name, "git"
    assert_equal @git_pub.git_ssh_url, "git@github.com:mobilize/mobilize.git"
  end

  def test_load
    repo_dir_pub = @git_pub.load
    assert_in_delta "cd #{repo_dir_pub} && git status".popen4.length, 1, 1000
    FileUtils.rm_r(repo_dir_pub, force: true)
    if @git_priv
      repo_dir_priv = @git_priv.load(@u.id)
      assert_in_delta "cd #{repo_dir_priv} && git status".popen4.length, 1, 1000
      FileUtils.rm_r(repo_dir_priv, force: true)
    end
  end
end
