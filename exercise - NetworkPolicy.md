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
