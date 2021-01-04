
k create namespace helm

k config set-context --current --namespace=helm

helm repo add hashicorp https://helm.releases.hashicorp.com

helm install vault hashicorp/vault --set "server.dev.enabled=true"
