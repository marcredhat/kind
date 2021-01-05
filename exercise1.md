
# StatefulSet

https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/

https://github.com/marcredhat/kubernetes-examples/blob/master/StatefulSet/simple-stateful-set.yaml



```bash
#git clone https://github.com/marcredhat/kubernetes-examples.git
cd kubernetes-examples/StatefulSet/
kubectl create -f simple-stateful-set.yaml
```

Expected result:

```text
oc get pods
NAME                         READY   STATUS    RESTARTS   AGE
simple-stateful-set-0        1/1     Running   0          13s
simple-stateful-set-1        1/1     Running   0          9s
simple-stateful-set-2        1/1     Running   0          6s


oc get pvc
NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
www-simple-stateful-set-0   Bound    pvc-f01deee7-7fc3-4326-97a0-98f87591b73f   1Gi        RWO            standard       67s
www-simple-stateful-set-1   Bound    pvc-5c182be0-3a3f-4d1f-b1a1-b19d587dfc61   1Gi        RWO            standard       63s
www-simple-stateful-set-2   Bound    pvc-f3795d90-b5c8-4b3d-9fa3-04c3cc50d270   1Gi        RWO            standard       60s
```

```bash
for i in 0 1 2; do kubectl exec "simple-stateful-set-$i" -- sh -c 'hostname'; done
simple-stateful-set-0
simple-stateful-set-1
simple-stateful-set-2
```

```bash
oc exec -it simple-stateful-set-0 -- sh
/ # nslookup simple-stateful-set-0.nginx
Name:      simple-stateful-set-0.nginx
Address 1: 10.240.207.136 simple-stateful-set-0.nginx.default.svc.cluster.local
```

```text
The CNAME of the headless service points to SRV records (one for each Pod that is Running and Ready).
The SRV records point to A record entries that contain the Pods' IP addresses.

If you need to find and connect to the active members of a StatefulSet, you should 
query the CNAME of the headless Service (nginx.default.svc).
```

```bash
/ # nslookup  nginx.default.svc

Name:      nginx.default.svc
Address 1: 10.240.207.162 simple-stateful-set-0.nginx.default.svc.cluster.local
Address 2: 10.240.207.166 simple-stateful-set-2.nginx.default.svc.cluster.local
Address 3: 10.240.207.164 simple-stateful-set-1.nginx.default.svc.cluster.local
```

```text
The SRV records associated with the CNAME will contain only the Pods in the StatefulSet that are Running and Ready.

If your application already implements connection logic that tests for liveness and readiness, 
you can use the SRV records of the Pods 
(simple-stateful-set-0.nginx.default.svc.cluster.local, 
simple-stateful-set-1.nginx.default.svc.cluster.local, 
simple-stateful-set-2.nginx.default.svc.cluster.local), as they are stable, 
and your application will be able to discover the Pods' addresses when they transition to Running and Ready.
```


```text
The PersistentVolumes mounted to the Pods of a StatefulSet are not deleted when the StatefulSet's Pods are deleted. 

This is still true when Pod deletion is caused by scaling the StatefulSet down.
```

```bash
oc exec -it simple-stateful-set-0 -- sh
/ # cd /persist
/persist # touch 0
/persist # exit
 
oc exec -it simple-stateful-set-1 -- sh
/ # cd /persist
/persist # touch 1
/persist # exit

oc exec -it simple-stateful-set-2 -- sh
/ # cd /persist
/persist # touch 2
/persist # exit
```

```bash
kubectl delete pod -l app=nginx
pod "simple-stateful-set-0" deleted
pod "simple-stateful-set-1" deleted
pod "simple-stateful-set-2" deleted
```

```bash
oc exec -it simple-stateful-set-0 -- sh
/ # ls /persist/
0
```



