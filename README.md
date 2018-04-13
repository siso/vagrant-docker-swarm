# Docker Swarm Vagrant

Vagrantfile to stand up Docker Engine Swarm Mode cluster.
It requires Docker 1.12+, and run Debian.

## Quickstart

Provision Docker Swarm cluster:

```
# stand up docker swarm cluster
AUTO_START_SWARM=true vagrant up
```

`vagrant up` would provision machines without creating Docker Swarm cluster.

SSH on manager and check Docker Swarm cluster:

```
# vagrant ssh $VAGRANT_NODE_NAME, e.g.:
vagrant ssh manager

# a few checks

# docker engine info
docker version
docker info

# check swarm
docker node list

# docker swarm logs
sudo tail -f /var/log/daemon.log

# set up monitoring
./setup-monitoring.sh
```

Set up monitoring with Grafana, Prometheus & Co.:

```
/vagrant/setup-monitoring.sh
```

Links:

- grafana: http://localhost:3000/
- portainer.io: http://localhost:9000/
- visualizer: http://localhost:8080/
- webstack (nginx): http://localhost:8888/

Tear cluster down and free resources on host:

```
vagrant destroy -f
```

## Demo

### UI

#### Visualizer

Run [`Visualizer`](https://github.com/dockersamples/docker-swarm-visualizer):

```
docker run -it -d -p 5000:8080 -v /var/run/docker.sock:/var/run/docker.sock dockersamples/visualizer
```

Connect on host: http://localhost:5000

#### portainer

[`portainer`](https://github.com/portainer/portainer) Simple management UI for Docker http://portainer.io

```
docker run -d -p 9000:9000 --restart always -v /var/run/docker.sock:/var/run/docker.sock -v /opt/portainer:/data portainer/portainer
```

Connect on host: http://localhost:9000

### Service

Run a single service, e.g.:

```
docker service create --name web -p 80:80 nginx
```

Connect to `nginx`:

- on `guest`: `curl 192.168.10.2:8080`
- on `host`: `curl localhost:8080`, http://localhost:8080

Manage service:

```
# display service info
docker service inspect web

# scale service
docker service scale web=3

# tear service down
docker service rm web
```

### Stack

Create `docker-compose.yml`:

```yml
version: "3"
services:
  web:
    image: nginx
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
      restart_policy:
        condition: on-failure
    ports:
      - "8888:80"
    networks:
      - webnet
networks:
  webnet:
```

Deploy stack:

```
docker stack deploy -c docker-compose.yml webstack
```

Connect to `nginx`: http://localhost:8888

Manage stack:

```
docker stack ls
docker stack ps webstack

docker stack ps --format "{{.Name}}: {{.Image}} {{.Node}} {{.DesiredState}} {{.CurrentState}}" webstack
```

See [`--format`](https://docs.docker.com/engine/reference/commandline/stack_ps/#formatting) documentation.

There are two ways to scale a service, either by persisting changes to `docker-compose.yml` file:

- edit `docker-compose.yml`
- run `docker stack deploy -c docker-compose.yml webstack`

or at runtime:

- `docker service scale webstack_web=6`

Load-test, e.g.:

```
ab -n 10000 -c 100 -s 2 -k http://192.168.10.2:80/
```

⚠️ `ab` looks broken on OS X:

```
ab -n 100 -c 10 http://localhost:8080/
This is ApacheBench, Version 2.3 <$Revision: 1807734 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking localhost (be patient)...apr_socket_recv: Connection refused (61)
```

## Examples

```
docker node list
docker ps
docker service create --name web -p 80:80 nginx
curl 192.168.10.2
docker service rm web
docker service scale web=6
watch -d -n1 docker ps
```

Suspend a node `vagrant suspend worker1`, simulate outage on one node.
Docker Swarm auto-heal by adding missing containers on remaining nodes to keep `web` service up and running:

```
docker node list
watch -d -n1 docker ps
curl 192.168.10.2
```

## FAQ

Docker Swarm IP:

```
$ docker node inspect self --format '{{ .Status.Addr  }}'
```

## License

GPLv3

## Author

Simone Soldateschi <simone.soldateschi@gmail.com>

## Links

- [Raft Consensus Algortihm](http://thesecretlivesofdata.com/raft/)

## Credits

- [Docker Swarm Vagrant](https://github.com/tdi/vagrant-docker-swarm)
  - > Inspired by `denverdino/docker-swarm-mode-vagrant` and `lowescott/learning-tools` repos.
