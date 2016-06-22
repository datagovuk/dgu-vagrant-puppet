# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # These steps are manual now
  config.vm.provision :shell, :path => "puppet/install_puppet_dependancies.sh"
  config.vm.provision :puppet do |puppet|
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "site.pp"
      puppet.facter = {
        "motd" => "Built by Vagrant using librarian-puppet.",
        # "fqdn" => "ckan.home",
        "pgpasswd" => "pass",
      }
  end

  # Allow local machines to view the VM
  config.vm.network "private_network", ip: "192.168.11.11"

  # Put CKAN source in /src, owned by 'co' user.
  # This is needed so 'co' can write to it and therefore install it into our
  # virtualenv.  However to get the owner of the 'src' dir to be 'co', we need
  # to set it using a uid, because the first time you do 'vagrant up' the
  # folder is created before the 'co' user exists.
  config.vm.synced_folder "src/", "/src", create: true, :mount_options => ["uid=510"]

  # Once the 'co' user has been created on the first 'vagrant up' you can uncomment this
  # line to ssh in as co by default. Just don't commit that change!
  #config.ssh.username = "co"

  config.vm.provider :virtualbox do |vb|
    config.vm.box = "trusty64"
    # Box from http://www.vagrantbox.es/
    config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box"
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
    override.vm.box = "trusty64_vmware"
    override.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vmwarefusion.box"
    # 8GB RAM and 8 (hyperthreaded virtual) CPU cores
    vmware.vmx["memsize"] = "8192"
    vmware.vmx["numvcpus"] = "8"
    vmware.vmx["displayName"] = "dgutg_vm"
    vmware.vmx["annotation"] = "Virtualised data.gov.uk To Go environment"
  end 
end
