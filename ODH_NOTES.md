# ODH Operator Testing (aka: why ODH sucks)

### Summary

The ODH operator at it's core is a re-branded `kubeflow` [operator](https://operatorhub.io/operator/kubeflow).

The primary differentiators are:

- A default `kfDef` custom resource
- The [odh manifests](https://github.com/opendatahub-io/odh-manifests/)
- The [odh contrib manifests](https://github.com/opendatahub-io-contrib/odh-contrib-manifests)

### Before

```
oc api-resources > api-before.txt
oc get crd > crd-before.txt
oc get sub -A > sub-before.txt
oc get csv -A > csv-before.txt
```

### Install

```
# install odh operator
oc apply -k https://github.com/redhat-cop/gitops-catalog/opendatahub-operator/operator/overlays/stable

# new project
oc new-project odh-testing

# default kfdef
cat << YAML | oc apply -f -
kind: KfDef
apiVersion: kfdef.apps.kubeflow.org/v1
metadata:
  name: opendatahub
spec:
  applications:
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: odh-common
      name: odh-common
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: odh-dashboard
      name: odh-dashboard
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: prometheus/cluster
      name: prometheus-cluster
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: prometheus/operator
      name: prometheus-operator
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: grafana/cluster
      name: grafana-cluster
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: grafana/grafana
      name: grafana-instance
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: odh-notebook-controller
      name: odh-notebook-controller
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: notebook-images
      name: notebook-images
    - kustomizeConfig:
        overlays:
          - odh-model-controller
        repoRef:
          name: manifests
          path: model-mesh
      name: model-mesh
    - kustomizeConfig:
        overlays:
          - metadata-store-mariadb
          - ds-pipeline-ui
          - object-store-minio
          - default-configs
        repoRef:
          name: manifests
          path: data-science-pipelines
      name: data-science-pipelines
  repos:
    - name: manifests
      uri: 'https://github.com/opendatahub-io/odh-manifests/tarball/v1.4.1'
YAML

# NOTE: many accidentally install the kfdef in openshift-operators
# NOTE: the default ns in the console changes to openshift-operators

# NOTE: kfdef opendatahub does not display anything in the `resources` tab indicating a lack of labeling

# BUG: operator installs `grafana` and `prometheus` operators with kfDef
# BUG: removes sub, not csv

# NOTE: `The group odh-admins no longer exists in OpenShift and has been removed from the selected group list.`
# BUG: PVCs created for notebook are set to `20` (bytes) not `20Gi` (gigabytes)
```

### After

```
# see what crds got installed
oc api-resources > api-after.txt
oc get crd > crd-after.txt

diff -u api-before.txt api-after.txt > api-diff.txt
diff -u crd-before.txt crd-after.txt > crd-diff.txt

grep '^+' api-diff.txt
grep '^+' crd-diff.txt
```

### Uninstall

```
# run the uninstall wizard (may fail)
# NOTE: crd named `odhquickstarts.console.openshift.io` does not follow the same domain `opendatahub.io`
# NOTE: inconsistency in api use: `odhquickstarts console.openshift.io/v1 true OdhQuickStart`
# NOTE: grafana dependencies not removed

# removing finalizers for kfdefs
# BUG: odh operator doesn't consistently remove kfdefs
for kfdef in $(oc get kfdef -A -o name)
  do oc patch $kfdef -n <namespace> --type merge -p '{"metadata": {"finalizers": null}}'
done

# removing related crds
for crd in $(oc get crd -o name | egrep 'odh|kfdef' | sed 's@custom.*k8s.io/@@')
do
  echo "Searching for CR: $crd"
  oc delete $crd --all -A
  oc delete crd $crd
done

# removing related crds - hope you weren't using grafana
for crd in $(oc get crd -o name | egrep 'integreatly.org' | sed 's@custom.*k8s.io/@@')
do
  echo "Searching for CR: $crd"
  oc get $crd -A 2 > /dev/null
  oc delete $crd --all -A
  oc delete crd $crd
done

# what an uninstall does in the ocp console
# delete csv,sub = uninstall
# BUG: odh operator does not remove csv
oc delete -n openshift-operators csv opendatahub-operator.v1.4.1
oc delete -n openshift-operators sub opendatahub-operator

# BUG: the odh operator created a redundant operator group in openshift-operators
# kfctl.kubeflow.io/kfdef-instance: opendatahub.openshift-operators
# oc get operatorgroup -l opendatahub.io/component -A
oc -n openshift-operators delete operatorgroup opendatahub

# INFO: additional namespaces created
# oc get ns -l opendatahub.io/component
oc delete ns anonymous system
```
