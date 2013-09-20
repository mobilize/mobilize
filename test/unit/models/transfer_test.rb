require "test_helper"
class TransferTest < MiniTest::Unit::TestCase
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
    #create public github instance for transfer
    @github = Mobilize::Github.find_or_create_by(
      owner_name: Mobilize.config.minitest.github.public.owner_name,
      repo_name: Mobilize.config.minitest.github.public.repo_name
    )
    #create transfer
    @transfer = Mobilize::Transfer.find_or_create_by(
      user_id: @user.id,
      command: "ls @path",
      path_ids: [@github.id],
      gsubs: {"@path"=>"mobilize"}
    )
  end

  def test_execute
    stdout = @transfer.execute
    assert_in_delta stdout.length, 1, 1000
  end
end
