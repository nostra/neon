# Distribution registry

- https://hub.docker.com/_/registry
- https://distribution.github.io/distribution/

Docker registry

Add TLS certificate with cert-manager:
- https://skarlso.github.io/2023/10/25/self-signed-locally-trusted-certificates-with-cert-manager/


```shell
kubectl port-forward -n management svc/registry 5000
```

Notice that the port-forwarding will not work correctly without having
certificates, or insecure connection.

## Configure user

TODO Organize differently:

```shell
docker run \
  --entrypoint htpasswd \
  httpd:2 -Bbn testuser testpassword >htpasswd
  ```

docker tag flux_sshd:v1 localhost:5000/flux_sshd
docker push localhost:5000/flux_sshd 

# To use as local registry

Kubernetes cannot pull images from inside itself, so you have to 
expose the endpoint externally. A guide for this, which would need some
adjustments to work as Rancher config needs to be adjusted:
- https://blog.zachinachshon.com/docker-registry/

A guide for Kind with external docker repo for repository:
- https://kind.sigs.k8s.io/docs/user/local-registry/