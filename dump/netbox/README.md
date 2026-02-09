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
APP_NAME=netbox
APP_LABEL="app.kubernetes.io/part-of=${APP_NAME}"
CONTAINER_IMAGE=quay.io/netboxcommunity/netbox:latest
NAMESPACE=netbox

# new project
oc new-project ${NAMESPACE}

# setup netbox container
oc new-app \
  --name ${APP_NAME} \
  -l ${APP_LABEL} \
  -n ${NAMESPACE} \
  ${CONTAINER_IMAGE}

# setup env vars for netbox
cat netbox.env | oc set env -e - deployment/${APP_NAME}

oc set env \
  deployment/${APP_NAME} \
  -n ${NAMESPACE} \
  -l ${APP_LABEL} \
  -e DB_WAIT_DEBUG=1 \
  -e REDIS_PORT=6379 \
  -e REDIS_CACHE_PORT=6379

# make netbox media persistent
oc set volume \
  deployment/${APP_NAME} \
  --add \
  --name=netbox-media \
  --mount-path=/opt/netbox/netbox/media \
  -t pvc \
  --claim-size=1G \
  --overwrite

# create service
oc expose deployment \
  ${APP_NAME} \
  -n ${NAMESPACE} \
  -l ${APP_LABEL} \
  --port 8080

# create route
oc expose service \
  ${APP_NAME} \
  -n ${NAMESPACE} \
  -l ${APP_LABEL} \
  --overrides='{"spec":{"tls":{"termination":"edge"}}}'

# setup postgres
oc new-app \
  --name ${APP_NAME}-db \
  -n ${NAMESPACE} \
  -l ${APP_LABEL} \
  --image-stream=postgresql:12-el8

cat postgres.env | oc set env -e - deployment/${APP_NAME}-db

# make db persistent
oc set volume \
  deployment/${APP_NAME}-db \
  --add \
  --name=netbox-db \
  --mount-path=/var/lib/postgresql/data \
  --sub-path=db \
  -t pvc \
  --claim-size=1G \
  --overwrite

# setup redis
oc new-app \
  --name ${APP_NAME}-redis \
  -n ${NAMESPACE} \
  -l ${APP_LABEL} \
  --image-stream=redis:latest

cat redis.env | oc set env -e - deployment/${APP_NAME}-redis

# setup redis-cache
oc new-app \
  --name ${APP_NAME}-redis-cache \
  -n ${NAMESPACE} \
  -l ${APP_LABEL} \
  --image-stream=redis:latest

cat redis-cache.env | oc set env -e - deployment/${APP_NAME}-redis-cache
```
