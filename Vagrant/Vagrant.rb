Vagrant.configure("2") do |config|

  config.vm.define "linux-lab" do |node|

    node.vm.box = "bento/ubuntu-24.04"

    node.vm.hostname = "Dori"

    node.vm.network "private_network", ip: "192.168.99.10"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "linux-lab"
      vb.memory = 4096
      vb.cpus = 2
    end

  end

end