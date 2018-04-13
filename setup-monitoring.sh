#!/usr/bin/env bash

#
# set up grafana and prometheus
#
mkdir /home/vagrant/swarmprom
git clone https://github.com/siso/swarmprom.git /home/vagrant/swarmprom

cd /home/vagrant/swarmprom

ADMIN_USER=admin \
ADMIN_PASSWORD=admin \
SLACK_URL=https://hooks.slack.com/services/TOKEN \
SLACK_CHANNEL=devops-alerts \
SLACK_USER=alertmanager \
sudo -u vagrant docker stack deploy -c docker-compose.yml mon

echo "View Grafana Dashboard at http://$(docker node inspect self --format '{{ .Status.Addr  }}'):3000"
