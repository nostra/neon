name: inverse
layout: true
class: center, middle, inverse
---
# NeonPandora
Deprecated, now using Jupyter

.footnote[xx.02.2024 Erlend Nossum]
???

- Made with: https://github.com/gnab/remark

---
layout: false
## Agenda
.left-column[
] .right-column[

Mål: Å starte med et blankt Kubernetes-cluster på din lokale laptop og:
- etablere et basis-oppsett
- sette internt docker repository
- sette opp gitrepo internt i Kubernetes-clusteret
- lage en quarkus-basert applikasjon
- bygge applikasjonen i clusteret ved innsjekking
- automatisk deployment
- samle metrikker fra applikasjonen
- alerts
]
---
## Tech recap
.left-column[
] .right-column[
Alternative: https://docs.openfaas.com/
]
---
## Tooling - this gets presented today

Install:
- https://docs.docker.com/install/
- https://kubernetes.io/docs/tasks/tools/install-kubectl/
- https://github.com/kubernetes-sigs/kind
- https://fluxcd.io/docs/installation/#install-the-flux-cli
- https://kubectl.docs.kubernetes.io/references/kustomize/
```
kind --version        # Should yield at least 0.20.0
docker ps             # Should not give any errors
kubectl version       # Should at least give 1.29
flux version --client # Should at least give 2.2.2
kustomize version     # 5.3.0, most are good
yq --version          # 4.40.5
cilium version        # 0.15.19 (server version 1.14.4)
hubble                # 0.12.3
```
Note: On Mac you will need gnu-sed and replace the `sed` commands with `gsed`.
???
- TODO: Add brew install cmd lines
---
# Adjust command line

```shell
git config --global push.default
```
---

name: inverse
layout: true
class: center, middle, inverse
---
# Practical example
---
layout: false

## Fire up docker based kubernetes - alt 1/2
.left-column[
## registry
] .right-column[
Using a local docker registry is a bit tricky. Following these instructions
for Kind: https://kind.sigs.k8s.io/docs/user/local-registry/

```shell
docker run \
    -d --restart=always -p "127.0.0.1:5001:5000" \
    --network bridge --name "kind-registry" \
    registry:2
```

This will start the registry as a separate docker container. 

**Notice** that it is
started without a backing volume, so a deletion of the docker image will remove 
the images.
]
???
- Kubernetes standard for local registries suggested: 
  https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
---
## Fire up docker based kubernetes - alt 1/2
.left-column[
## registry
## kind
] .right-column[
Create the cluster
```shell
kind create cluster --config kind-api-cluster.yaml --name=neonpandora
```
Test that it runs OK
```shell
kubectl get pods -A
kubectl config get-contexts
```
We want to be able to accommodate the following:
- Flux base system
- Cluster setup
- Creation of tenant within the cluster
]
???
```
kubectl config use-context kind-neonpandora
```
---
## Fire up docker based kubernetes - alt 1/2
.left-column[
## registry
## kind
## enable
] .right-column[
Add registry config to the nodes:
```shell
REGISTRY_DIR="/etc/containerd/certs.d/localhost:5001"
for node in $(kind get nodes --name=neonpandora); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://kind-registry:5000"]
EOF
done
```
Connect network
```shell
docker network connect "kind"  kind-registry
```
]

---
## Fire up docker based kubernetes - alt 1/2
.left-column[
## tbd
## tbd
] .right-column[
[Documentation](https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry):

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:5001"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
```
]

---
## Fire up docker based kubernetes - alt 2/2

TODO Local registry:
- https://github.com/k3d-io/k3d/blob/main/docs/usage/registries.md#using-a-local-registry
- https://github.com/k3d-io/k3d/blob/main/docs/usage/registries.md?plain=1#L115
- https://k3d.io/v5.2.0/usage/registries/#using-k3d-managed-registries

Fire up rancher desktop. We want to use Cilium:
https://docs.cilium.io/en/stable/installation/rancher-desktop/

Do the indicated adjustment in the override file. Then:

```shell
cilium install --version 1.14.5
cilium status --wait
```
Enable hubble with ui component
```shell
cilium hubble enable --ui
```
For the CLI to work, you need a port-forward.
```shell
cilium hubble port-forward
```
```shell
hubble status
hubble observe
```

```shell
cilium hubble ui
```

---
## Create ssh keys for git 1/2

```shell
ssh-keygen -f ~/.ssh/fluxpres -N "" -C "Key used for flux presentation"
```
As the different git repositories represent different access levels, we
would **use different keys** in a real life scenario.

Bootstrapping sshd service, and use the key there:
```shell
pushd dockerimage/sshd/
cp ~/.ssh/fluxpres.pub .
docker build -t neon.local.gd:5001/flux_sshd:v1 .
echo "NOT DOING # docker build -t flux_sshd:v1 ."
which nerdctl > /dev/null && nerdctl --namespace k8s.io build -t flux_sshd:v1 .
```
TODO Streamline use according to rancher or kind.

Kind: Push image to running repository
(TODO Check: May be that the local.gd strategy here does not pan out)
```shell
docker push neon.local.gd:5001/flux_sshd:v1
```

**Legacy:** If using kind, load the image, first:
```shell
kind --name neonpandora load docker-image flux_sshd:v1
```
Start the sshd server, in which we will store our git repos:
```shell
kubectl create ns management
kubectl create -n management -k base/sshd
```
**NB: Check nodeport config for Rancher **

---
## Create ssh keys for git 2/2
There seem to be some trouble with nodeports on rancher, so we have to start a port-forward
session, and keep it open:
```shell
kubectl port-forward -n management svc/sshd 31022:22
```
Alternative is to set up port-forwarding in Rancher GUI.

Test the connection:
```shell
ssh -i ~/.ssh/fluxpres -p 31022 fluxpres@neon.local.gd 
```

???
- keygen note: Modern algorithm, no passphrase
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
- https://medium.com/risan/upgrade-your-ssh-key-to-ed25519-c6e8d60d3c54
- Test key ` ssh -i ~/.ssh/fluxpres fluxpres@sshd `
- Consider ssh-keyscan -H sshd >> ~/.ssh/known_hosts
- Testing repository: git clone ssh://fluxpres@sshd.ssh:/home/en/scrap/flux-system.git
- `ssh-keygen -R "[localhost]:31022"` 
``` 
# Modern type key:
ssh-keygen -t ed25519 -f ~/.ssh/fluxpres -N "" -C "Key used for flux presentation dev on que"
flux bootstrap git --url=ssh://fluxpres@sshd.management:/home/fluxpres/flux-system.git --branch=master --ssh-key-algorithm=ed25519 --private-key-file=$HOME/.ssh/fluxpres
# commit into presentation directory
flux bootstrap github --owner=nostra --repository=gitops-fluxcd2 --branch=master path=/flux-system --personal=true --private=true  
```

---
## ...  and enable GitOps with kustomize
.left-column[
## system
] .right-column[
```shell
ssh -i ~/.ssh/fluxpres -p 31022 fluxpres@neon.local.gd \
     git init --bare git/neonflux.git < /dev/null
```
If you have trouble with the command above, you need:
```
# Edit ~/.ssh/config
Host localhost
  User fluxpres
  IdentityFile ~/.ssh/fluxpres
```
Clone and install flux system

```shell
mkdir -p ~/scrap/work
git clone ssh://fluxpres@neon.local.gd:31022/home/fluxpres/git/neonflux.git ~/scrap/work/neonflux
cp -r flux $HOME/scrap/work/neonflux/.
cp -r base $HOME/scrap/work/neonflux/.
cp .gitignore $HOME/scrap/work/neonflux/.gitignore
```
]
---
## ...  and enable GitOps with kustomize
.left-column[
## system
## flux
] .right-column[
```shell
pushd $HOME/scrap/work/neonflux

flux install \
  --components=source-controller,kustomize-controller,helm-controller,notification-controller \
  --components-extra=image-reflector-controller,image-automation-controller \
  --export > ./flux/system/gotk-components.yaml &&
git add . ; git commit -a -m "Initial commit" ; git push
popd  
```
]
???
- System is the Flux system as such
- https://fluxcd.io/docs/installation/#air-gapped-environments
- https://github.com/fluxcd/flux2-multi-tenancy
- Open as module in IntelliJ
- It may be that flux bootstrap with appropriate flags is a better approach than applying system twice
- If doing "git branch -m main", you need to change flux-system-sync too
---
## ...  and enable GitOps with kustomize
.left-column[
## system
## flux
## secret
] .right-column[
Add ssh key as secret to flux system. 
```shell
pushd ~/scrap/work/neonflux
flux create secret git flux-system \
    --url=ssh://fluxpres@neon.local.gd:31022/home/fluxpres/git/flux-system.git \
    --private-key-file=$HOME/.ssh/fluxpres --namespace=flux-system \
    --export > flux-system-secret.yaml
echo "Correct sshd hostname to what it is inside cluster"
export POD=$( kubectl get pods -n management -l app=sshd -o yaml  | yq '.items[].metadata.name' )
export LINE=$( kubectl exec -t -n management $POD -- ssh-keyscan sshd.management | grep sha2 |  gsed '/./,$!d' )
gsed -i 's|\(known_hosts:\).*|\1 '$LINE'|g' flux-system-secret.yaml
mv flux-system-secret.yaml flux/system/flux-system-secret.yaml
git add .
git commit -a -m "Add secret and sync configurations" && git push
popd
```
**Bootstrap** synchronization of flux-system. 

```shell
kubectl create -k ~/scrap/work/neonflux/flux/system
```

Notice that the secret would be **encrypted with Mozilla SOPS or Sealed Secrets** in a 
real life scenario in order to avoid storing plain-text secrets in git. Or placed in a vault.
]
???
```shell
kubectl -n flux-system get pods --watch
```

---
## Set up a Quarkus project
.left-column[
## initial
] .right-column[

Create a repository for code:
```shell
ssh -i ~/.ssh/fluxpres -p 31022 fluxpres@neon.local.gd \
     git init --bare git/neoncode.git
```
Initial commit
```shell
git clone ssh://fluxpres@neon.local.gd:31022/home/fluxpres/git/neoncode.git $HOME/scrap/work/neoncode
pushd  $HOME/scrap/work/neoncode/
git branch -m main
echo "# Basis for a project" >  README.md
git add README.md
git commit -a -m "Initial commit"
git push 
```
]
---
## Set up a Quarkus project
.left-column[
## initial
## quarkus
] .right-column[
Initialize Quarkus project
```shell
pushd $HOME/scrap/work/neoncode
quarkus create app --dry-run no.scienta:neoncode
quarkus create app no.scienta:neoncode
find neoncode -maxdepth 1 -exec mv {} . \;
rmdir neoncode
quarkus ext add io.quarkus:quarkus-kubernetes
quarkus ext add io.quarkus:quarkus-micrometer-registry-prometheus
quarkus ext add io.quarkus:quarkus-container-image-jib
./mvnw quarkus:add-extension -Dextensions="io.quarkus:quarkus-smallrye-health"
git add .
git commit -a -m "Quarkus project created"
git push
popd
```
Add application properties
```shell
cp quarkus-app.properties $HOME/scrap/work/neoncode/src/main/resources/application.properties
cp .gitignore $HOME/scrap/work/neoncode/.gitignore
pushd $HOME/scrap/work/neoncode
git commit -a -m "Application configration added"
git push
popd
```
]
???
- https://quarkus.io/get-started/
```
sdk install quarkus
```
- examine the properties
---
## Set up a Quarkus project
.left-column[
## initial
## quarkus
## code
] .right-column[
Build and run it locally:
```shell
pushd $HOME/scrap/work/neoncode
quarkus dev
```
Call it:
```shell
curl http://localhost:8080/hello
```
]
???
```shell
pushd $HOME/scrap/work/neoncode
./mvnw clean package
```
---
## Build with tekton...
.left-column[
# key
] .right-column[
The Tekton pipeline needs to be able to pull code from the repository too:
```shell
cd ~/scrap/work/neonflux/
export LINE=$( cat $HOME/.ssh/fluxpres | base64 )
gsed -i 's|\(id_rsa:\).*|\1 '$LINE'|g' flux/tenant/neon-builder/git-credentials.yaml
git commit flux -m "Update credentials"
git push
```
]
---
## Build with tekton...
.left-column[
# key
# elements
] .right-column[

| element     | description                                       |
|-------------|---------------------------------------------------|
| step        | an actual action, for instance compiling the code | 
| task        | collection of steps                               |
| taskrun     | run and execute a task. Useful for debugging      |
| pipeline    | run one or more tasks in sequence                 |
| pipelinerun | execute a pipeline                                |

Annoyingly missing code completion in Intellij, as CRD does not define explanation fields.
Redhat has a plugin which supports Tekton, but it does not play nice with the
existing Kubernetes plugin - at least not in my experience.

Definitions are somewhat verbose, but luckily one does not set up too many different 
types of build pipelines in the same project.

```shell 
kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
```
Then open http://localhost:9097/
]
???
- TODO Fix git credentials 
- SLSA https://tekton.dev/docs/concepts/supply-chain-security/

---
## Build with tekton...
.left-column[
# key
# elements
# webhook
] .right-column[
Creating a [git webhook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks).

Copy the script to the server side hook directory:
```shell
scp -i ~/.ssh/fluxpres -P 31022 post-recieve.sh \
       fluxpres@neon.local.gd:/home/fluxpres/git/neoncode.git/hooks/post-receive
ssh -i  ~/.ssh/fluxpres -p 31022 fluxpres@neon.local.gd \
       chmod a+x /home/fluxpres/git/neoncode.git/hooks/post-receive
```

This will trigger upon change of code. You can also induce manual run with
a Kubernetes definition:
```shell
kubectl create -n neon-builder -f flux/tenant/neon-builder/neon-pipeline-run.yaml 
```
_or_ by calling the trigger endpoint manually:
```shell
kubectl run curl -i --rm --restart=Never --image gcr.io/cloud-builders/curl -- \
    -XPOST -d '{"reponame": "neoncode"}' \
     http://el-neon-listener.neon-builder:8080 
```
]
---
## Build with tekton...
.left-column[
# key
# elements
# webhook
# status
] .right-column[
- https://hub.tekton.dev/tekton/task/maven
```shell
kubectl config set-context --current --namespace=neon-builder
kubectl get pods
```
```shell
tkn pipeline list
```
```shell
tkn pipelinerun list
```
```shell
tkn pipelinerun logs neon-build-run-$HASH
```

```shell
docker pull localhost:5001/scienta/neon:1.0.0-SNAPSHOT
```
]
---
## Build with tekton...
.left-column[
# key
# elements
# webhook
# status
# feeling
] .right-column[
- Tekton is fairly verbose
- As build is done be Kubernetes objects, pipeline runs remains as cruft
]
---
## Build with tekton...
.left-column[
# key
# elements
# webhook
# feeling
# SLSA
] .right-column[
Supply chain security:
https://tekton.dev/docs/getting-started/supply-chain-security/
]
---
## Run application...
.left-column[
# secret
] .right-column[
(Not necessary when using Kind.)
```shell
kubectl create secret docker-registry image-pull-secret \
-n backend \
--docker-server=registry.management.svc.cluster.local:5000 \
--docker-username=testuser \
--docker-password=testpassword \
--docker-email=nobody@dynamicus.org
```
]
???
```
curl -i --user testuser:testpassword https://registry.management.svc.cluster.local:5000/v2/_catalog
curl -i --user testuser:testpassword https://registry.management.svc.cluster.local:5000/v2/scienta/neon/tags/list
curl -i --user testuser:testpassword https://registry.management.svc.cluster.local:5000/v2/scienta/neon/manifests/1.0.0-SNAPSHOT
```
---
## Run application...
.left-column[
# app
] .right-column[
```shell
cd ~/scrap/work/neoncode
mvn clean package
cd target/kubernetes
kustomize create --autodetect .
mkdir -p ~/scrap/work/neonflux/base/neoncode
rm -f ~/scrap/work/neonflux/base/neoncode/*.yaml
kustomize build . -o ~/scrap/work/neonflux/base/neoncode
cd ~/scrap/work/neonflux/base/neoncode
kustomize create --autodetect .
cd ..
git add neoncode
git commit neoncode -m "Add / update neon"
git push
```
]
---
## Run application...
.left-column[
# app
# base
] .right-column[
```shell
kubectl port-forward -n backend svc/neoncode 8080:80
```
- http://localhost:8080/hello
- http://localhost:8080/
]
???
Not needed: Copy registry-cert from management namespace:
```shell
kubectl get secret registry-certs --namespace=management -o yaml |
         kubectl neat|
         yq e '.metadata.namespace = "backend"'|
         kubectl create -f -
```
---
## Metrics
.left-column[
# stack
] .right-column[
- Prometheus
- Grafana

```shell 
kubectl port-forward -n monitoring svc/grafana 3000
```
```shell
kubectl port-forward -n monitoring svc/prometheus-k8s 9090
```
]
---
name: inverse
layout: true
class: center, middle, inverse
---
# Questions?
