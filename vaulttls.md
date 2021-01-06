
https://cogarius.medium.com/a-vault-for-all-your-secrets-full-tls-on-kubernetes-with-kv-v2-c0ecd42853e1


```bash
SERVICE=vault-agent-injector-svc
NAMESPACE=vault
SECRET_NAME=vault-agent-injector-tls
TMPDIR=/tmp
```

```bash
openssl genrsa -out ${TMPDIR}/vault-injector.key 2048
```

```bash
cat <<EOF >${TMPDIR}/csr-vault-agent-injector.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE}
DNS.2 = ${SERVICE}.${NAMESPACE}
DNS.3 = ${SERVICE}.${NAMESPACE}.svc
DNS.4 = ${SERVICE}.${NAMESPACE}.svc.cluster.local
IP.1 = 127.0.0.1
EOF
```

```bash
openssl req -new -key ${TMPDIR}/vault-injector.key -subj "/CN=${SERVICE}.${NAMESPACE}.svc" -out ${TMPDIR}/server-vault-agent-injector.csr -config ${TMPDIR}/csr-vault-agent-injector.conf
```

```bash
export CSR_NAME=vault-agent-injector-csr
```

```bash
cat <<EOF >${TMPDIR}/agent-injector-csr.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/server-vault-agent-injector.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF
```

```bash
kubectl create -f ${TMPDIR}/agent-injector-csr.yaml
certificatesigningrequest.certificates.k8s.io/vault-agent-injector-csr created
```

```bash
kubectl certificate approve ${CSR_NAME}
certificatesigningrequest.certificates.k8s.io/vault-agent-injector-csr approved
```

```bash
serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')

echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/vault-injector.crt

kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode > ${TMPDIR}/vault-injector.ca

cat ${TMPDIR}/vault-injector.ca | base64

kubectl create secret generic ${SECRET_NAME} \
        --namespace ${NAMESPACE} \
        --from-file=vault-injector.key=${TMPDIR}/vault-injector.key \
        --from-file=vault-injector.crt=${TMPDIR}/vault-injector.crt \
        --from-file=vault-injector.ca=${TMPDIR}/vault-injector.ca
        
secret/vault-agent-injector-tls created       

git clone https://github.com/hashicorp/vault-helm.git
Inside the values.yaml file you need to set tlsDisable variable to false to enable TLS. Note that all the configuration of the chart is detailed here
```
....

Follow the instructions from 
https://cogarius.medium.com/a-vault-for-all-your-secrets-full-tls-on-kubernetes-with-kv-v2-c0ecd42853e1 
to update your values.yaml

My values.yaml is at https://github.com/marcredhat/kind/blob/main/values.yaml

....

```bash
helm install marcvault2 .
```

```bash
oc get pods
NAME                                         READY   STATUS    RESTARTS   AGE
marcvault2-0                                 0/1     Running   0          6m14s
marcvault2-agent-injector-775ddf757b-xnh94   1/1     Running   0          6m15s
webapp-7cf4cb477-m5vnc                       1/1     Running   0          137m
```


## Vault init and unsealing

```text
At the end of the chart installation you will notice that the vault-0 pod 
will not switch to the ready state. 

We need to init and unseal the vault for it to be ready.

For HA deployments, only one of the Vault pods needs to be initialized.
```

```bash
kubectl exec -ti vault-0 -- vault operator init -address http://127.0.0.1:8200
```

```text
Vault will print out five unseal keys and a root token. Indeed vault secrets are encrypted with an encryption key that is itself encrypted with a master key. Vault does not store the master key. To decrypt the data, Vault must decrypt the encryption key which requires the master key.
Unsealing is the process of reconstructing this master key. Without at least 3 keys out of the five to reconstruct the master key, the vault will remain permanently sealed!
```

```bash
kubectl exec -ti marcvault2-0 -- vault operator init -address http://127.0.0.1:8200
Unseal Key 1: wPL7HDOoZre10Hz3CtePnpTyadMOs2jEb4SGoik8wgSy
Unseal Key 2: KNes3ugIfgJgha4hcsi71Vr+uFRBOXF/SmiyzlZFWrof
Unseal Key 3: 3ekOwE8543TfihtNy6CUXjWJxq/dpRYsT1GCoJ+Vklr1
Unseal Key 4: rwZrguSGQpKCR5yJh8dfNfmmavPd1gtRbMARD9Pem775
Unseal Key 5: yDjyuzQRi/wKibK3tS5iyDrW7IlAxYaeIWxyfa5ZA5GU

Initial Root Token: s.ofgWKTxmpa5YITwcIhRRGgPO

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 3 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

```bash
kubectl exec -ti marcvault2-0 --  vault operator unseal --address http://127.0.0.1:8200
Unseal Key (will be hidden):
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       118ffb33-9883-45d1-77dd-eb7144bc92a9
Version            1.6.1
Storage Type       file
HA Enabled         false
```

```text
Note aboce that Unseal progress is 1/3

We need to repeat the unseal process with 2 other keys
...

vault operator unseal --address http://10.240.207.171:8200
Unseal Key (will be hidden):
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.6.1
Storage Type    file
Cluster Name    vault-cluster-c3297237
Cluster ID      7b9ab370-2725-990e-f071-2063543f8468
HA Enabled      false
```

```bash
oc apply -f https://raw.githubusercontent.com/marcredhat/kind/main/service-account-webapp.yaml
serviceaccount/webapp created
```


```bash
oc get sa
NAME                        SECRETS   AGE
default                     1         3h10m
marcvault2                  1         31m
marcvault2-agent-injector   1         31m
webapp                      1         171m
```

```bash
kubectl create namespace app-ns
namespace/app-ns created
```

```bash
kubectl create serviceaccount app-auth
serviceaccount/app-auth created
```

```bash
oc exec -it marcvault2-0 -- /bin/sh
/ # export VAULT_ADDR='http://127.0.0.1:8200'
```

```bash
tee /tmp/app-ro-pol.hcl <<EOF
# As we are working with KV v2
path "kv/data/secret/app/*" {
    capabilities = ["read", "list", "create", "update"]
}
EOF
```

```bash
cat  /tmp/app-ro-pol.hcl
# As we are working with KV v2
path "kv/data/secret/app/*" {
    capabilities = ["read", "list", "create", "update"]
}
```

```bash
/ $ vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.ofgWKTxmpa5YITwcIhRRGgPO
token_accessor       yFCVSVDhcVcTrTpzXh8XAUxN
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

```bash
/ $ vault policy write app-ro-pol /tmp/app-ro-pol.hcl
Success! Uploaded policy: app-ro-pol
```

```bash
/ $ vault secrets enable -path=kv kv
Success! Enabled the kv secrets engine at: kv/
```

```bash
/ $ vault secrets list -detailed
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----
cubbyhole/    cubbyhole    cubbyhole_261e961b    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           fe639c60-0cbb-f11d-921d-bc3d2ba86b29
identity/     identity     identity_2cdd5ee1     system         system     false             replicated     false        false                      map[]      identity store                                             b8770c0b-b108-390c-9bef-c3d8d8ab8ffe
kv/           kv           kv_55b01e47           system         system     false             replicated     false        false                      map[]      n/a                                                        a1d1d0de-3a01-369a-7890-43f5e70dbe93
sys/          system       system_72804ea9       n/a            n/a        false             replicated     false        false                      map[]      system endpoints used for control, policy and debugging    d1b1ded7-3278-f7b8-9400-6d3c965fc9b8
```


vault kv put kv/data/secret/app/config username='heisenberg' password='urdamnright' ttl='30s'


```bash
/ $ vault kv put kv/data/secret/app/config username='heisenberg' password='urdamnright' ttl='30s'
Success! Data written to: kv/data/secret/app/config
```


## Get a token linked to the policy

```bash
/ $ vault token create -policy=app-ro-pol
Key                  Value
---                  -----
token                s.yVvAJcmZwqhCNOTNFHNAdCiJ
token_accessor       aD06yJzC0gT1eear8ypsu5pH
token_duration       768h
token_renewable      true
token_policies       ["app-ro-pol" "default"]
identity_policies    []
policies             ["app-ro-pol" "default"]
```

## Login with the above token

```bash
/ $ vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.yVvAJcmZwqhCNOTNFHNAdCiJ
token_accessor       aD06yJzC0gT1eear8ypsu5pH
token_duration       767h58m48s
token_renewable      true
token_policies       ["app-ro-pol" "default"]
identity_policies    []
policies             ["app-ro-pol" "default"]
```


## Test if we can access our secret 


```bash
/ $ vault kv get kv/data/secret/app/config
====== Data ======
Key         Value
---         -----
password    urdamnright
ttl         30s
username    heisenberg
```

## Configure Kubernetes auth method

Login with the Initial Root Token

```bash
vault login

/ $ vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
```

```bash
/ $ export KUBERNETES_TCP_ADDR="10.0.2.15:6443"

/ $ vault write auth/kubernetes/config \
>     token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
>     kubernetes_host=${KUBERNETES_TCP_ADDR} \
>  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
Success! Data written to: auth/kubernetes/config
```

## Create a role named, 'app' to map our app's Kubernetes Service Account to Vault policies and default token TTL

```bash
vault write auth/kubernetes/role/app \
        bound_service_account_names=app-auth \
        bound_service_account_namespaces=app-ns \
        policies=app-ro-pol \
        ttl=24h
        
Success! Data written to: auth/kubernetes/role/app
```

```bash
kubectl config set-context --current --namespace=app-ns
```

```bash
kubectl create serviceaccount app-auth
serviceaccount/app-auth created
```

```bash
cat <<EOF >> app.yaml
# app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: vault
  labels:
    app: vault-agent-demo
spec:
  selector:
    matchLabels:
      app: vault-agent-demo
  replicas: 1
  template:
    metadata:
      annotations:
      labels:
        app: vault-agent-demo
    spec:
      serviceAccountName: app-auth
      containers:
      - name: app
        image: jweissig/app:0.0.1
EOF
```

```bash
kubectl create -f app.yaml
deployment.apps/app created
```

Next, let’s launch our example application and create the service account. 

We can also verify there are no secrets mounted at /vault/secrets.

```bash
oc get pods
NAME                     READY   STATUS    RESTARTS   AGE
app-98cdf8f99-zpx8p      1/1     Running   0          4m42s
webapp-8cff8b6d8-9pfb8   1/1     Running   0          6m21s

kubectl exec -ti app-98cdf8f99-zpx8p -c app -- ls -l /vault/secrets
ls: /vault/secrets: No such file or directory
```

```bash
cat <<EOF >> patch-app.yaml
# patch-basic-annotations.yaml
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-status: "update"
        vault.hashicorp.com/ca-cert: "/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        vault.hashicorp.com/agent-inject-secret-app-config: "kv/data/secret/app/config"
        vault.hashicorp.com/role: "app"
EOF
```  

```bash
kubectl patch deployment app --patch "$(cat patch-app.yaml)"
deployment.apps/app patched
```







