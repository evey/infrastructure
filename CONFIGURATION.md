# Guide de configuration des variables d'environnement

Ce guide explique comment configurer les variables d'environnement pour les applications sur le VPS.

## 📍 Emplacement du fichier .env

Sur le VPS, le fichier `.env` se trouve dans :
```
/var/www/apps/infrastructure/.env
```

## 🔧 Configuration initiale

### 1. Créer le fichier .env

```bash
cd /var/www/apps/infrastructure
cp .env.example .env
nano .env  # ou vim .env
```

### 2. Variables obligatoires

Ces variables **doivent** être configurées pour que les applications fonctionnent :

```bash
# MySQL - Utilisez des mots de passe forts !
MYSQL_ROOT_PASSWORD=votre_mot_de_passe_root_securise
MYSQL_USER_PASSWORD=votre_mot_de_passe_user_securise

# JWT Secrets - Générez des clés aléatoires de 32+ caractères
NAWEL_JWT_SECRET=cle_secrete_aleatoire_min_32_caracteres_nawel
MENUS_JWT_SECRET=cle_secrete_aleatoire_min_32_caracteres_menus
```

**💡 Astuce :** Pour générer des secrets sécurisés :
```bash
# Générer une clé aléatoire de 64 caractères
openssl rand -base64 64 | tr -d '\n' && echo
```

### 3. Variables optionnelles pour Nawel

#### OpenGraph API (extraction d'infos produits)

Pour utiliser la fonctionnalité d'extraction automatique d'informations produits depuis des URLs :

```bash
# Obtenir une clé API gratuite sur https://www.opengraph.io/
OPENGRAPH_API_KEY=votre-cle-api-opengraph
```

**Sans cette clé :** La fonctionnalité d'extraction automatique ne fonctionnera pas, mais l'app reste fonctionnelle.

#### Configuration Email (notifications)

Pour envoyer des emails (invitations, notifications) :

```bash
# Activer l'envoi d'emails
EMAIL_ENABLED=true

# Configuration SMTP (exemple avec Gmail)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=votre-email@gmail.com
SMTP_PASSWORD=votre-mot-de-passe-application
SMTP_FROM_EMAIL=noreply@nawel.nironi.com
SMTP_FROM_NAME=Nawel - Listes de Noël
SMTP_USE_SSL=true
```

**Notes :**
- Pour Gmail, utilisez un "Mot de passe d'application" (pas votre mot de passe habituel)
- Vous pouvez aussi utiliser d'autres fournisseurs SMTP (SendGrid, Mailgun, etc.)
- **Sans cette configuration :** Les emails ne seront pas envoyés, mais l'app reste fonctionnelle

## 📝 Exemple de fichier .env complet

```bash
# ========================================
# MySQL Configuration (OBLIGATOIRE)
# ========================================
MYSQL_ROOT_PASSWORD=P@ssw0rd!Secure123Root
MYSQL_USER_PASSWORD=P@ssw0rd!Secure123User

# ========================================
# JWT Secrets (OBLIGATOIRE)
# ========================================
NAWEL_JWT_SECRET=nawel_super_secret_jwt_key_minimum_32_chars_abc123xyz789
MENUS_JWT_SECRET=menus_super_secret_jwt_key_minimum_32_chars_def456uvw012

# ========================================
# Nawel - OpenGraph API (OPTIONNEL)
# ========================================
OPENGRAPH_API_KEY=abc123def456

# ========================================
# Nawel - Email (OPTIONNEL)
# ========================================
EMAIL_ENABLED=true
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=votre-email@gmail.com
SMTP_PASSWORD=votre-mot-de-passe-app
SMTP_FROM_EMAIL=noreply@nawel.nironi.com
SMTP_FROM_NAME=Nawel - Listes de Noël
SMTP_USE_SSL=true
```

## 🔄 Appliquer les modifications

Après avoir modifié le fichier `.env`, redéployez les applications :

```bash
cd /var/www/apps/infrastructure

# Pour appliquer les changements à Nawel uniquement
./deploy.sh --rebuild --nawel-only

# Pour appliquer à toutes les apps
./deploy.sh --rebuild
```

**Important :** Vous **devez** utiliser `--rebuild` pour que les nouvelles variables d'environnement soient prises en compte.

## 🔒 Sécurité

**⚠️ Important :**
- Ne **JAMAIS** commiter le fichier `.env` dans git
- Le `.env` est dans le `.gitignore`
- Utilisez des mots de passe **forts et uniques**
- Changez les secrets JWT régulièrement
- Restreignez l'accès au fichier `.env` :
  ```bash
  chmod 600 /var/www/apps/infrastructure/.env
  ```

## 🧪 Vérifier la configuration

### Vérifier que les variables sont bien passées au container

```bash
# Pour Nawel
docker exec nawel-backend env | grep -E "OPENGRAPH|EMAIL|SMTP"

# Pour Menus
docker exec menus-backend env | grep JWT
```

### Vérifier les logs au démarrage

```bash
# Logs Nawel
docker logs nawel-backend | head -50

# Logs Menus
docker logs menus-backend | head -50
```

Recherchez des messages d'erreur liés à la configuration.

## ❓ FAQ

### Comment changer une variable d'environnement ?

1. Modifier le fichier `.env` sur le VPS
2. Redéployer : `./deploy.sh --rebuild`

### Les variables optionnelles sont-elles nécessaires ?

Non, elles ont des valeurs par défaut. L'application fonctionnera sans elles, mais certaines fonctionnalités seront désactivées :
- Sans `OPENGRAPH_API_KEY` : pas d'extraction auto d'infos produits
- Sans config email : pas d'envoi d'emails

### Comment obtenir une clé OpenGraph ?

1. Aller sur https://www.opengraph.io/
2. S'inscrire (plan gratuit disponible)
3. Copier la clé API
4. L'ajouter dans le `.env`

### Puis-je utiliser un autre service SMTP ?

Oui ! Configurez simplement les paramètres de votre fournisseur SMTP :
- **SendGrid** : smtp.sendgrid.net:587
- **Mailgun** : smtp.mailgun.org:587
- **Office365** : smtp.office365.com:587
- etc.

## 📚 Ressources

- [Configuration JWT ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/security/authentication/jwt)
- [OpenGraph API Documentation](https://www.opengraph.io/documentation/)
- [Configuration SMTP Gmail](https://support.google.com/mail/answer/7126229)
