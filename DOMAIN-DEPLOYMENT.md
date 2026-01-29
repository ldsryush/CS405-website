# AWS Deployment Guide - With Your Domain

## Architecture Overview
- **Frontend**: AWS Amplify or S3 + CloudFront (Static files)
- **Backend**: AWS Elastic Beanstalk or EC2 (Node.js API)
- **Database**: AWS RDS MySQL
- **Domain**: Route 53 (Your registered domain)

---

## Step 1: Create RDS MySQL Database

### 1.1 Go to AWS RDS Console
https://console.aws.amazon.com/rds/

### 1.2 Create Database
- Click **"Create database"**
- Choose **MySQL**
- Template: **Free tier** (or Production)
- Settings:
  - DB instance identifier: `autoreportai-db`
  - Master username: `admin`
  - Master password: [Create a strong password - save it!]
  - Confirm password
- DB instance class: `db.t3.micro` (free tier) or `db.t4g.micro`
- Storage: 20 GB (default)
- **Important**: Under "Connectivity"
  - Public access: **Yes** (for initial setup)
  - VPC security group: Create new
  - Availability Zone: No preference
- Additional configuration:
  - Initial database name: `autoreportai`
- Click **"Create database"**

### 1.3 Wait for Database Creation
- Status will change to "Available" (5-10 minutes)
- Note the **Endpoint** (looks like: `autoreportai-db.xxxxx.us-east-1.rds.amazonaws.com`)

### 1.4 Configure Security Group
- Go to your RDS instance → Connectivity & security
- Click the security group link
- Edit inbound rules → Add rule:
  - Type: MySQL/Aurora
  - Port: 3306
  - Source: Anywhere-IPv4 (0.0.0.0/0) for testing
  - Description: MySQL access
- Save rules

### 1.5 Create Tables in RDS
Connect from your local machine:
```bash
cd "C:\Program Files\MySQL\MySQL Server 8.0\bin"
.\mysql.exe -h YOUR-RDS-ENDPOINT.rds.amazonaws.com -u admin -p
```

Enter your RDS password, then run:
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
```

---

## Step 2: Deploy Backend to AWS Elastic Beanstalk

### 2.1 Prepare Application
Your files are ready. Just need to update environment variables for production.

### 2.2 Install AWS EB CLI (if not installed)
```powershell
pip install awsebcli --upgrade
```

### 2.3 Initialize Elastic Beanstalk
```powershell
cd C:\Users\ldsry\Desktop\CS405-website
eb init
```

Follow prompts:
- Region: Choose closest to you (e.g., `us-east-1`)
- Application name: `autoreportai`
- Platform: Node.js
- Platform branch: Node.js 18 or 20
- CodeCommit: No
- SSH: Yes (recommended)

### 2.4 Create Environment
```powershell
eb create autoreportai-prod
```

This will:
- Create an EC2 instance
- Deploy your code
- Give you a URL like: `autoreportai-prod.us-east-1.elasticbeanstalk.com`

### 2.5 Set Environment Variables
```powershell
eb setenv DB_HOST=your-rds-endpoint.rds.amazonaws.com DB_USER=admin DB_PASSWORD=your-rds-password DB_NAME=autoreportai PORT=8080
```

### 2.6 Deploy Updates
Anytime you make changes:
```powershell
eb deploy
```

### 2.7 Get Your Backend URL
```powershell
eb status
```

Note the CNAME (your backend URL)

---

## Step 3: Deploy Frontend to AWS Amplify

### 3.1 Create Deployment Package
Create a folder with just frontend files:
```powershell
mkdir frontend-deploy
copy index.html frontend-deploy\
copy styles.css frontend-deploy\
copy script.js frontend-deploy\
copy logo.png frontend-deploy\
copy product-image.jpg frontend-deploy\
```

### 3.2 Update script.js with Backend URL
Open `frontend-deploy\script.js` and update:
```javascript
const apiUrl = 'https://YOUR-EB-URL.elasticbeanstalk.com/api/contact';
```

### 3.3 Deploy to Amplify
1. Go to AWS Amplify Console: https://console.aws.amazon.com/amplify/
2. Click **"New app"** → **"Host web app"**
3. Choose **"Deploy without Git provider"**
4. Drag and drop your `frontend-deploy` folder
5. App name: `autoreportai`
6. Environment name: `production`
7. Click **"Save and deploy"**

### 3.4 Get Amplify URL
You'll get a URL like: `https://main.xxxxx.amplifyapp.com`

---

## Step 4: Connect Your Domain

### 4.1 Add Domain to Amplify
1. In Amplify console, click your app
2. Go to **"Domain management"**
3. Click **"Add domain"**
4. Enter your domain (e.g., `yourdomain.com`)
5. Click **"Configure domain"**

### 4.2 Update DNS Records
Amplify will show you DNS records to add. Go to where your domain is registered:

**If domain is NOT in Route 53:**
- Go to your domain registrar (GoDaddy, Namecheap, etc.)
- Add the CNAME records Amplify provides
- Wait for DNS propagation (5 minutes to 48 hours)

**If domain IS in Route 53:**
- Amplify can configure it automatically
- Just click "Update DNS records"

### 4.3 Wait for SSL Certificate
AWS will automatically provision SSL certificate for HTTPS (5-30 minutes)

---

## Step 5: Configure CORS on Backend

Update server.js CORS settings:

```javascript
app.use(cors({
    origin: ['https://yourdomain.com', 'https://www.yourdomain.com'],
    credentials: true
}));
```

Then redeploy:
```powershell
eb deploy
```

---

## Alternative: Simpler All-in-One EC2 Deployment

If Elastic Beanstalk seems complex, use a single EC2 instance:

### 1. Launch EC2 Instance
- AMI: Ubuntu 22.04 LTS
- Instance type: t2.micro (free tier)
- Key pair: Create or use existing
- Security group: Allow ports 22, 80, 443, 3000

### 2. Connect and Deploy
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install MySQL client
sudo apt-get install mysql-client

# Clone or upload your files
# (Use scp, git, or copy-paste)

# Install dependencies
cd /home/ubuntu/autoreportai
npm install

# Set up environment
nano .env
# Update with RDS credentials

# Install PM2
sudo npm install -g pm2
pm2 start server.js
pm2 startup
pm2 save

# Install Nginx
sudo apt-get install nginx

# Configure Nginx
sudo nano /etc/nginx/sites-available/autoreportai
```

Nginx config:
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/autoreportai /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 3. Get SSL Certificate
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 4. Point Domain to EC2
- Get EC2 Elastic IP (so it doesn't change)
- Go to Route 53 or your domain registrar
- Create A record: `yourdomain.com` → EC2 Elastic IP

---

## Recommended Approach

**For Beginners**: Amplify (frontend) + Elastic Beanstalk (backend) + RDS
**For Control**: Single EC2 instance + RDS + Nginx

---

## Testing Your Deployment

1. Visit `https://yourdomain.com`
2. Fill out contact form
3. Check RDS database:
```bash
mysql -h YOUR-RDS-ENDPOINT -u admin -p
USE autoreportai;
SELECT * FROM contacts;
```

---

## Estimated Monthly Costs

- RDS db.t3.micro: $15-20
- EC2 t2.micro: $8-10 (or free tier)
- Amplify: $0.01 per build + $0.15/GB served
- Route 53: $0.50 per hosted zone
- **Total**: ~$25-35/month (less if using free tier)

---

## Need Help?

Check [BACKEND-SETUP.md](BACKEND-SETUP.md) for more detailed troubleshooting.
