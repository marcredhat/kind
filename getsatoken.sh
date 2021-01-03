kubectl get secret $(kubectl get sa mysa -n default -o json | jq -r '.secrets[0].name') -o json | jq -r '.data.token' | base64 -d

