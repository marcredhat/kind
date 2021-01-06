
SERVICE=vault-agent-injector-svc
NAMESPACE=vault
SECRET_NAME=vault-agent-injector-tls
TMPDIR=/tmp

openssl genrsa -out ${TMPDIR}/vault-injector.key 2048

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

openssl req -new -key ${TMPDIR}/vault-injector.key -subj "/CN=${SERVICE}.${NAMESPACE}.svc" -out ${TMPDIR}/server-vault-agent-injector.csr -config ${TMPDIR}/csr-vault-agent-injector.conf
export CSR_NAME=vault-agent-injector-csr

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



kubectl create -f ${TMPDIR}/agent-injector-csr.yaml
certificatesigningrequest.certificates.k8s.io/vault-agent-injector-csr created


kubectl certificate approve ${CSR_NAME}
certificatesigningrequest.certificates.k8s.io/vault-agent-injector-csr approved



serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')

echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/vault-injector.crt

kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode > ${TMPDIR}/vault-injector.ca

cat ${TMPDIR}/vault-injector.ca | base64

kubectl create secret generic ${SECRET_NAME} \
        --namespace ${NAMESPACE} \
        --from-file=vault-injector.key=${TMPDIR}/vault-injector.key \
        --from-file=vault-injector.crt=${TMPDIR}/vault-injector.crt \
        --from-file=vault-injector.ca=${TMPDIR}/vault-injector.ca

git clone https://github.com/hashicorp/vault-helm.git
Inside the values.yaml file you need to set tlsDisable variable to false to enable TLS. Note that all the configuration of the chart is detailed here
