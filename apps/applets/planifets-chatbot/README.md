# planifets-chatbot

Applet GitOps pour le composant `planifets-chatbot` déployé sur le cluster `k8s-cedille-production-v2` via ArgoCD.

Ce dossier ne contient plus une stack frontend/backend complète : il gère uniquement le service **Qdrant** utilisé par le chatbot, avec les secrets associés par environnement.

## Ce qui est déployé

| Composant | Image | Port | Rôle |
|-----------|-------|------|------|
| Qdrant | `qdrant/qdrant:latest` | `6333` / `6334` | Base vectorielle du chatbot |

## Environnements

| Env | Namespace | ArgoCD Application | Secret Vault |
|-----|-----------|--------------------|--------------|
| dev | `planifets-chatbot-dev` | `planifets-chatbot-dev` | `kv/data/planifets-chatbot/dev/planifets-chatbot/qdrant` |
| staging | `planifets-chatbot-staging` | `planifets-chatbot-staging` | `kv/data/planifets-chatbot/staging/planifets-chatbot/qdrant` |
| prod | `planifets-chatbot` | `planifets-chatbot` | `kv/data/planifets-chatbot/default/planifets-chatbot/qdrant` |

## Structure actuelle

```text
apps/applets/planifets-chatbot/
├── planifets-chatbot.argoapp.yaml   # 3 Applications ArgoCD : dev, staging, prod
├── base/
│   └── qdrant/
│       ├── service.yaml             # Service ClusterIP (6333/6334)
│       └── statefulset.yaml         # StatefulSet Qdrant + PVC
├── dev/
│   ├── kustomization.yaml           # Base qdrant + secret Vault dev
│   └── vault-secret.yaml
├── staging/
│   ├── kustomization.yaml           # Base qdrant + secret Vault staging
│   └── vault-secret.yaml
└── prod/
    ├── kustomization.yaml           # Base qdrant + secret Vault prod
    └── vault-secret.yaml
```

## Secrets Vault

Les secrets sont gérés via **HashiCorp Vault** et l'opérateur `vault-secret`.

Chaque environnement crée un secret Kubernetes `planifets-chatbot-secret` contenant la clé `qdrant_api_key`, lue par le StatefulSet via `QDRANT__SERVICE__API_KEY`.

### Chemins Vault attendus

- `dev` → `kv/data/planifets-chatbot/dev/planifets-chatbot/qdrant`
- `staging` → `kv/data/planifets-chatbot/staging/planifets-chatbot/qdrant`
- `prod` → `kv/data/planifets-chatbot/default/planifets-chatbot/qdrant`

## Déploiement

1. Créer ou mettre à jour la valeur `api_key` dans le chemin Vault de l'environnement visé.
2. Laisser ArgoCD synchroniser l'application correspondante.
3. Vérifier que le secret `planifets-chatbot-secret` et le StatefulSet Qdrant sont bien présents dans le namespace.

### Vérifications utiles

```bash
kubectl get pods -n planifets-chatbot-dev
kubectl get pods -n planifets-chatbot-staging
kubectl get pods -n planifets-chatbot

kubectl get secret -n planifets-chatbot-dev planifets-chatbot-secret
kubectl get statefulset -n planifets-chatbot-dev planifets-chatbot-qdrant
kubectl get svc -n planifets-chatbot-dev planifets-chatbot-qdrant
```

## Notes

- Le stockage persistant Qdrant utilise un `volumeClaimTemplate` de `5Gi` avec `storageClassName: cephfs`.
- Le service expose les ports `6333` (HTTP) et `6334` (gRPC).
- Les trois overlays (`dev`, `staging`, `prod`) réutilisent la base `qdrant` et ne diffèrent que par leur secret Vault.