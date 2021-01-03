## Check prereqs

```bash
[root@marcrhel82 kind]# cat /etc/redhat-release
Red Hat Enterprise Linux release 8.3 (Ootpa)
```

```bash
[root@marcrhel82 kind]# go version
go version go1.14.12 linux/amd64
```

```bash
[root@marcrhel82 kind]# helm version
version.BuildInfo{Version:"v3.4.2", GitCommit:"23dd3af5e19a02d4f4baa5b2f242645a1a3af629", GitTreeState:"clean", GoVersion:"go1.14.13"}
```

```bash
[root@marcrhel82 kind]# kubectl version
Client Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.1", GitCommit:"c4d752765b3bbac2237bf87cf0b1c2e307844666", GitTreeState:"clean", BuildDate:"2020-12-18T12:09:25Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"19", GitVersion:"v1.19.1", GitCommit:"206bcadf021e76c27513500ca24182692aabd17e", GitTreeState:"clean", BuildDate:"2020-09-14T07:30:52Z", GoVersion:"go1.15", Compiler:"gc", Platform:"linux/amd64"}
```

```bash
podman version
Version:      2.0.5
API Version:  1
Go Version:   go1.14.7
Built:        Wed Sep 23 09:18:02 2020
OS/Arch:      linux/amd64
```

## Cleanup 

```bash
kind delete clusters marccluster01
```

Expected result:
```text
enabling experimental podman provider
Deleted clusters: ["marccluster01"]
```


```
Use
podman container rm 
to remove any old kind workers and control-planes
```

```bash
git clone https://github.com/marcredhat/kind.git
cd kind
```

```bash
kind create cluster --name marcccluster01 --config cluster01-kind.yaml
```

Expected result:

```text
enabling experimental podman provider
Creating cluster "marcccluster01" ...
 ✓ Ensuring node image (kindest/node:v1.19.1) 🖼
 ✓ Preparing nodes 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-marcccluster01"
You can now use your cluster with:

kubectl cluster-info --context kind-marcccluster01

Thanks for using kind! 😊
```

```bash
kubectl apply -f calico.yaml
```

Expected result:

```text
configmap/calico-config created
Warning: apiextensions.k8s.io/v1beta1 CustomResourceDefinition is deprecated in v1.16+, unavailable in v1.22+; use apiextensions.k8s.io/v1 CustomResourceDefinition
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
daemonset.apps/calico-node created
serviceaccount/calico-node created
deployment.apps/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
```

```bash
oc create -f https://raw.githubusercontent.com/marcredhat/kind/main/deploy.yaml
```


Expected result:

```text
deployment.apps/nginx-web created
```


```bash
oc expose deploy nginx-web --port 8080 --target-port 8080
```

Expected result:

```text
service/nginx-web exposed
```

```bash
oc apply -f nginx-ingress.yaml
```

Expected result:

```text
ingress.networking.k8s.io/minimal-ingress created
```

```bash 
curl webserver1.10.0.2.15.nip.io/
```

Expected result:
```text
Hello, world!
Version: 1.0.0
Hostname: nginx-web-7675865c58-8kf2n
```
