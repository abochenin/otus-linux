Vagrant.configure(2) do |config|

  config.vm.define "ipa" do |subconfig|
    subconfig.vm.box = "centos/7"
    subconfig.vm.hostname="ipa.otus.lan"
    subconfig.vm.network :private_network, ip: "192.168.50.10"
    subconfig.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = "1"
    end
  end

  config.vm.define "client" do |subconfig|
    subconfig.vm.box = "centos/7"
    subconfig.vm.hostname="client.otus.lan"
    subconfig.vm.network :private_network, ip: "192.168.50.11"
    subconfig.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
    end
#    subconfig.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"
#    subconfig.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"
  end


  config.ssh.insert_key = false 
  config.ssh.private_key_path = ['~/.vagrant.d/insecure_private_key', '~/.ssh/id_rsa']
  config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"
  config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/id_rsa.pub"
  config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "provision.yml"
  end

end
