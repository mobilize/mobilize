require "test_helper"
class JobTest < MiniTest::Unit::TestCase
  def setup
    Mongoid.purge!
    @ec2 = Mobilize::Ec2.find_or_create_by(
      name: Mobilize.config.minitest.ec2.worker_name
    )
    #create user from owner
    @user = Mobilize::User.find_or_create_by(
      active: true,
      google_login: Mobilize.config.minitest.google.login,
      github_login: Mobilize.config.minitest.github.login,
      ec2_id: @ec2.id
    )
    #create github instance for job
    @github = Mobilize::Github.find_or_create_by(
      owner_name: Mobilize.config.minitest.github.owner_name,
      repo_name: Mobilize.config.minitest.github.repo_name
    )
    #create job
    @job = Mobilize::Job.find_or_create_by(
      user_id: @user.id,
      command: "ls @path",
      path_ids: [@github.id],
      gsubs: {"@path"=>"mobilize"}
    )
  end

  def test_execute
    stdout = @job.execute
    assert_in_delta stdout.length, 1, 1000
  end
end
