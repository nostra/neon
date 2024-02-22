# Tekton

- https://tekton.dev/docs/getting-started/
- https://hub.tekton.dev/

Future direction might be to set this up with an operator:
https://github.com/tektoncd/operator/tree/main/docs

Installation of latest:

```bash
curl -o tekton.yaml https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
curl -o tekton-triggers.yaml https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
curl -o tekton-interceptors.yaml https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
curl -o tekton-dashboard.yaml https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
```
(Could use kustomize build -o ... in order to separate up files.)

Dashboard ingress: https://tekton.dev/docs/dashboard/install/#using-an-ingress-rule

```bash
kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
```