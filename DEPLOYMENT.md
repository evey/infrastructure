# Guide de déploiement

Ce guide explique comment déployer les applications Menus et Nawel sur le VPS.

## Prérequis

- Accès SSH ou console web au VPS
- Git configuré sur le VPS
- Docker et Docker Compose installés

## Déploiement automatique

### Utilisation de base

```bash
cd /var/www/apps/infrastructure
./deploy.sh
```

Cette commande va :
1. 📥 Pull les dernières modifications de tous les repos (menus, nawel, infrastructure)
2. 🛑 Arrêter tous les containers
3. ▶️  Redémarrer tous les containers avec les nouveaux changements
4. ✅ Vérifier que tout fonctionne correctement

### Options disponibles

```bash
# Voir l'aide
./deploy.sh --help

# Déployer avec rebuild complet (si changements dans Dockerfile ou dépendances)
./deploy.sh --rebuild

# Déployer uniquement Menus
./deploy.sh --menus-only

# Déployer uniquement Nawel
./deploy.sh --nawel-only

# Combiner les options
./deploy.sh --rebuild --menus-only
```

### Quand utiliser --rebuild ?

Utilisez `--rebuild` quand :
- ✅ Vous avez modifié un `Dockerfile`
- ✅ Vous avez ajouté/modifié des dépendances (package.json, *.csproj)
- ✅ Vous voulez forcer une reconstruction complète

Ne l'utilisez PAS pour :
- ❌ Des changements de code simple (components, services, etc.)
- ❌ Des changements de configuration

## Déploiement manuel

Si vous préférez déployer manuellement :

```bash
# 1. Pull les modifications
cd /var/www/apps/menus
git pull origin master

cd /var/www/apps/nawel
git pull origin master

cd /var/www/apps/infrastructure
git pull origin master

# 2. Rebuild et redémarrer
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml up -d --build

# 3. Vérifier les logs
docker logs -f menus-backend
docker logs -f nawel-backend
```

## Vérification après déploiement

### Vérifier l'état des containers

```bash
docker ps
```

Tous les containers doivent être "Up" :
- shared-mysql (healthy)
- menus-backend
- menus-frontend
- nawel-backend
- nawel-frontend

### Vérifier les logs

```bash
# Logs des backends (migrations)
docker logs menus-backend | grep "migration"
docker logs nawel-backend | grep "migration"

# Logs en temps réel
docker logs -f menus-backend
docker logs -f nawel-backend
```

### Tester les applications

```bash
# Via curl
curl -I https://menus.nironi.com
curl -I https://nawel.nironi.com

# Via navigateur
# Ouvrir https://menus.nironi.com
# Ouvrir https://nawel.nironi.com
```

## Rollback en cas de problème

Si le déploiement cause des problèmes :

```bash
# 1. Revenir à la version précédente dans git
cd /var/www/apps/menus
git log --oneline -5  # Voir les derniers commits
git checkout <commit-hash>  # Revenir à un commit précédent

# 2. Redéployer
cd /var/www/apps/infrastructure
./deploy.sh --rebuild --menus-only
```

## Commandes utiles

### Gestion des containers

```bash
# Voir tous les containers
docker ps -a

# Arrêter tous les containers
docker-compose -f docker-compose.production.yml down

# Redémarrer un container spécifique
docker restart menus-backend

# Voir les logs d'un container
docker logs -f menus-backend

# Exécuter une commande dans un container
docker exec -it menus-backend bash
```

### Gestion de la base de données

```bash
# Se connecter à MySQL
docker exec -it shared-mysql mysql -u root -p

# Backup de la base de données
docker exec shared-mysql mysqldump -u root -p menus > backup-menus.sql
docker exec shared-mysql mysqldump -u root -p nawel > backup-nawel.sql

# Restore
docker exec -i shared-mysql mysql -u root -p menus < backup-menus.sql
```

### Nettoyage

```bash
# Supprimer les images inutilisées
docker image prune -f

# Supprimer les containers arrêtés
docker container prune -f

# Nettoyage complet (attention: supprime aussi les volumes!)
docker system prune -a --volumes
```

## Monitoring

### Vérifier l'utilisation des ressources

```bash
# CPU et mémoire des containers
docker stats

# Espace disque
df -h

# Logs système
journalctl -u nginx -f
```

### Certificats SSL

Les certificats Let's Encrypt sont renouvelés automatiquement par Certbot.

Pour vérifier :

```bash
# Voir les certificats
certbot certificates

# Tester le renouvellement
certbot renew --dry-run

# Renouveler manuellement si nécessaire
certbot renew
```

## Troubleshooting

### Les containers ne démarrent pas

```bash
# Vérifier les logs
docker-compose -f docker-compose.production.yml logs

# Vérifier l'espace disque
df -h

# Redémarrer Docker
systemctl restart docker
```

### Les migrations ne s'exécutent pas

```bash
# Voir les logs du backend
docker logs menus-backend | grep -i "migration\|error"

# Redémarrer le backend
docker restart menus-backend
```

### Problème de connexion à la base de données

```bash
# Vérifier que MySQL est démarré et healthy
docker ps | grep mysql

# Vérifier les logs MySQL
docker logs shared-mysql

# Tester la connexion
docker exec -it shared-mysql mysql -u app_user -p -e "SELECT 1;"
```

### Site inaccessible

```bash
# Vérifier Nginx
systemctl status nginx
nginx -t

# Vérifier les containers frontend
docker logs menus-frontend
docker logs nawel-frontend

# Vérifier les ports
netstat -tlnp | grep :80
netstat -tlnp | grep :443
```

## Support

Pour toute question ou problème, vérifiez :
1. Les logs des containers
2. L'état des containers avec `docker ps`
3. Les logs Nginx avec `journalctl -u nginx`
4. L'espace disque avec `df -h`
