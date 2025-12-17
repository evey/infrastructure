# Nginx Configuration

Ces fichiers de configuration Nginx servent de reverse proxy pour les applications Menus et Nawel.

## Installation sur le VPS

```bash
# Copier les fichiers de config
sudo cp /root/repos/infrastructure/nginx/*.conf /etc/nginx/sites-available/

# Activer les sites
sudo ln -sf /etc/nginx/sites-available/menus.nironi.com.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/nawel.nironi.com.conf /etc/nginx/sites-enabled/

# Tester la configuration
sudo nginx -t

# Redémarrer Nginx
sudo systemctl restart nginx

# Vérifier le status
sudo systemctl status nginx
```

## Structure

- `menus.nironi.com.conf` : Configuration pour l'application Menus
  - Frontend: port 3001
  - Backend API: port 5001

- `nawel.nironi.com.conf` : Configuration pour l'application Nawel
  - Frontend: port 3000
  - Backend API: port 5000

## SSL/HTTPS

Après avoir configuré les DNS, utiliser Certbot pour obtenir des certificats SSL :

```bash
sudo certbot --nginx -d menus.nironi.com -d nawel.nironi.com
```

Certbot modifiera automatiquement les fichiers de config pour ajouter HTTPS.
