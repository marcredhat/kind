

https://github.com/openlab-red/hashicorp-vault-for-openshift


```bash
git clone https://github.com/marcredhat/vault-guides.git
cd vault-guides/operations/provision-vault/kubernetes/openshift
```

```bash
kubectl create ns vault
namespace/vault created
```

```bash
kubectl config set-context --namespace vault --current
Context "kind-marcccluster01" modified.
```

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com --insecure-skip-tls-verify
helm repo update
helm install vault hashicorp/vault --set "global.openshift=true" --set "server.dev.enabled=true" --insecure-skip-tls-verify
```

```bash
oc get pods
NAME                                   READY   STATUS    RESTARTS   AGE
vault-0                                1/1     Running   0          61s
vault-agent-injector-b6f6b47d4-774j9   1/1     Running   0          65s
```

```bash
oc exec -it vault-0 -- /bin/sh
/ # vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
```

```bash
oc exec -it vault-0 -- /bin/sh
/ # vault write auth/kubernetes/config \
>     token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
>     kubernetes_host="https://10.0.2.15:6443" \
>     kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
Success! Data written to: auth/kubernetes/config
```

