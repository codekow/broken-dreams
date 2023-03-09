#!/bin/sh

install_odh(){

oc apply -k https://github.com/redhat-cop/gitops-catalog/opendatahub-operator/operator/overlays/stable

# new project
oc new-project odh-testing
sleep 60

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
}


remove_odh(){
	# run the uninstall wizard (may fail)
	# NOTE: crd named `odhquickstarts.console.openshift.io` does not follow the same domain `opendatahub.io`
	# NOTE: inconsistency in api use: `odhquickstarts console.openshift.io/v1 true OdhQuickStart`
	# NOTE: grafana dependencies not removed

	# removing finalizers for kfdefs
	# BUG: odh operator doesn't consistently remove kfdefs

	oc get kfdef -A

	oc get kfdef -A | grep -v NAME | while read -r NAMESPACE NAME JUNK
	do
		oc -n "${NAMESPACE}" patch kfdef "${NAME}" --type merge -p '{"metadata": {"finalizers": null}}'
	done

	# removing related crds
	BASIC_INFO="NAMESPACE:.metadata.namespace"
	BASIC_INFO="${BASIC_INFO},NAME:.metadata.name"

	for crd in $(oc get crd -o name | egrep 'odh|kfdef' | sed 's@custom.*k8s.io/@@')
	do
		echo "Searching for CR: $crd"
		oc get $crd --no-headers -o custom-columns="${BASIC_INFO}" -A | while read -r NAMESPACE NAME
		do
			oc delete -n "${NAMESPACE}" "$crd" "${NAME}"
		done
	done

	# removing related crds - hope you weren't using grafana
	for crd in $(oc get crd -o name | egrep 'integreatly.org' | sed 's@custom.*k8s.io/@@')
	do
		echo "Searching for CR: $crd"
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

	echo "delete the project / namespace where you deployed your original kfdefs"
	echo "oc delete <project>"

}

# remove_odh