# NFS dynamic provisioner

```
NAMESPACE=`oc project -q`
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    -f values.yaml \
    -n nfs-provisioner

oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:$NAMESPACE:nfs-provisioner
```

## Links

- https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner