#!/bin/bash
# AutoReportAI - Complete EC2 Setup Script
# This installs everything: Node.js, MySQL, Nginx, SSL

set -e  # Exit on any error

echo "========================================="
echo "AutoReportAI Complete Setup"
echo "Installing Node.js, MySQL, Nginx, SSL"
echo "========================================="
echo ""

# Update system
echo "→ Updating system..."
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
echo "→ Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install MySQL Server
echo "→ Installing MySQL Server..."
sudo apt-get install -y mysql-server

# Secure MySQL installation
echo "→ Configuring MySQL..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'AutoReport2026!';"
sudo mysql -e "CREATE DATABASE IF NOT EXISTS autoreportai;"
sudo mysql -e "FLUSH PRIVILEGES;"

# Create contacts table
echo "→ Creating database tables..."
sudo mysql -u root -pAutoReport2026! autoreportai << 'EOF'
CREATE TABLE IF NOT EXISTS contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    company VARCHAR(255),
    message TEXT,
    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_submitted_at (submitted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF

# Install PM2
echo "→ Installing PM2..."
sudo npm install -g pm2

# Install Nginx
echo "→ Installing Nginx..."
sudo apt-get install -y nginx

# Install Certbot for SSL
echo "→ Installing Certbot..."
sudo apt-get install -y certbot python3-certbot-nginx

# Create app directory
echo "→ Setting up application directory..."
mkdir -p ~/autoreportai
cd ~/autoreportai

# Create .env file
echo "→ Creating environment configuration..."
cat > .env << 'EOF'
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=AutoReport2026!
DB_NAME=autoreportai
PORT=3000
NODE_ENV=production
EOF

echo ""
echo "========================================="
echo "✓ Base Setup Complete!"
echo "========================================="
echo ""
echo "MySQL root password: AutoReport2026!"
echo "Database: autoreportai"
echo ""
echo "Waiting for application files upload..."
