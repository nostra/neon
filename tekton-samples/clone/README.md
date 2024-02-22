# Pipeline for checking out code

https://tekton.dev/docs/how-to-guides/clone-repository/#run-the-pipeline

```shell
curl -o git-clone-task.yaml https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.6/git-clone.yaml
```


```shell
tkn pipelinerun list
tkn pipelinerun logs clone-read-run-$HASH
tkn hub check-upgrade task
```

To clean up:
```shell
kubectl get pipelineruns.tekton.dev --no-headers|cut -f1 -d ' '|xargs kubectl delete pipelinerun
```