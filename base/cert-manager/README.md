# Cert-manager

- https://github.com/cert-manager/cert-manager
- https://cert-manager.io/
- Releases: https://github.com/cert-manager/cert-manager/releases
- If you need to sync secrets over different namespaces: 
  https://cert-manager.io/docs/devops-tips/syncing-secrets-across-namespaces/

```shell
VERSION=1.14.2
curl -L -o cert-manager.yaml https://github.com/cert-manager/cert-manager/releases/download/v$VERSION/cert-manager.yaml
```

**Note** : The cert-manager yaml sets the namespaces itself, which means that you **cannot** override them.