#!/bin/bash

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Prompt for domain and database password
read -p "Enter your domain name or IP address for Paymenter: " DOMAIN
read -s -p "Enter the database password for Paymenter: " DB_PASSWORD
echo

# Update system and install basic dependencies
echo "Updating system and installing dependencies..."
apt update -y && apt upgrade -y
apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg

# Install PHP, MySQL, and other required packages
echo "Adding PHP and MySQL repositories..."
add-apt-repository -y ppa:ondrej/php
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version="mariadb-10.11"
apt update

echo "Installing PHP, MySQL, and necessary extensions..."
DEBIAN_FRONTEND=noninteractive apt install -y php8.2 php8.2-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server

# Start and secure MySQL
echo "Configuring MySQL..."
systemctl start mariadb
mysql_secure_installation <<EOF

Y
$DB_PASSWORD
$DB_PASSWORD
Y
Y
Y
Y
EOF

# Setup Paymenter Database and User
echo "Setting up Paymenter database..."
mysql -u root -p"$DB_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS paymenter;
CREATE USER IF NOT EXISTS 'paymenter'@'127.0.0.1' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON paymenter.* TO 'paymenter'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Download Paymenter
echo "Downloading Paymenter..."
mkdir -p /var/www/paymenter
cd /var/www/paymenter
curl -Lo paymenter.tar.gz https://github.com/paymenter/paymenter/releases/latest/download/paymenter.tar.gz
tar -xzvf paymenter.tar.gz
chmod -R 750 storage/* bootstrap/cache/

# Configure Nginx for Paymenter
echo "Configuring Nginx..."
cat <<EOF > /etc/nginx/sites-available/paymenter.conf
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root /var/www/paymenter/public;
    index index.php;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }
}
EOF

ln -s /etc/nginx/sites-available/paymenter.conf /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# Prompt for SSL setup
read -p "Do you want to install SSL for your domain? (Y/N): " SSL_CHOICE
if [[ "$SSL_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Installing Certbot and setting up SSL..."
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d "$DOMAIN"
fi

# Install Paymenter dependencies and set environment
echo "Setting up Paymenter..."
cd /var/www/paymenter
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate --force
php artisan storage:link

# Configure .env file with database credentials
sed -i "s/DB_DATABASE=.*/DB_DATABASE=paymenter/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=paymenter/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env

# Run migrations
php artisan migrate --force --seed

# Set permissions
chown -R www-data:www-data /var/www/paymenter

# Configure cron job for Paymenter
echo "Setting up cron job..."
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/paymenter/artisan schedule:run >> /dev/null 2>&1") | crontab -

# Create systemd service for queue worker
echo "Setting up queue worker as a systemd service..."
cat <<EOF > /etc/systemd/system/paymenter.service
[Unit]
Description=Paymenter Queue Worker
After=network.target

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/paymenter/artisan queue:work
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now paymenter.service

# Create initial Paymenter user
php artisan p:user:create

echo "Installation complete! Access Paymenter at http://$DOMAIN or https://$DOMAIN if SSL was enabled."
