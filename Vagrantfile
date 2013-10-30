# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # These steps are manual now
  #config.vm.provision :shell, :path => "puppet/install_puppet_dependancies.sh"
  #config.vm.provision :puppet do |puppet|
  #    puppet.manifests_path = "puppet/manifests"
  #    puppet.manifest_file  = "site.pp"
  #    puppet.facter = {
  #      "motd" => "Built by Vagrant using librarian-puppet.",
  #      "fqdn" => "ckan.home",
  #      "pgpasswd" => "pass",
  #    }
  #end

  # Allow local machines to view the VM
  config.vm.network "private_network", ip: "192.168.11.11"

  config.vm.provider :virtualbox do |vb|
    config.vm.box = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"
    # This allows symlinks to be created within the /vagrant root directory, 
    # which is something librarian-puppet needs to be able to do. This might
    # be enabled by default depending on what version of VirtualBox is used.
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
    # boot headless (or make true to get a display)
    vb.gui = false
    # Virtualbox Custom CPU count:
    vb.customize ["modifyvm", :id, "--name", "dgutg_vm"]
    vb.customize ["modifyvm", :id, "--memory", "8192"]
    vb.customize ["modifyvm", :id, "--cpus", "8"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.provider :vmware_fusion do |vmware, override|
    override.vm.box = "precise64_vmware"
    override.vm.box_url = "http://files.vagrantup.com/precise64_vmware.box"
    # 4GB RAM and 4 (hyperthreaded virtual) CPU cores
    vmware.vmx["memsize"] = "8192"
    vmware.vmx["numvcpus"] = "8"
    vmware.vmx["displayName"] = "dgutg_vm"
    vmware.vmx["annotation"] = "Virtualised data.gov.uk 2 environment"
  end 
end
