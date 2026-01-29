#!/bin/bash
# Run this after uploading application files

cd ~/autoreportai

echo "========================================="
echo "Starting AutoReportAI Application"
echo "========================================="

# Install dependencies
echo "→ Installing Node.js dependencies..."
npm install

# Start with PM2
echo "→ Starting application with PM2..."
pm2 start server.js --name autoreportai
pm2 startup | tail -n 1 | bash
pm2 save

# Configure Nginx
echo "→ Configuring Nginx..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

sudo tee /etc/nginx/sites-available/autoreportai > /dev/null << EOF
server {
    listen 80;
    server_name $PUBLIC_IP autoreportform.click www.autoreportform.click;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/autoreportai /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo ""
echo "========================================="
echo "✓ Application Started!"
echo "========================================="
echo ""
echo "Your server is running at:"
echo "  http://$PUBLIC_IP"
echo "  http://autoreportform.click (after DNS update)"
echo ""
echo "Test API: http://$PUBLIC_IP/api/health"
echo ""
echo "Next step: Set up SSL certificate"
echo "Run: sudo certbot --nginx -d autoreportform.click -d www.autoreportform.click"
echo ""
