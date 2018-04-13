# Demo

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Goals](#goals)
- [Record demo session](#record-demo-session)
- [Stand up development Swarm cluster](#stand-up-development-swarm-cluster)
- [Start services](#start-services)
- [Set up monitoring](#set-up-monitoring)
- [Scale and Load-test](#scale-and-load-test)
- [Summarise `ab` results](#summarise-ab-results)
- [Grafana](#grafana)

<!-- /TOC -->

## Goals

- Stand up development Swarm cluster
- Start services
- Set up monitoring
- Scale and Load-test

## Record demo session

Record demo session:

```
script --timing=script-demo.tm script-demo.out
```

```
scriptreplay --timing script-demo.tm --typescript script-demo.out
```

## Stand up development Swarm cluster

Provision Docker Swarm cluster:

```
# stand up docker swarm cluster
AUTO_START_SWARM=true vagrant up
```

SSH into Swarm manager node:

```
vagrant ssh manager
```

Run a few checks:

```
# docker engine info
docker version
docker info

# check swarm
docker node list

# docker swarm logs
sudo tail -f /var/log/daemon.log
```

## Start services

Set up `webstack`:

```
docker stack deploy -c /vagrant/webstack/docker-compose.yml webstack
```

Connect: http://localhost:8888

Set up visualizer:

```
docker run -it -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock dockersamples/visualizer
```

Connect: http://localhost:8080

Set up portainer:

```
docker run -d -p 9000:9000 --restart always -v /var/run/docker.sock:/var/run/docker.sock -v /opt/portainer:/data portainer/portainer
```

Connect: http://localhost:9000

## Set up monitoring

Deploy [`stefanprodan/swarmprom`](https://github.com/stefanprodan/swarmprom):

```
git clone https://github.com/siso/swarmprom.git

cd /home/vagrant/swarmprom

ADMIN_USER=admin \
ADMIN_PASSWORD=admin \
SLACK_URL=https://hooks.slack.com/services/TOKEN \
SLACK_CHANNEL=devops-alerts \
SLACK_USER=alertmanager \
sudo -u vagrant docker stack deploy -c docker-compose.yml mon

echo "View Grafana Dashboard at http://$(docker node inspect self --format '{{ .Status.Addr  }}'):3000"
```

## Scale and Load-test

```
docker service scale webstack_web=3

# load-test with ab
ab -n 10000 -c 100 -s 2 http://$(docker node inspect self --format '{{ .Status.Addr  }}'):80/

# Enable the HTTP KeepAlive feature
ab -n 10000 -c 100 -s 2 -k http://$(docker node inspect self --format '{{ .Status.Addr  }}'):80/

docker service scale webstack_web=6
ab -n 10000 -c 100 -s 2 -k http://$(docker node inspect self --format '{{ .Status.Addr  }}'):80/

docker service scale webstack_web=12
ab -n 10000 -c 100 -s 2 -k http://$(docker node inspect self --format '{{ .Status.Addr  }}'):80/

docker service scale webstack_web=24
ab -n 10000 -c 100 -s 2 -k http://$(docker node inspect self --format '{{ .Status.Addr  }}'):80/

docker service scale webstack_web=3
```

## Summarise `ab` results

Slide with `ab` results based on number of containers in `webstack`.

## Grafana

Slide showing impact of load-tests on Docker Swarm cluster.
