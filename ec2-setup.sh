#!/bin/bash
# AutoReportAI EC2 Setup Script
# Run this after SSH into your EC2 instance

echo "========================================="
echo "AutoReportAI EC2 Setup Script"
echo "========================================="

# Update system
echo "Step 1: Updating system..."
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
echo "Step 2: Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install MySQL client
echo "Step 3: Installing MySQL client..."
sudo apt-get install -y mysql-client

# Install PM2
echo "Step 4: Installing PM2..."
sudo npm install -g pm2

# Install Nginx
echo "Step 5: Installing Nginx..."
sudo apt-get install -y nginx

# Install Certbot for SSL
echo "Step 6: Installing Certbot..."
sudo apt-get install -y certbot python3-certbot-nginx

# Create app directory
echo "Step 7: Creating application directory..."
mkdir -p ~/autoreportai
cd ~/autoreportai

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Upload your application files to ~/autoreportai/"
echo "2. Create .env file with database credentials"
echo "3. Run: npm install"
echo "4. Run: pm2 start server.js --name autoreportai"
echo "5. Configure Nginx (see EC2-DEPLOYMENT.md)"
echo ""
echo "Your server is ready!"
