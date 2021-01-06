
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
