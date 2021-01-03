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

```bash
kubectl apply -f calico.yaml
```

```bash
oc create -f https://raw.githubusercontent.com/marcredhat/kind/main/deploy.yaml
```

```bash
oc expose deploy nginx-web --port 8080 --target-port 8080
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
