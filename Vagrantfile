# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu1910"
  config.vm.synced_folder "./", "/vagrant", disabled: false
  config.vm.provider "vmware_desktop" do |v|
    v.linked_clone = false
  end
  config.vm.provision "build-env", type: "shell", :path => "build-env.sh", privileged: false
  config.vm.provision "build", type: "shell", :path => "build.sh", privileged: false
end

