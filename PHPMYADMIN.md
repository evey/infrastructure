# Guide d'installation phpMyAdmin

Ce guide explique comment installer et configurer phpMyAdmin pour gérer les bases de données MySQL.

## 📋 Prérequis

- Docker et Docker Compose installés
- Accès DNS pour créer un sous-domaine

## 🚀 Installation

### Étape 1 : Configurer le DNS

Ajouter un enregistrement DNS chez ifastnet :

```
Type: A
Host: db
Value: 65.21.52.61
TTL: 3600 (ou Auto)
```

**Résultat :** `db.nironi.com` pointera vers votre VPS.

**Vérifier la propagation :**
```bash
nslookup db.nironi.com
```

### Étape 2 : Déployer sur le VPS

Les fichiers sont déjà configurés dans le repo. Sur le VPS :

```bash
# 1. Pull les modifications
cd /var/www/apps/infrastructure
git pull origin master

# 2. Copier la config Nginx
cp /var/www/apps/infrastructure/nginx/db.nironi.com.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/db.nironi.com.conf /etc/nginx/sites-enabled/

# 3. Tester la config Nginx
nginx -t

# 4. Recharger Nginx
systemctl reload nginx

# 5. Démarrer phpMyAdmin
docker-compose -f docker-compose.production.yml up -d phpmyadmin

# 6. Vérifier que le container tourne
docker ps | grep phpmyadmin
```

### Étape 3 : Configurer SSL

```bash
# Obtenir un certificat SSL pour db.nironi.com
certbot --nginx -d db.nironi.com

# Certbot configurera automatiquement HTTPS
```

### Étape 4 : Accéder à phpMyAdmin

Ouvrir dans un navigateur : **https://db.nironi.com**

**Identifiants :**
- **Serveur :** mysql (laissez par défaut)
- **Utilisateur :**
  - `root` (mot de passe : `MYSQL_ROOT_PASSWORD` du .env)
  - ou `app_user` (mot de passe : `MYSQL_USER_PASSWORD` du .env)
- **Bases de données disponibles :**
  - `menus`
  - `nawel`

## 🔒 Sécurité

### Option 1 : Restriction par IP (Recommandé)

Pour limiter l'accès à phpMyAdmin uniquement depuis votre IP :

1. **Trouver votre IP publique :**
```bash
curl ifconfig.me
```

2. **Modifier la config Nginx :**
```bash
nano /etc/nginx/sites-available/db.nironi.com.conf
```

3. **Décommenter et modifier les lignes :**
```nginx
# Remplacer VOTRE_IP_PUBLIQUE par votre vraie IP
allow 123.456.789.012;  # Votre IP
deny all;
```

4. **Recharger Nginx :**
```bash
nginx -t
systemctl reload nginx
```

### Option 2 : Authentification HTTP Basic

Ajouter une couche d'authentification HTTP :

```bash
# 1. Installer htpasswd
apt install apache2-utils -y

# 2. Créer un fichier de mots de passe
htpasswd -c /etc/nginx/.htpasswd admin

# 3. Modifier la config Nginx
nano /etc/nginx/sites-available/db.nironi.com.conf
```

Ajouter dans le bloc `location /` :
```nginx
auth_basic "Database Administration";
auth_basic_user_file /etc/nginx/.htpasswd;
```

```bash
# 4. Recharger Nginx
nginx -t
systemctl reload nginx
```

### Option 3 : Les deux (Maximum de sécurité)

Combiner restriction IP + authentification HTTP.

## 🛠️ Gestion

### Voir les logs

```bash
docker logs phpmyadmin
docker logs -f phpmyadmin  # En temps réel
```

### Redémarrer phpMyAdmin

```bash
docker restart phpmyadmin
```

### Arrêter phpMyAdmin

```bash
docker-compose -f /var/www/apps/infrastructure/docker-compose.production.yml stop phpmyadmin
```

### Démarrer phpMyAdmin

```bash
docker-compose -f /var/www/apps/infrastructure/docker-compose.production.yml start phpmyadmin
```

### Désinstaller phpMyAdmin

```bash
# Arrêter et supprimer le container
docker-compose -f /var/www/apps/infrastructure/docker-compose.production.yml down phpmyadmin

# Supprimer l'image
docker rmi phpmyadmin:latest

# Supprimer la config Nginx
rm /etc/nginx/sites-enabled/db.nironi.com.conf
rm /etc/nginx/sites-available/db.nironi.com.conf
systemctl reload nginx

# Supprimer l'enregistrement DNS chez ifastnet
```

## 🔍 Fonctionnalités phpMyAdmin

- ✅ Gérer les bases de données (créer, supprimer, modifier)
- ✅ Exécuter des requêtes SQL
- ✅ Importer/Exporter des données (SQL, CSV, Excel)
- ✅ Gérer les utilisateurs et permissions
- ✅ Visualiser la structure des tables
- ✅ Éditer les données directement
- ✅ Créer des index et optimiser les tables

## ❓ Troubleshooting

### phpMyAdmin ne démarre pas

```bash
# Vérifier les logs
docker logs phpmyadmin

# Vérifier que MySQL est bien démarré
docker ps | grep mysql

# Redémarrer
docker restart phpmyadmin
```

### Impossible de se connecter

1. Vérifier que vous utilisez les bons identifiants (ceux du `.env`)
2. Vérifier que le container MySQL est accessible :
```bash
docker exec -it phpmyadmin ping mysql
```

### Page blanche ou erreur 502

```bash
# Vérifier que le port 8080 est libre
netstat -tlnp | grep 8080

# Vérifier les logs Nginx
journalctl -u nginx -f
```

### Erreur "Maximum execution time exceeded"

Augmenter les limites dans le docker-compose :
```yaml
environment:
  - MAX_EXECUTION_TIME=600
  - MEMORY_LIMIT=512M
```

Puis redémarrer :
```bash
docker-compose -f docker-compose.production.yml restart phpmyadmin
```

## 🌐 Alternative : Adminer

Si vous préférez une interface plus légère :

```yaml
adminer:
  image: adminer:latest
  container_name: adminer
  restart: always
  ports:
    - "8080:8080"
  depends_on:
    - mysql
  networks:
    - apps-network
```

Adminer est plus léger que phpMyAdmin mais offre moins de fonctionnalités.

## 📊 Conseils d'utilisation

### Backup régulier

Dans phpMyAdmin :
1. Sélectionner la base de données (menus ou nawel)
2. Onglet "Exporter"
3. Méthode : "Rapide" ou "Personnalisé"
4. Format : SQL
5. Télécharger

### Optimisation des tables

1. Sélectionner la base de données
2. Cocher toutes les tables
3. Dans "Pour la sélection" → Choisir "Optimiser la table"

### Requêtes SQL courantes

**Voir la taille des bases :**
```sql
SELECT
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
WHERE table_schema IN ('menus', 'nawel')
GROUP BY table_schema;
```

**Voir les utilisateurs :**
```sql
SELECT user, host FROM mysql.user;
```

**Lister les tables d'une base :**
```sql
SHOW TABLES FROM menus;
```
