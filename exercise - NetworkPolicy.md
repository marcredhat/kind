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
To simulate a compromise of the customer pod we will exec into the pod and 
attempt to access the database directly from there.

CUSTOMER_POD=$(kubectl get pods -n yaobank -l app=customer -o name)

kubectl config set-context yaobank

kubectl exec -it $CUSTOMER_POD -n yaobank -c customer -- /bin/bash

Access the database
From within the customer pod, we will now attempt to access the database directly, 
simulating an attack.  

As the pod is not secured with NetworkPolicy, 
the attack will succeed and the balance of all users will be returned.

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

```text
For this lab we’ve chosen to exclude kube-system and calico-system namespaces, 
since we don’t want the policy to impact the Kubernetes or Calico control planes. 
(This is a good best practice which avoids accidentally breaking the control planes, 
in case you have not already set up appropriate network policies and/or Calico failsafe port rules that allows control plane traffic. 

You can then separately write network policy for each control plane component.)
As the policy contains no rules, it doesn't actually matter what precedence it has, so we did not specify an order value.  

Omitting the order field on a network policy means it has the lower precedence 
compared to any Calico network policy which does specify an order, or 
Kubernetes network policies which have an implicit order of 1000. 
```


Let's label our namespaces:

```bash
  kubectl label namespace default projectcalico.org/name=default 
  kubectl label namespace kube-node-lease projectcalico.org/name=kube-node-lease
  kubectl label namespace kube-public projectcalico.org/name=kube-public
  kubectl label namespace kube-system  projectcalico.org/name=kube-system  
  kubectl label namespace local-path-storage projectcalico.org/name=local-path-storage
  kubectl label namespace yaobank projectcalico.org/name=yaobank 
```


```yaml
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: default-app-policy
spec:
  namespaceSelector:  projectcalico.org/name not in {"kube-system", "kube-node-lease", "calico-system", "kube-public","local-path-storage"}
  types:
  - Ingress
  - Egress
```

```bash
wget https://raw.githubusercontent.com/marcredhat/kind/main/globalnetpolicy1.yaml
```

```bash
calicoctl apply -f globalnetpolicy1.yaml
Successfully applied 1 'GlobalNetworkPolicy' resource(s)
```


## Verify default deny is in place

```text
So far we only defined network policy for the Database. 
The rest of our pods should now be hitting default deny (for both ingress and egress) since 
there's no policy defined to say who they are allowed to talk to.

Let's try to see if basic connectivity works, e.g. DNS.
It should fail, timing out after around 15s, because we've not written any policy to say DNS (or any other egress) is allowed.
```

```bash
kubectl exec -ti $CUSTOMER_POD -n yaobank -c customer -- /bin/bash
root@customer-68d67b588d-dk5p7:/app# dig www.google.com
```

## Allow DNS 

```bash
cat ./globalnetpolicy2.yaml
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: default-app-policy
spec:
  namespaceSelector: has(projectcalico.org/name) && projectcalico.org/name not in { "kube-node-lease", "calico-system", "kube-public","local-path-storage"}
  types:
  - Ingress
  - Egress
  egress:
    - action: Allow
      protocol: UDP
      destination:
        selector: k8s-app == "kube-dns"
        ports:
          - 53
```

Above, we used selector: "k8s-app=kube-dns" as  this is the label for coredns pods:

```bash
oc get pods -n kube-system --show-labels | grep coredns
coredns-f9fd979d6-7h55h                                1/1     Running   0          4h29m   k8s-app=kube-dns,pod-template-hash=f9fd979d6
coredns-f9fd979d6-klmrq                                1/1     Running   0          4h29m   k8s-app=kube-dns,pod-template-hash=f9fd979d6
```


```bash
calicoctl delete -f globalnetpolicy1.yaml
calicoctl apply -f  globalnetpolicy2.yaml
Successfully applied 1 'GlobalNetworkPolicy' resource(s)
```

Check DNS access from the customer pod:

```bash
kubectl exec -ti $CUSTOMER_POD -n yaobank -c customer -- /bin/bash
root@customer-68d67b588d-dk5p7:/app# dig www.google.com
```



