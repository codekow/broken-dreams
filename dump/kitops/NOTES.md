# KitOps Notes

## Easy deploy of `llama3-8b` on OpenShift

```sh
# create project / namespace
oc new-project models

# create deployment
oc new-app \
  --name llama3-8b \
  --image jozu.ml/jozu/llama3-8b/llama-cpp:8B-instruct-q5_0

# create service
oc expose deployment/llama3-8b \
  -l app=llama3-8b \
  --port=8000

# create route
oc expose service/llama3-8b \
  -l app=llama3-8b

# patch route to use tls
oc patch route/llama3-8b --type merge \
  -p '{"spec": {"tls": {"termination": "edge", "insecureEdgeTerminationPolicy": "Redirect"}}}'
```

```sh
# storage is at ~/.local/share/kitops
kit pull jozu.ml/jozu/llama3-8b:8B-text-q8_0

# list local cached models
kit list

# list info about local models
kit info jozu.ml/jozu/llama3-8b:8B-text-q8_0

# unpack 
kit unpack jozu.ml/jozu/llama3-8b:8B-text-q8_0 -d scratch
```

## Links

- https://jozu.ml/docs/understanding-jozu-hub/modelkit-containers.html
- https://jozu.ml/repository/jozu/llama3-8b/8B-instruct-q5_0/deploy
