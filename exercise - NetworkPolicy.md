```bash
kubectl apply -f https://raw.githubusercontent.com/marcredhat/kind/main/yaobank.yaml
service/database created
serviceaccount/database created
deployment.apps/database created
service/summary created
serviceaccount/summary created
deployment.apps/summary created
service/customer created
serviceaccount/customer created
deployment.apps/customer created
```

## Simulate compromise

```text
To simulate a compromise of the customer pod we will exec into the pod and attempt to access the database directly from there.

CUSTOMER_POD=$(kubectl get pods -n yaobank -l app=customer -o name)

kubectl exec -it $CUSTOMER_POD -n yaobank -c customer -- /bin/bash
Access the database
From within the customer pod, we will now attempt to access the database directly, simulating an attack.  As the pod is not secured with NetworkPolicy, the attack will succeed and the balance of all users will be returned.

curl http://database:2379/v2/keys?recursive=true | python -m json.tool
```

## NetworkPolicy

```bash
oc apply -f https://raw.githubusercontent.com/marcredhat/kind/main/netpolicy1.yaml

curl http://database:2379/v2/keys?recursive=true | python -m json.tool

root@customer-68d67b588d-dk5p7:/app# curl http://database:2379/v2/keys?recursive=true | python -m json.tool
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:01 --:--:--     0
```  


## GlobalNetworkPolicy

```text
Switch the cluster to a default-deny behavior. 
This is a best practice that ensures that every new microservice deployed needs to have an 
accompanying network policy and no microservices are accidentally left wide open to attack.

You can do this on a per-namespace scope using Kubernetes Network Policy, but 
that requires each namespace to have its own default-deny policy, and 
relies on remembering to create a default-deny policy each time a new namespace is created. 

Since Calico’s GlobalNetworkPolicy policies apply across all namespaces, 
you can write a single default-deny policy for the whole of your cluster.
```

```bash
curl -O -L  https://github.com/projectcalico/calicoctl/releases/download/v3.17.1/calicoctl
chmod +x calicoctl
mv ./calicoctl /usr/bin
```

```bash
oc get ns
NAME                 STATUS   AGE
default              Active   3h50m
ingress-nginx        Active   3h49m
kube-node-lease      Active   3h50m
kube-public          Active   3h50m
kube-system          Active   3h50m
local-path-storage   Active   3h50m
yaobank              Active   46m
```

```yaml
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: default-app-policy
spec:
  namespaceSelector: has(projectcalico.org/name) && projectcalico.org/name not in {"kube-system", "kube-node-lease", "calico-system", "kube-public","local-path-storage"}
  types:
  - Ingress
  - Egress
```

```bash
oc apply -f https://raw.githubusercontent.com/marcredhat/kind/main/globalnetpolicy1.yaml
```


