# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

auto = ENV['AUTO_START_SWARM'] || false

# Increase numworkers if you want more than 3 nodes
numworkers = 2

# VirtualBox settings
# Increase vmmemory if you want more than 512mb memory in the vm's
vmmemory = 512
# Increase numcpu if you want more cpu's per vm
numcpu = 1

instances = []

(1..numworkers).each do |n|
  instances.push({:name => "worker#{n}", :ip => "192.168.10.#{n+2}"})
end

manager_ip = "192.168.10.2"

File.open("./hosts", 'w') { |file|
  file.write("#{manager_ip} manager manager\n")
  instances.each do |i|
    file.write("#{i[:ip]} #{i[:name]} #{i[:name]}\n")
  end
}

# Vagrant version requirement
Vagrant.require_version ">= 1.8.4"

Vagrant.configure("2") do |config|
    system("
        if [ #{ARGV[0]} = 'up' ]; then
            echo 'create disposable ssh key'
            mkdir ./ssh
            ssh-keygen -b 2048 -t rsa -f ./ssh/id_rsa -q -N ''
        elif [ #{ARGV[0]} = 'status' ]; then
            echo '(status) worker node ssh key:'
            find ./ssh
        fi
    ")
    config.vm.provider "virtualbox" do |v|
     	v.memory = vmmemory
  	v.cpus = numcpu
    end

    config.vm.define "manager" do |i|
      i.vm.box = "debian/stretch64"
      i.vm.hostname = "manager"
      i.vm.network "private_network", ip: "#{manager_ip}"
      i.vm.provision "shell", path: "./provision.sh"
      if File.file?("./hosts")
        i.vm.provision "file", source: "hosts", destination: "/tmp/hosts"
        i.vm.provision "shell", inline: "cat /tmp/hosts >> /etc/hosts", privileged: true
      end
      if auto
        i.vm.provision "file", source: "./ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
        i.vm.provision "shell", inline: "cat /tmp/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys"
        i.vm.provision "shell", inline: "docker swarm init --advertise-addr #{manager_ip}"
      end

      # set up webstack
      i.vm.provision "shell", inline: "sudo -u vagrant docker stack deploy -c /vagrant/webstack/docker-compose.yml webstack", privileged: true
      i.vm.network "forwarded_port", guest: 80, host: 8888

      # set up visualizer
      i.vm.provision "shell", inline: "sudo -u vagrant docker run -it -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock dockersamples/visualizer", privileged: true
      i.vm.network "forwarded_port", guest: 8080, host: 8080

      # set up portainer
      i.vm.provision "shell", inline: "sudo -u vagrant docker run -d -p 9000:9000 --restart always -v /var/run/docker.sock:/var/run/docker.sock -v /opt/portainer:/data portainer/portainer", privileged: true
      i.vm.network "forwarded_port", guest: 9000, host: 9000

      # set up monitoring system with grafana, prometheus, & co.
      # TODO -- 'setup-monitoring.sh' should run only after all swarm nodes have joined the cluster
      # i.vm.provision "shell", inline: "sudo -u vagrant /vagrant/setup-monitoring.sh", privileged: true
      i.vm.network "forwarded_port", guest: 3000, host: 3000
    end

  instances.each do |instance|
    config.vm.define instance[:name] do |i|
      i.vm.box = "debian/stretch64"
      i.vm.hostname = instance[:name]
      i.vm.network "private_network", ip: "#{instance[:ip]}"
      i.vm.provision "shell", path: "./provision.sh"
      if File.file?("./hosts")
        i.vm.provision "file", source: "hosts", destination: "/tmp/hosts"
        i.vm.provision "shell", inline: "cat /tmp/hosts >> /etc/hosts", privileged: true
      end
      if auto
        i.vm.provision "file", source: "./ssh/id_rsa", destination: "/home/vagrant/.ssh/id_rsa"
        i.vm.provision "shell", inline: "docker swarm join --token $(ssh -i /home/vagrant/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vagrant@manager 'docker swarm join-token worker -q') manager:2377"
      end
    end
  end

  system("
      if [ #{ARGV[0]} = 'destroy' ]; then
          echo 'delete disposable ssh key'
          rm -rf ./ssh
      fi
  ")
end
