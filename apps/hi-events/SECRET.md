# Gestion du Secret hi-events

Le déploiement nécessite un Secret Kubernetes `hi-events-secret` dans le namespace `hi-events`.
Ce secret ne doit PAS être commis dans Git en clair.

## Valeurs requises

| Clé             | Description                        |
| --------------- | ---------------------------------- |
| `APP_KEY`       | `base64:<openssl rand -base64 32>` |
| `JWT_SECRET`    | `openssl rand -base64 32`          |
| `DB_PASSWORD`   | Mot de passe PostgreSQL            |
| `MAIL_PASSWORD` | Mot de passe SMTP (si applicable)  |

## Option A — Création manuelle (kubectl)

```bash
kubectl create secret generic hi-events-secret \
  --namespace hi-events \
  --from-literal=APP_KEY="base64:$(openssl rand -base64 32)" \
  --from-literal=JWT_SECRET="$(openssl rand -base64 32)" \
  --from-literal=DB_PASSWORD="changeme_secure_password" \
  --from-literal=MAIL_PASSWORD=""
```

## Option B — Sealed Secrets (si installé sur le cluster)

```bash
kubectl create secret generic hi-events-secret \
  --namespace hi-events \
  --from-literal=APP_KEY="..." \
  --from-literal=JWT_SECRET="..." \
  --from-literal=DB_PASSWORD="..." \
  --from-literal=MAIL_PASSWORD="" \
  --dry-run=client -o yaml | \
  kubeseal --format yaml > apps/hi-events/base/sealed-secret.yml
```

Ensuite ajouter `sealed-secret.yml` dans le `kustomization.yml`.
