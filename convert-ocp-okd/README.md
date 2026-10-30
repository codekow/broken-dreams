# Convert OCP 4.20 to OKD 4.21

This is definitely not recommended or supported

```sh
# download / extract oc for okd
curl -sL https://github.com/okd-project/okd/releases/download/4.21.0-okd-scos.9/openshift-client-linux-4.21.0-okd-scos.9.tar.gz | tar vzxf -
```

```sh
cat << YAML | oc apply -f -
apiVersion: config.openshift.io/v1
kind: ClusterImagePolicy
metadata:
  name: allow-upgrade-to-okd
spec:
  policy:
    rootOfTrust:
      policyType: insecureAcceptAnything
  scopes:
    - quay.io
YAML
```

```sh
oc adm upgrade --force \
  --allow-explicit-upgrade \
  --to-image \
    quay.io/okd/scos-release:4.21.0-okd-scos.9
    # quay.io/okd/scos-release@sha256:ea8a1ccc0173d6d880a7ce880b11f954fa18fda74afe8c2ce7ce48086e94101b
```

```sh
oc delete clusterimagepolicy allow-upgrade-to-okd
```

```sh
# https://okd.io/blog/2026/09/18/okd-cincinnati
oc patch clusterversion version --type merge \
  -p '{"spec":{"upstream":"https://updates.okd.io/api/updates/graph","channel":"stable-4.21"}}'
```

## Other

```sh
oc edit clusterversions.config.openshift.io version --subresource=status
```
