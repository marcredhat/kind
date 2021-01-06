
https://learn.hashicorp.com/tutorials/vault/kubernetes-openshift?in=vault/kubernetes
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

```bash
oc create -f https://raw.githubusercontent.com/marcredhat/kind/main/service-account-webapp.yaml
serviceaccount/webapp created

oc get sa
NAME                   SECRETS   AGE
default                1         18m
vault                  1         15m
vault-agent-injector   1         15m
webapp                 1         7s
```


```bash
oc exec -it vault-0 -- /bin/sh
/ # vault kv put secret/webapp/config username="static-user" \
>     password="static-password"
Key              Value
---              -----
created_time     2020-12-30T13:08:09.641527354Z
deletion_time    n/a
destroyed        false
version          1
/ #
```


```bash
/ # vault kv get secret/webapp/config
====== Metadata ======
Key              Value
---              -----
created_time     2020-12-30T13:08:09.641527354Z
deletion_time    n/a
destroyed        false
version          1

====== Data ======
Key         Value
---         -----
password    static-password
username    static-user
```

```bash
/ # vault policy write webapp - <<EOF
> path "secret/data/webapp/config" {
>   capabilities = ["read"]
> }
> EOF
Success! Uploaded policy: webapp
```

```bash
/ # vault write auth/kubernetes/role/webapp \
>     bound_service_account_names=webapp \
>     bound_service_account_namespaces=default \
>     policies=webapp \
>     ttl=24h
Success! Data written to: auth/kubernetes/role/webapp
```

oc create -f https://raw.githubusercontent.com/marcredhat/kind/main/vault-deployement-webapp.yaml
deployment.apps/webapp created




