# `oras` example

```sh
REGISTRY_DIR=./scratch

mkdir -p $REGISTRY_DIR
podman run -d \
  --name oras-registry \
  -p 5000:5000 \
  -v $REGISTRY_DIR:/var/lib/registry:z \
  --restart=always \
    docker.io/library/registry:2
```

```sh
REG_CONFIG=${HOME}/.config/containers/registries.conf

mkdir -p $(dirname ${REG_CONFIG})
cat > ${REG_CONFIG} << CONF
unqualified-search-registries = ["registry.fedoraproject.org", "registry.access.redhat.com", "docker.io"]

[[registry]]
location = 'localhost:5000'
insecure = true
CONF
```

```sh
mkdir -p downloads && cd downloads
curl -sL https://raw.githubusercontent.com/redhat-na-ssa/ocp-web-terminal-enhanced/refs/heads/main/container/download_tools.sh | bash
cd ..

oras push localhost:5000/downloads:0.1 \
  README.md:text/markdown \
  ./downloads/scratch/usr/local/bin/:application/x-tar
```
