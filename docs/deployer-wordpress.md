# Deployer un site WordPress pour un club

Cette procedure explique comment creer un nouveau site WordPress pour un club etudiant avec le workflow GitHub du repo `k8s-cedille-production-v2`.

Le workflow genere une pull request avec les manifests Kubernetes du site. Apres le merge, Argo CD deploie automatiquement WordPress, MySQL, les secrets Vault, le certificat TLS et le HTTPProxy Contour.

## Lancer le workflow

Aller dans le repo GitHub `k8s-cedille-production-v2`, puis ouvrir:

```text
Actions > Demander un site web WordPress > Run workflow
```

Remplir les champs principaux:

```text
nom_club: mon-club
domaine: mon-club.prodv2.cedille.club
```

Regles importantes:

- `nom_club` est le slug du club, pas le domaine complet.
- `nom_club` doit contenir seulement des lettres minuscules, des chiffres et des tirets.
- `domaine` est le FQDN complet du site.
- Pour un premier deploiement, garder les images et les tailles de stockage par defaut.

Exemple valide:

```text
nom_club: mon-club
domaine: mon-club.prodv2.cedille.club
```

Exemple invalide:

```text
nom_club: mon-club.prodv2.cedille.club
domaine: mon-club
```

## Verifier la pull request

Le workflow cree une branche du type:

```text
wordpress/mon-club
```

Il ouvre ensuite une pull request avec les fichiers du site:

```text
apps/mon-club/wordpress/prod/configMap.yaml
apps/mon-club/wordpress/prod/ingress.yaml
apps/mon-club/wordpress/prod/kustomization.yaml
apps/mon-club/wordpress/prod/vault-secret.yaml
apps/mon-club/wordpress/mon-club-wordpress.argoapp.yaml
```

Avant de merger, verifier que:

- le domaine est correct;
- le namespace attendu est `<nom_club>-wordpress`;
- l'application Argo CD attendue est `<nom_club>-wordpress`;
- les checks de la pull request passent.

Quand tout est bon, merger la pull request dans `main`.

## Verifier le deploiement Argo CD

Apres le merge, chercher l'application dans Argo CD:

```text
<nom_club>-wordpress
```

Exemple:

```text
mon-club-wordpress
```

Etat attendu:

```text
Sync Status: Synced
Health: Healthy
```

Pendant le premier demarrage, l'application peut rester en `Progressing` quelques minutes.

## Verifier avec kubectl

Exporter le kubeconfig au besoin:

```bash
export KUBECONFIG=~/Downloads/k8s-cedille-production-v2-kubeconfig.yaml
```

Verifier les pods:

```bash
kubectl -n mon-club-wordpress get pods
```

Resultat attendu:

```text
mysql-0                      1/1     Running
wordpress-xxxxxxxxxx-xxxxx   1/1     Running
```

Verifier le HTTPProxy, le certificat TLS et les secrets:

```bash
kubectl -n mon-club-wordpress get httpproxy,certificate,secret
```

Resultat attendu:

```text
httpproxy.projectcontour.io/wordpress   mon-club.prodv2.cedille.club   wordpress-tls   valid
certificate.cert-manager.io/wordpress-tls   True   wordpress-tls
secret/wordpress-secret
secret/wordpress-tls
```

Tester le site:

```bash
curl -I https://mon-club.prodv2.cedille.club
```

Resultat attendu:

```text
HTTP/2 200
```

## Recuperer le mot de passe admin

L'utilisateur WordPress initial est:

```text
admin
```

Recuperer le mot de passe admin genere:

```bash
kubectl -n mon-club-wordpress get secret wordpress-secret \
  -o jsonpath='{.data.WORDPRESS_ADMIN_PASSWORD}' | base64 -d; echo
```

Se connecter ensuite a:

```text
https://mon-club.prodv2.cedille.club/wp-admin
```

Apres la premiere connexion, demander au club de changer le mot de passe admin et de personnaliser le site.

## Debug rapide

Voir les evenements recents:

```bash
kubectl -n mon-club-wordpress get events --sort-by=.lastTimestamp | tail -n 80
```

Decrire le pod MySQL:

```bash
kubectl -n mon-club-wordpress describe pod mysql-0
```

Decrire le pod WordPress:

```bash
kubectl -n mon-club-wordpress describe pod -l app.kubernetes.io/name=wordpress
```

Voir les logs WordPress:

```bash
kubectl -n mon-club-wordpress logs deploy/wordpress
```

Voir les logs de l'initialisation WordPress:

```bash
kubectl -n mon-club-wordpress logs deploy/wordpress -c wordpress-install
```

Voir les logs MySQL:

```bash
kubectl -n mon-club-wordpress logs mysql-0
```

