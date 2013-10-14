module Mobilize
  module Fixture
    module Ssh
      def Ssh.default(ec2)
        ec2.create_ssh(
          ec2_id: ec2.id,
          user_name: Mobilize.config.fixture.ssh.user_name,
          private_key_path: Mobilize.config.fixture.ssh.private_key_path
        )
      end
    end
  end
end
