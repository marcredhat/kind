kind create cluster --name marcccluster01 --config cluster01-kind.yaml

kubectl apply -f calico.yaml

oc create -f https://raw.githubusercontent.com/marcredhat/kind/main/deploy.yaml

oc expose deploy nginx-web --port 8080 --target-port 8080


 
curl webserver1.10.0.2.15.nip.io/
Hello, world!
Version: 1.0.0
Hostname: nginx-web-7675865c58-8kf2n
