## Links
- https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/
- https://github.com/netbox-community/netbox-docker

## Command Dump

kompose hacking

```
mkdir scratch
cd scratch

curl -L https://github.com/kubernetes/kompose/releases/download/v1.28.0/kompose-linux-amd64 -o kompose
chmod +x kompose

git clone git@github.com:netbox-community/netbox-docker.git

./kompose --provider openshift --verbose convert -f netbox-docker/docker-compose.yml
```

OpenShift hacking

```
# new project
oc new-project netbox-test

# setup netbox container
oc new-app \
  quay.io/netboxcommunity/netbox:latest \
  --name netbox \
  -l app=netbox

# setup env vars for netbox
cat netbox.env | oc set env -e - deploy/netbox
oc set env \
  deployment/netbox \
  -e DB_WAIT_DEBUG=1 \
  -e REDIS_PORT=6379 \
  -e REDIS_CACHE_PORT=6379

oc expose deployment \
netbox \
  --port 8080 \
  --overrides='{"spec":{"tls":{"termination":"edge"}}}' \
  -l app=netbox

oc expose service \
netbox \
  --overrides='{"spec":{"tls":{"termination":"edge"}}}' \
  -l app=netbox

# setup postgres
oc new-app \
  --image-stream=postgresql:12-el8 \
  --name postgresql \
  -l app=netbox

cat postgres.env | oc set env -e - deploy/postgresql

# setup redis
oc new-app \
  --image-stream=redis:latest \
  --name redis \
  -l app=netbox

cat redis.env | oc set env -e - deploy/redis

# setup redis-cache
oc new-app \
  --image-stream=redis:latest \
  --name redis-cache \
  -l app=netbox

cat redis-cache.env | oc set env -e - deploy/redis-cache

```
