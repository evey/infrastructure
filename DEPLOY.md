# Guide de déploiement - Nawel & Menus

## Architecture

```
VPS (Ubuntu 22.04 - Hetzner CX33)
├─ MySQL 8.0 (instance partagée)
│  ├─ Database: nawel
│  └─ Database: menus
├─ Nginx (reverse proxy)
│  ├─ nawel.nironi.com → nawel-frontend:80
│  ├─ nawel.nironi.com/api → nawel-backend:5000
│  ├─ menus.nironi.com → menus-frontend:80
│  └─ menus.nironi.com/api → menus-backend:5001
└─ Docker Compose
   ├─ nawel-backend (ASP.NET Core 9.0)
   ├─ nawel-frontend (React + Nginx)
   ├─ menus-backend (ASP.NET Core 9.0)
   └─ menus-frontend (React + Nginx)
```

## Prérequis sur le VPS

1. **Docker & Docker Compose** installés
2. **Git** installé
3. **Nginx** installé et configuré comme reverse proxy
4. **Certbot** pour SSL
5. **DNS** configuré (A records pointant vers le VPS)

## Installation initiale sur le VPS

### 1. Installation de Docker

```bash
# Mettre à jour le système
apt update && apt upgrade -y

# Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Installer Docker Compose
apt install -y docker-compose-plugin

# Vérifier l'installation
docker --version
docker compose version
```

### 2. Cloner les projets

```bash
cd /var/www
mkdir apps && cd apps

# Cloner Nawel
git clone https://github.com/VOTRE_REPO/nawel.git

# Cloner Menus
git clone https://github.com/VOTRE_REPO/menus.git

# Copier les fichiers de déploiement
cd /var/www/apps
# Copier docker-compose.production.yml
# Copier deploy.sh
# Copier mysql-init/
```

### 3. Configuration des variables d'environnement

```bash
cd /var/www/apps

# Créer le fichier .env
cp .env.example .env
nano .env

# Générer des secrets sécurisés
openssl rand -base64 48  # Pour MYSQL_ROOT_PASSWORD
openssl rand -base64 48  # Pour MYSQL_USER_PASSWORD
openssl rand -base64 48  # Pour NAWEL_JWT_SECRET
openssl rand -base64 48  # Pour MENUS_JWT_SECRET
```

### 4. Lancer les applications

```bash
cd /var/www/apps

# Rendre le script exécutable
chmod +x deploy.sh

# Premier déploiement (construit et lance tout)
docker compose -f docker-compose.production.yml up -d --build

# Vérifier que tout tourne
docker compose -f docker-compose.production.yml ps
docker compose -f docker-compose.production.yml logs -f
```

### 5. Appliquer les migrations de base de données

```bash
# Nawel
docker exec -it nawel-backend dotnet ef database update

# Menus
docker exec -it menus-backend dotnet ef database update
```

## Configuration Nginx

### Fichier: `/etc/nginx/sites-available/nawel`

```nginx
server {
    listen 80;
    server_name nawel.nironi.com;

    # Redirect HTTP to HTTPS (après installation SSL)
    # return 301 https://$server_name$request_uri;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Fichier: `/etc/nginx/sites-available/menus`

```nginx
server {
    listen 80;
    server_name menus.nironi.com;

    # Redirect HTTP to HTTPS (après installation SSL)
    # return 301 https://$server_name$request_uri;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Activer les sites

```bash
# Créer les liens symboliques
ln -s /etc/nginx/sites-available/nawel /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/menus /etc/nginx/sites-enabled/

# Tester la configuration
nginx -t

# Redémarrer Nginx
systemctl restart nginx
```

## Configuration SSL avec Certbot

```bash
# Installer Certbot
apt install -y certbot python3-certbot-nginx

# Obtenir les certificats SSL
certbot --nginx -d nawel.nironi.com
certbot --nginx -d menus.nironi.com

# Renouvellement automatique (déjà configuré par Certbot)
certbot renew --dry-run
```

## Configuration DNS

Chez votre registrar (actuellement ifastnet), ajoutez ces enregistrements :

```
Type: A
Host: nawel
Value: 65.21.52.61
TTL: 3600

Type: A
Host: menus
Value: 65.21.52.61
TTL: 3600
```

## Déploiements ultérieurs

### Déployer une seule application

```bash
cd /var/www/apps

# Déployer uniquement Nawel
./deploy.sh nawel

# Déployer uniquement Menus
./deploy.sh menus

# Déployer les deux
./deploy.sh all
```

### Voir les logs

```bash
# Tous les conteneurs
docker compose -f docker-compose.production.yml logs -f

# Un conteneur spécifique
docker compose -f docker-compose.production.yml logs -f nawel-backend
docker compose -f docker-compose.production.yml logs -f menus-frontend
```

### Redémarrer un service

```bash
docker compose -f docker-compose.production.yml restart nawel-backend
docker compose -f docker-compose.production.yml restart menus-frontend
```

### Sauvegardes MySQL

```bash
# Créer une sauvegarde
docker exec shared-mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} nawel > backup_nawel_$(date +%Y%m%d).sql
docker exec shared-mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} menus > backup_menus_$(date +%Y%m%d).sql

# Automatiser les sauvegardes (crontab)
0 2 * * * /var/www/apps/backup.sh
```

## Monitoring

```bash
# Voir l'utilisation des ressources
docker stats

# Voir les conteneurs actifs
docker ps

# Voir l'espace disque
docker system df

# Nettoyer les ressources inutilisées
docker system prune -a
```

## Troubleshooting

### Problème de connexion MySQL

```bash
# Se connecter au conteneur MySQL
docker exec -it shared-mysql mysql -u root -p

# Vérifier les bases de données
SHOW DATABASES;
USE nawel;
SHOW TABLES;
```

### Problème de build Docker

```bash
# Reconstruire sans cache
docker compose -f docker-compose.production.yml build --no-cache

# Voir les logs de build
docker compose -f docker-compose.production.yml up --build
```

### Espace disque plein

```bash
# Nettoyer les images non utilisées
docker image prune -a -f

# Nettoyer les volumes non utilisés
docker volume prune -f

# Nettoyer tout
docker system prune -a --volumes -f
```

## Sécurité

- ✅ Firewall UFW activé (ports 22, 80, 443)
- ✅ Firewall Hetzner activé
- ✅ SSH avec clé uniquement (pas de password)
- ✅ SSL/TLS avec Let's Encrypt
- ✅ Mots de passe MySQL sécurisés
- ✅ JWT secrets uniques par application
- ⚠️ TODO: Fail2ban pour SSH
- ⚠️ TODO: Monitoring avec Grafana/Prometheus
