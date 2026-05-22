# planifets-chatbot

Chatbot déployé sur le cluster k8s-cedille-production-v2 via ArgoCD (GitOps).

## Architecture

| Service    | Image                                      | Port |
|------------|--------------------------------------------|------|
| Frontend   | `ghcr.io/applets/planifets-frontend`       | 3000 |
| Backend    | `ghcr.io/applets/planifets-backend`        | 3000 |
| PostgreSQL | CloudNative-PG (CNPG) 17.2                 | 5432 |
| Qdrant     | `qdrant/qdrant`                            | 6333 |

## Environnements

| Env      | Namespace                   | Domaine                                    | Tag image  |
|----------|-----------------------------|--------------------------------------------|------------|
| dev      | `planifets-chatbot-dev`     | `planifets-chatbot.dev.cedille.club`       | `:dev`     |
| staging  | `planifets-chatbot-staging` | `planifets-chatbot.staging.cedille.club`   | `:staging` |
| prod     | `planifets-chatbot`         | `planifets-chatbot.prodv2.cedille.club`    | `:latest`  |

## Structure Kustomize

```
apps/applets/planifets-chatbot/
├── planifets-chatbot.argoapp.yaml   # 3 ArgoCD Applications (dev/staging/prod)
├── base/
│   ├── frontend/                    # Deployment + Service frontend
│   ├── backend/                     # Deployment + Service backend + CNPG cluster + Pooler
│   └── qdrant/                      # StatefulSet + Service Qdrant
├── dev/                             # Overlay: ingress dev, vault secrets dev, patch image :dev
├── staging/                         # Overlay: ingress staging, vault secrets staging, patch image :staging
└── prod/                            # Overlay: ingress prod (2 domaines), vault secrets prod
```

## Gestion des secrets (Vault)

Les secrets sont gérés via **HashiCorp Vault** + l'opérateur `vault-secret`. ArgoCD sync les `VaultSecret` qui créent automatiquement les Kubernetes Secrets dans le namespace.

### Chemins Vault à configurer

#### dev (`planifets-chatbot-dev`)

```
kv/data/planifets-chatbot/dev/planifets-chatbot/planifets-chatbot-backend
  db_url          = postgresql://planifets_chatbot:<password>@planifets-chatbot-pooler-rw:5432/planifets_chatbot
  qdrant_api_key  = <clé API Qdrant>

kv/data/planifets-chatbot/dev/planifets-chatbot/cnpg
  username        = planifets_chatbot
  password        = <mot de passe DB>
```

#### staging (`planifets-chatbot-staging`)

```
kv/data/planifets-chatbot/staging/planifets-chatbot/planifets-chatbot-backend
  db_url          = postgresql://planifets_chatbot:<password>@planifets-chatbot-pooler-rw:5432/planifets_chatbot
  qdrant_api_key  = <clé API Qdrant>

kv/data/planifets-chatbot/staging/planifets-chatbot/cnpg
  username        = planifets_chatbot
  password        = <mot de passe DB>
```

#### prod (`planifets-chatbot`)

```
kv/data/planifets-chatbot/default/planifets-chatbot/planifets-chatbot-backend
  db_url          = postgresql://planifets_chatbot:<password>@planifets-chatbot-pooler-rw:5432/planifets_chatbot
  qdrant_api_key  = <clé API Qdrant>

kv/data/planifets-chatbot/default/planifets-chatbot/cnpg
  username        = planifets_chatbot
  password        = <mot de passe DB>
```

> **Important :** La clé `qdrant_api_key` doit être identique dans le secret backend et configurée sur le StatefulSet Qdrant (`QDRANT__SERVICE__API_KEY`). Le même secret `planifets-chatbot-secret` est monté dans les deux pods.

### Rôle Vault requis

Le rôle `secret-reader` doit être configuré dans Vault pour le service account `default` de chaque namespace. Voir [`apps/vault-gh-roles/`](../../vault-gh-roles/) pour le pattern.

## Procédure de déploiement

### Prérequis

- Accès au cluster (via `kubectl` / Omni)
- Accès à Vault pour créer les secrets
- Images Docker publiées sur GHCR avec les bons tags (`:dev`, `:staging`, `:latest`)

### 1. Configurer les secrets Vault

Créer les chemins Vault listés ci-dessus pour l'environnement cible. Exemple avec la CLI Vault :

```bash
vault kv put kv/planifets-chatbot/dev/planifets-chatbot/cnpg \
  username=planifets_chatbot \
  password=<mot_de_passe_sécurisé>

vault kv put kv/planifets-chatbot/dev/planifets-chatbot/planifets-chatbot-backend \
  db_url="postgresql://planifets_chatbot:<password>@planifets-chatbot-pooler-rw:5432/planifets_chatbot" \
  qdrant_api_key=<clé_api_aléatoire>
```

### 2. Pousser les modifications GitOps

ArgoCD détecte automatiquement les changements sur la branche `HEAD`. Le simple merge d'un PR suffit pour déclencher un déploiement :

```bash
git add apps/applets/planifets-chatbot/
git commit -m "feat: add planifets-chatbot deployment"
git push origin main
```

ArgoCD synchronisera les 3 apps (`planifets-chatbot-dev`, `planifets-chatbot-staging`, `planifets-chatbot`) en vague 2 (`sync-wave: "2"`).

### 3. Vérifier le déploiement

```bash
# Vérifier les pods (remplacer le namespace selon l'environnement)
kubectl get pods -n planifets-chatbot-dev
kubectl get pods -n planifets-chatbot-staging
kubectl get pods -n planifets-chatbot

# Vérifier les secrets créés par vault-secret
kubectl get secrets -n planifets-chatbot-dev

# Vérifier le cluster CNPG
kubectl get cluster -n planifets-chatbot-dev

# Vérifier Qdrant
kubectl get statefulset -n planifets-chatbot-dev
```

### 4. Mise à jour des images (CI/CD)

`argocd-image-updater` surveille GHCR et met à jour automatiquement les digests :

- Push sur la branche `dev` → tag `:dev` → namespace `planifets-chatbot-dev`
- Push sur la branche `staging` → tag `:staging` → namespace `planifets-chatbot-staging`
- Release (tag `:latest`) → namespace `planifets-chatbot`

## Dépannage

```bash
# Logs backend
kubectl logs -n planifets-chatbot-dev deploy/planifets-chatbot-backend

# Logs frontend
kubectl logs -n planifets-chatbot-dev deploy/planifets-chatbot-frontend

# Logs Qdrant
kubectl logs -n planifets-chatbot-dev statefulset/planifets-chatbot-qdrant

# Statut ArgoCD
argocd app get planifets-chatbot-dev
```
