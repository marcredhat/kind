kubectl get secret $(kubectl get sa default -n default -o json | jq -r '.secrets[0].name') -o json | jq -r '.data.token' | base64 -d
export KUBE_AZ=$(kubectl get secret $(kubectl get sa default -n default -o json | jq -r '.secrets[0].name') -o json | jq -r '.data.token' | base64 -d) 
curl  -H "Authorization: Bearer $KUBE_AZ" --insecure https://0.0.0.0:32768/api



