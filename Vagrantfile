# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "almalinux/8"
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.provider "libvirt" do |hv|
    hv.cpus = "2"
    hv.memory = "2048"
  end
  config.vm.define "rundeck" do |rundeck|
    rundeck.vm.network "forwarded_port", guest: 443, host: 443
    rundeck.vm.network :private_network, ip: "192.168.3.10"
    rundeck.vm.hostname = "rundeck"
    rundeck.vm.provision "ansible" do |a|
      a.verbose = "v"
      a.playbook = "deploy_rundeck.yml"
      a.host_vars = {
        "rundeck" => {
          "server_address" => "localhost",
          "rundeck_xmx" => "1024m",
          "rundeck_xms" => "256m",
          "rundeck_maxmetaspacesize" => "256m"
      }
    }
    end
  end
end
