# kube-dns-proxy
Lightweight per-node DNS proxy for the Kubernetes.
It is used to reduce the number of the DNS requests to **kube-dns** and to cache results in case of node connectivity was lost.
It uses the simple cache strategy - stale records are not deleted from the cache if source server can not reply to the request, so every time the connection to **kube-dns** was lost, cache stays in it last state until the connection is restored.
## How it works
**K8S** uses predefined IP address for the **kube-dns** to route dns requests to.
You will reroute requests to that IP address via iptables to the localhost, so the local dns proxy will get dns requests and will be capable to propper resolve them.
## Installation
At first, you need to move **kube-dns** service to different IP.
To do that, you must change the IP address of the service, take a note that K8S didn't allow to change IP address of the service, so you will need to recreate that.
Default IP of the kubernetes dns server is 10.96.0.10, we will change it to 10.96.0.11
Create file
  - kube-dns-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: KubeDNS
  name: kube-dns
  namespace: kube-system
spec:
  clusterIP: 10.96.0.11
  ports:
  - name: dns
    port: 53
    protocol: UDP
    targetPort: 53
  - name: dns-tcp
    port: 53
    protocol: TCP
    targetPort: 53
  selector:
    k8s-app: kube-dns
  sessionAffinity: None
  type: ClusterIP
```
Kubernetes didn't allow to change clusterIP after it was assigned, so delete Service and create it again:
```sh
kubectl delete -f kube-dns-service.yaml
kubeclt create -f kube-dns-service.yaml
```
Now  deploy pdnsd to all nodes of your cluster:
  - pdnsd-mirror.yaml
```yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: pdnsd
  namespace: kube-system
  labels:
    app: pdnsd
spec:
  selector:
    matchLabels:
      app: pdnsd
  template:
    metadata:
      labels:
        app: pdnsd
    spec:
      hostNetwork: true
      containers:
        - name: pdnsd
          image: tzlom/kube-dns-proxy:1
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 53
              name: dns
              protocol: UDP
              hostPort: 53
            - containerPort: 53
              name: dns-tcp
              protocol: TCP
              hostPort: 53
```
```sh
kubectl create -f pdnsd-mirror.yaml
```
The last step is to reroute dns requests from 
```sh
iptables -t nat -I PREROUTING --dest 10.96.0.10 -p udp --dport 53 -j DNAT --to-dest 127.0.0.1
```
