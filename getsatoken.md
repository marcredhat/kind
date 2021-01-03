
kubectl get secret $(kubectl get sa default -n default -o json | jq -r '.secrets[0].name') -o json | jq -r '.data.token' | base64 -d

export KUBE_AZ=$(kubectl get secret $(kubectl get sa default -n default -o json | jq -r '.secrets[0].name') -o json | jq -r '.data.token' | base64 -d) 

curl  -H "Authorization: Bearer $KUBE_AZ" --insecure https://10.0.2.15:6443/api

{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "10.88.0.26:6443"
    }
  ]



