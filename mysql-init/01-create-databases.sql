-- Create databases for both applications
CREATE DATABASE IF NOT EXISTS nawel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS menus CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant privileges to app_user on both databases
GRANT ALL PRIVILEGES ON nawel.* TO 'app_user'@'%';
GRANT ALL PRIVILEGES ON menus.* TO 'app_user'@'%';

FLUSH PRIVILEGES;
