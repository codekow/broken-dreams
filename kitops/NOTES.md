# KitOps Notes

## Deploy on OpenShift

```sh
oc new-project models

oc new-app \
  --name llama3-8b \
  --image jozu.ml/jozu/llama3-8b/llama-cpp:8B-instruct-q5_0

oc expose deployment/llama3-8b \
  -l app=llama3-8b \
  --port=8000

oc expose service/llama3-8b \
  -l app=llama3-8b

oc patch route/llama3-8b --type merge \
  -p '{"spec": {"tls": {"termination": "edge", "insecureEdgeTerminationPolicy": "Redirect"}}}'
```

## Links

- https://jozu.ml/docs/understanding-jozu-hub/modelkit-containers.html
- https://jozu.ml/repository/jozu/llama3-8b/8B-instruct-q5_0/deploy

