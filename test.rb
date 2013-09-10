lines=[]
(01..28).to_a.map{|d| "%02d" % d }.each do |n|
  lines << "#{ENV["K#{n}"]}"
end
File.open("test.ssh","w") {|f| f.print lines.join("\n")}
`chmod 0400 test.ssh`
puts `ssh -i test.ssh -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' "ubuntu@$MOB_AWS_MASTER_DNS" hostname`
