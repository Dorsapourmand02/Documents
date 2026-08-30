

1- create a directory for installation

`cd /Desktop`
`mkdir linux_lab`


2- check the vagrant version and plugin list 

`vagrant --version`
`vagrant plugin list`


mine was : Vagrant 2.4.9 
if you didn't have the vagrant file you c an go to this website below and download it base on you system 
https://developer.hashicorp.com/vagrant/install
plugin: no plugin installed


3- `vagrant init` 
`vagrant init` initializes a Vagrant project by creating a default `Vagrantfile` in the current directory.


4- `vagrant box list` 


mine : bento/ubuntu-24.04 (virtualbox, 202510.26.0, (arm64))


if there was n o boxes 
`vagrant box add bento/ubuntu-24.04 --provider=virtualbox`


you should see 
Successfully added box 'bento/ubuntu-24.04'


5- personalize your vagrant file

`nano vagrantfile`



simple 

`Vagrant.configure("2") do |config|`

  `config.vm.define "linux-lab" do |node|`

    `node.vm.box = "bento/ubuntu-24.04"`

    `node.vm.hostname = "Dori"`

    `node.vm.network "private_network", ip: "192.168.99.10"`

    `node.vm.provider "virtualbox" do |vb|`
      `vb.name = "linux-lab"`
      `vb.memory = 4096`
      `vb.cpus = 2`
    `end`

  `end`

`end`





6- `vagrant validate`

7- `vagrant up`

8- changing the root password

`sudo -i` 
`passwd` 

Finished :)))