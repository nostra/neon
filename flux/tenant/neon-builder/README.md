# Pipeline for checking out code

https://tekton.dev/docs/how-to-guides/clone-repository/#run-the-pipeline

- https://hub.tekton.dev/tekton/task/jib-maven
- https://hub.tekton.dev/tekton/task/maven
- https://hub.tekton.dev/tekton/task/git-clone

```shell
curl -o jib-maven-task.yaml https://api.hub.tekton.dev/v1/resource/tekton/task/jib-maven/0.5/raw
curl -o maven-task.yaml https://api.hub.tekton.dev/v1/resource/tekton/task/maven/0.3/raw
```

Note that git-clone task is inherently outdated, but cannot upgrade due to
https://github.com/tektoncd/catalog/issues/1220

## Fix credentials that are hard coded. Need to import upon creation

TODO Need to make this dynamic

```shell
export LINE=$( cat $HOME/.ssh/fluxpres | base64 )
gsed -i 's|\(id_rsa:\).*|\1 '$LINE'|g' git-credentials.yaml
```

# Usage

```shell
tkn pipelinerun list
tkn pipelinerun logs neon-build-run-$HASH
tkn hub check-upgrade task
```

To clean up:
```shell
kubectl get pipelineruns.tekton.dev --no-headers|cut -f1 -d ' '|xargs kubectl delete pipelinerun
```


## Debug

```shell
kubectl port-forward -n neon-builder svc/el-neon-listener 8080
```

```shell
curl -v \
-H 'content-Type: application/json' \
-d '{"reponame": "neoncode"}' \
http://localhost:8080
```