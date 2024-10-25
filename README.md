# Paymenter Installation Script for Ubuntu 24

This repository provides a fully automated Bash script to install **Paymenter** on an Ubuntu 24 server. The script installs all necessary dependencies, configures the database, sets up Nginx, and optionally enables SSL using Certbot.

## Features

- Installs PHP, MySQL, Nginx, Redis, and other dependencies
- Configures MySQL for Paymenter with secure user and password setup
- Automatically sets up an Nginx configuration for Paymenter
- Optional SSL installation using Certbot for HTTPS
- Sets up necessary cron jobs and systemd services for optimal operation
- Creates the first admin user for Paymenter during setup

## Prerequisites

- **Ubuntu 24 Server**
  - A fresh installation is recommended for best compatibility.
- **Domain Name (Optional)**
  - A domain is required if you choose to enable SSL.
- **Root Privileges**
  - The script requires sudo or root access to install packages and configure services.

## Usage

### 1. Download the Script

Clone this repository or manually download the installation script:

```bash
git clone https://github.com/billfoo/paymenter-install.git
cd paymenter-install
```

### 2. Run the Script

Make the script executable and run it with sudo:

```bash
chmod +x install.sh
sudo ./install.sh
```

### 3. Follow the Prompts

The script will prompt you for:

- **Domain Name**: This will configure Nginx for your domain or IP address.
- **Database Password**: The password you want to set for the Paymenter database user.
- **SSL Option**: Whether to install SSL with Certbot for HTTPS access.

### 4. Access Paymenter

After the installation completes, access Paymenter in a web browser at:

- `http://your_domain_or_ip` (without SSL)
- `https://your_domain` (if SSL is enabled)

## Script Walkthrough

This script performs the following actions:

1. **Updates and Installs System Dependencies**
   - Installs PHP 8.2, MySQL, Redis, Nginx, and necessary PHP extensions.
   
2. **Configures MySQL**
   - Sets up a `paymenter` database and user, securing MySQL with the provided password.

3. **Downloads Paymenter and Configures Nginx**
   - Downloads the latest version of Paymenter, sets up directory permissions, and configures an Nginx server block.

4. **Optional SSL Setup**
   - If selected, installs SSL using Certbot and configures Nginx for HTTPS.

5. **Environment and Migrations**
   - Sets up `.env` with your database credentials, runs database migrations, and seeds initial data.

6. **Cron Job and Queue Worker**
   - Configures a cron job for scheduled tasks and sets up a systemd service for the queue worker.

## Example Output

Upon successful completion, you’ll see:

```
Paymenter installation complete! Access Paymenter at http://your_domain_or_ip or https://your_domain if SSL was enabled.
```

## Troubleshooting

1. **Firewall**:
   - Ensure HTTP and HTTPS traffic are allowed through the firewall:
     ```bash
     sudo ufw allow 'Nginx Full'
     ```

2. **Service Status**:
   - If you encounter issues, check the status of relevant services:
     ```bash
     sudo systemctl status nginx
     sudo systemctl status mariadb
     sudo systemctl status paymenter.service
     ```

3. **Error in Nginx Configuration**:
   - The script tests the Nginx configuration before reloading. If an error occurs, check `/etc/nginx/sites-available/paymenter.conf` and correct any issues.

4. **Database Connection**:
   - Ensure the MySQL service is running, and check the database credentials in `/var/www/paymenter/.env`.

## Contributing

Contributions, bug reports, and feature requests are welcome. Please feel free to fork the repository and submit a pull request.

---

## License

This project is open-source and available under the MIT License.

---

### Notes

- **Compatibility**: This script is specifically tailored for Ubuntu 24 and may require adjustments for other distributions.
- **Support**: For assistance, please create an issue on this repository.

---
