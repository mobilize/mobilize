require 'test_helper'
class GitPathTest < MiniTest::Unit::TestCase
  def setup
    @gp = Mobilize::GitPath.find_or_create_by(
      TestHelper.load_fixture("git_paths/mobilize")
    )
    @u = Mobilize::User.find_or_create_by(
      TestHelper.load_fixture("users/owner")
    )
    @uc = Mobilize::UserCred.find_or_create_by(
      TestHelper.load_fixture("user_creds/owner_ssh_key")
    )
  end

  #make sure defaults are working as expected
  def test_create
    assert_equal @gp.service, "git"
    assert_equal @gp.domain, "github.com"
    assert_equal @gp.owner_name, "mobilize"
    assert_equal @gp.repo_name, "mobilize"
    assert_equal @gp.branch, "master"
    assert_equal @gp.file_path, "lib/mobilize.rb"
    assert_equal @gp.address, "github.com/mobilize/mobilize/master/lib/mobilize.rb"
    assert_equal @gp.http_url, "https://github.com/mobilize/mobilize/blob/master/lib/mobilize.rb"
    assert_equal @gp.http_url_repo, "https://github.com/mobilize/mobilize.git"
    assert_equal @gp.git_user_name, "git"
    assert_equal @gp.ssh_url_repo, "git@github.com:mobilize/mobilize.git"
  end

  def test_load
    repo_dir = @gp.load
    assert_in_delta "cd #{repo_dir} && git status".popen4.length, 1, 1000
    FileUtils.rm_r(repo_dir, force: true)
  end

  def test_read
    assert_in_delta @gp.read.length, 1, 10000
  end
end
