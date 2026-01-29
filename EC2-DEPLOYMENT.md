# EC2 Deployment Guide for AutoReportAI

## Part 1: Create RDS Database (Same as before)

### Quick Steps:
1. Go to AWS RDS Console: https://console.aws.amazon.com/rds/
2. Click **"Create database"**
3. Settings:
   - Engine: **MySQL 8.0**
   - Template: **Free tier**
   - DB instance identifier: `autoreportai-db`
   - Master username: `admin`
   - Master password: [Create strong password]
   - Public access: **YES** ✓
   - Initial database name: `autoreportai`
4. Click **"Create database"**
5. Wait 10 minutes for "Available" status
6. **Copy the Endpoint** from Connectivity & security tab
7. Edit security group → Add inbound rule:
   - Type: MySQL/Aurora (port 3306)
   - Source: 0.0.0.0/0

### Create Tables:
```powershell
cd "C:\Program Files\MySQL\MySQL Server 8.0\bin"
.\mysql.exe -h YOUR-RDS-ENDPOINT.rds.amazonaws.com -u admin -p
```

Then run:
```sql
USE autoreportai;
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
exit;
```

---

## Part 2: Launch EC2 Instance

### Step 1: Go to EC2 Console
https://console.aws.amazon.com/ec2/

### Step 2: Launch Instance
1. Click **"Launch Instance"**
2. Name: `autoreportai-backend`
3. Application and OS Images:
   - **Ubuntu Server 22.04 LTS** (Free tier eligible)
4. Instance type:
   - **t2.micro** (Free tier eligible)
5. Key pair:
   - Create new key pair
   - Name: `autoreportai-key`
   - Type: RSA
   - Format: `.pem`
   - **Download and save the .pem file!**
6. Network settings:
   - Create security group
   - Allow:
     - ✅ SSH (port 22) - Your IP
     - ✅ HTTP (port 80) - Anywhere
     - ✅ HTTPS (port 443) - Anywhere
     - ✅ Custom TCP (port 3000) - Anywhere (for testing)
7. Configure storage:
   - 8 GB gp2 (default is fine)
8. Click **"Launch instance"**

### Step 3: Allocate Elastic IP (so IP doesn't change)
1. Go to EC2 → Elastic IPs
2. Click **"Allocate Elastic IP address"**
3. Click **"Allocate"**
4. Select the new IP → Actions → **"Associate Elastic IP address"**
5. Instance: Select `autoreportai-backend`
6. Click **"Associate"**
7. **Copy the Elastic IP** (e.g., 54.123.45.67)

---

## Part 3: Connect and Deploy

### Step 1: Convert .pem to .ppk (for Windows)
If using PuTTY:
1. Download PuTTYgen
2. Load your .pem file
3. Save private key as .ppk

Or use PowerShell SSH (easier):
```powershell
# Move key to .ssh folder
mkdir ~\.ssh -Force
copy C:\Users\ldsry\Downloads\autoreportai-key.pem ~\.ssh\
icacls ~\.ssh\autoreportai-key.pem /inheritance:r
icacls ~\.ssh\autoreportai-key.pem /grant:r "%username%:R"
```

### Step 2: SSH into EC2
```powershell
ssh -i ~/.ssh/autoreportai-key.pem ubuntu@YOUR-ELASTIC-IP
```

Type "yes" when prompted.

### Step 3: Run Deployment Script on EC2
Once connected to EC2, run these commands one by one:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install MySQL client
sudo apt-get install -y mysql-client

# Install PM2 (process manager)
sudo npm install -g pm2

# Create app directory
mkdir -p ~/autoreportai
cd ~/autoreportai

# We'll upload files next
```

### Step 4: Upload Your Files to EC2
Open a **NEW PowerShell window** (don't close SSH session):

```powershell
# Create deployment package
cd C:\Users\ldsry\Desktop\CS405-website
$files = @(
    "server.js",
    "package.json",
    "index.html",
    "styles.css",
    "script.js",
    "logo.png",
    "product-image.jpg"
)

# Upload files
foreach ($file in $files) {
    if (Test-Path $file) {
        scp -i ~/.ssh/autoreportai-key.pem $file ubuntu@YOUR-ELASTIC-IP:~/autoreportai/
    }
}
```

### Step 5: Configure Environment (Back in SSH session)
```bash
cd ~/autoreportai

# Create .env file
cat > .env << EOF
DB_HOST=your-rds-endpoint.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=your-rds-password
DB_NAME=autoreportai
PORT=3000
NODE_ENV=production
EOF

# Install dependencies
npm install

# Test the server
npm start
```

Press `Ctrl+C` to stop after testing.

### Step 6: Start with PM2
```bash
# Start server with PM2
pm2 start server.js --name autoreportai

# Make it start on reboot
pm2 startup
# Copy and run the command it outputs

pm2 save

# Check status
pm2 status
pm2 logs autoreportai
```

### Step 7: Install and Configure Nginx
```bash
# Install Nginx
sudo apt-get install -y nginx

# Create Nginx config
sudo nano /etc/nginx/sites-available/autoreportai
```

Paste this config:
```nginx
server {
    listen 80;
    server_name YOUR-ELASTIC-IP autoreportform.click www.autoreportform.click;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Save with `Ctrl+X`, `Y`, `Enter`.

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/autoreportai /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### Step 8: Install SSL Certificate (Free with Let's Encrypt)
```bash
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate (replace with your domain)
sudo certbot --nginx -d autoreportform.click -d www.autoreportform.click
```

Follow prompts:
- Enter email
- Agree to terms
- Choose to redirect HTTP to HTTPS

---

## Part 4: Update DNS

### Point Your Domain to EC2:
1. Go to your domain settings in AWS Amplify
2. Or go to Route 53 (if managing there)
3. Create/Update A record:
   - Name: `@` or `autoreportform.click`
   - Type: A
   - Value: YOUR-ELASTIC-IP
4. Create CNAME for www:
   - Name: `www`
   - Type: CNAME
   - Value: `autoreportform.click`

---

## Part 5: Update Frontend

### Update script.js with EC2 URL:
```javascript
const apiUrl = window.location.hostname === 'localhost' 
    ? 'http://localhost:3000/api/contact'
    : 'https://autoreportform.click/api/contact';
```

### Update server.js CORS:
```javascript
app.use(cors({
    origin: [
        'https://autoreportform.click',
        'https://www.autoreportform.click',
        'http://localhost:3000'
    ],
    credentials: true
}));
```

### Redeploy to EC2:
```powershell
scp -i ~/.ssh/autoreportai-key.pem script.js ubuntu@YOUR-ELASTIC-IP:~/autoreportai/
scp -i ~/.ssh/autoreportai-key.pem server.js ubuntu@YOUR-ELASTIC-IP:~/autoreportai/
```

Then in SSH:
```bash
cd ~/autoreportai
pm2 restart autoreportai
```

### Update Amplify:
1. Create clean frontend folder with updated files
2. Upload to Amplify

---

## Testing

Visit these URLs:
1. `https://autoreportform.click/api/health` - Should show database connected
2. `https://autoreportform.click` - Your website
3. Fill out contact form and submit
4. Check database:
```bash
mysql -h YOUR-RDS-ENDPOINT -u admin -p
USE autoreportai;
SELECT * FROM contacts;
```

---

## Useful Commands

**View logs:**
```bash
pm2 logs autoreportai
```

**Restart server:**
```bash
pm2 restart autoreportai
```

**Stop server:**
```bash
pm2 stop autoreportai
```

**Server status:**
```bash
pm2 status
```

**Check Nginx:**
```bash
sudo systemctl status nginx
sudo nginx -t
```

**Update application:**
```bash
cd ~/autoreportai
git pull  # if using git
npm install
pm2 restart autoreportai
```

---

## Cost Estimate

- **EC2 t2.micro**: Free tier (750 hours/month for 12 months) or ~$8/month
- **RDS db.t3.micro**: Free tier (750 hours/month for 12 months) or ~$15/month
- **Elastic IP**: Free while attached to running instance
- **Data transfer**: First 100 GB free/month

**Total**: $0/month with free tier, ~$25/month after

---

## Quick Reference Card

**SSH into server:**
```powershell
ssh -i ~/.ssh/autoreportai-key.pem ubuntu@YOUR-ELASTIC-IP
```

**Upload file:**
```powershell
scp -i ~/.ssh/autoreportai-key.pem file.js ubuntu@YOUR-ELASTIC-IP:~/autoreportai/
```

**Restart after changes:**
```bash
pm2 restart autoreportai
```

**View website:**
- Frontend: https://autoreportform.click
- API health: https://autoreportform.click/api/health
- All contacts: https://autoreportform.click/api/contacts

---

Done! Your website will be fully functional with database storage.
