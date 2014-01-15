# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "adf-env"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.hostname = "adfenv.temp.medin.name"
  config.vm.synced_folder "files", "/etc/puppet/files"

  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "4096"]
	vb.gui = true
  end

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
	puppet.module_path    = "modules"
    puppet.manifest_file  = "base.pp"
  end

end
