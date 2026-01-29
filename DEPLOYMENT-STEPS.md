# AWS RDS & Backend Deployment - Step by Step

## Part 1: Create RDS MySQL Database (15 minutes)

### Step 1: Go to AWS RDS Console
1. Open your browser and go to: https://console.aws.amazon.com/rds/
2. Make sure you're in the correct region (top-right corner)
3. Click **"Create database"**

### Step 2: Configure Database Settings
Copy these settings exactly:

**Engine options:**
- Engine type: **MySQL**
- Edition: **MySQL Community**
- Version: **MySQL 8.0.39** (or latest 8.0.x)

**Templates:**
- Select: **Free tier** ✓ (This will limit other options to free tier)

**Settings:**
- DB instance identifier: `autoreportai-db`
- Master username: `admin`
- Credentials management: **Self managed**
- Master password: [CREATE A STRONG PASSWORD - Write it down!]
- Confirm password: [Enter same password]

**Instance configuration:**
- DB instance class: **db.t3.micro** (should be auto-selected with free tier)
  - If not available, choose **db.t4g.micro**

**Storage:**
- Storage type: **General Purpose SSD (gp2)**
- Allocated storage: **20 GiB** (default is fine)
- Enable storage autoscaling: **Unchecked** (to avoid charges)

**Connectivity:**
- Compute resource: **Don't connect to an EC2 compute resource**
- Network type: **IPv4**
- VPC: **Default VPC**
- DB subnet group: **default**
- **Public access: YES** ✓ (Important! Check this box)
- VPC security group: **Create new**
  - New VPC security group name: `autoreportai-db-sg`
- Availability Zone: **No preference**
- Database port: **3306**

**Database authentication:**
- Database authentication options: **Password authentication**

**Monitoring:**
- Enable Enhanced monitoring: **Unchecked** (to avoid charges)

**Additional configuration** (Click to expand):
- Initial database name: `autoreportai` (Important! Don't skip this)
- DB parameter group: **default.mysql8.0**
- Option group: **default:mysql-8-0**
- Backup:
  - Enable automated backups: **Checked** (default)
  - Backup retention period: **1 day** (minimum)
- Encryption: **Leave default settings**
- Maintenance:
  - Enable auto minor version upgrade: **Checked** (default)

### Step 3: Create Database
1. Review all settings
2. Click **"Create database"** at the bottom
3. Wait 5-10 minutes for status to change to **"Available"**

### Step 4: Save Database Endpoint
1. Once available, click on `autoreportai-db`
2. In **"Connectivity & security"** tab, find **Endpoint**
3. Copy the endpoint (looks like: `autoreportai-db.xxxxxxxxxx.us-east-1.rds.amazonaws.com`)
4. **SAVE THIS!** You'll need it later

### Step 5: Configure Security Group
1. On the same page, under **"Connectivity & security"**, click the security group link
2. Click **"Edit inbound rules"**
3. Click **"Add rule"**
4. Configure:
   - Type: **MySQL/Aurora**
   - Protocol: **TCP**
   - Port range: **3306** (auto-filled)
   - Source: **Anywhere-IPv4** (0.0.0.0/0) for now
   - Description: `MySQL access for AutoReportAI`
5. Click **"Save rules"**

### Step 6: Create Database Tables
Open PowerShell and run (replace YOUR-RDS-ENDPOINT):

```powershell
cd "C:\Program Files\MySQL\MySQL Server 8.0\bin"
.\mysql.exe -h YOUR-RDS-ENDPOINT.rds.amazonaws.com -u admin -p
```

Enter your RDS password when prompted, then run:

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

SHOW TABLES;
exit;
```

✅ **RDS Database is ready!**

---

## Part 2: Deploy Backend with Elastic Beanstalk

### Step 1: Initialize EB in Your Project
```powershell
cd C:\Users\ldsry\Desktop\CS405-website
eb init
```

Answer the prompts:
- Select a default region: **Choose your region** (e.g., 1 for us-east-1)
- Enter Application Name: **autoreportai**
- Select a platform: **Node.js**
- Select a platform branch: **Node.js 18** or **Node.js 20**
- Do you wish to continue with CodeCommit? **No** (n)
- Do you want to set up SSH? **Yes** (y)
  - Select a keypair or create new

### Step 2: Update .ebextensions Config
The config file is already created. Update it with your RDS details:

Open: `.ebextensions/environment.config`
Replace placeholders with your actual values:
- YOUR-RDS-ENDPOINT → Your actual RDS endpoint
- YOUR-RDS-PASSWORD → Your actual RDS password

### Step 3: Create EB Environment
```powershell
eb create autoreportai-prod --single
```

This will take 5-10 minutes. It will:
- Create an EC2 instance
- Deploy your Node.js application
- Give you a URL

### Step 4: Set Environment Variables (Alternative Method)
If .ebextensions doesn't work, set them manually:

```powershell
eb setenv DB_HOST=your-rds-endpoint.rds.amazonaws.com DB_USER=admin DB_PASSWORD=your-password DB_NAME=autoreportai NODE_ENV=production
```

### Step 5: Get Your Backend URL
```powershell
eb status
```

Look for **CNAME**: `autoreportai-prod.us-east-1.elasticbeanstalk.com`

### Step 6: Test Backend
Open browser and visit:
```
http://YOUR-EB-URL.elasticbeanstalk.com/api/health
```

Should see: `{"status":"ok","database":"connected"}`

✅ **Backend is deployed!**

---

## Part 3: Connect Frontend to Backend

### Step 1: Update script.js
Replace `YOUR-BACKEND-URL` in script.js with your EB URL:

```javascript
const apiUrl = window.location.hostname === 'localhost' 
    ? 'http://localhost:3000/api/contact'
    : 'https://autoreportai-prod.us-east-1.elasticbeanstalk.com/api/contact';
```

### Step 2: Update server.js CORS
Add your Amplify domain to allowed origins.

### Step 3: Re-upload to Amplify
1. Create a clean folder with frontend files only:
   - index.html
   - styles.css
   - script.js (updated)
   - logo.png
   - product-image.jpg

2. Go to Amplify Console
3. Drag and drop the folder to deploy

### Step 4: Test Everything
1. Visit `https://autoreportform.click`
2. Fill out contact form
3. Submit
4. Check RDS database for the entry

---

## Troubleshooting

### Can't connect to RDS:
- Check security group allows 0.0.0.0/0
- Verify public access is enabled
- Check endpoint is correct

### EB deployment fails:
```powershell
eb logs
```

### CORS errors:
Update server.js and redeploy:
```powershell
eb deploy
```

---

## Quick Commands Reference

**Check EB status:**
```powershell
eb status
```

**View logs:**
```powershell
eb logs
```

**Redeploy after changes:**
```powershell
eb deploy
```

**Terminate environment (cleanup):**
```powershell
eb terminate autoreportai-prod
```

**Delete RDS database:**
- Go to RDS Console → Select database → Actions → Delete

---

## Cost Summary
- **RDS db.t3.micro**: ~$15-20/month (Free tier: 750 hours/month for 12 months)
- **EB t2.micro EC2**: Free tier or ~$8/month
- **Amplify**: ~$1-2/month for small traffic
- **Total**: $0-5/month with free tier, $25-30/month without

---

## What You Need:
1. ✅ AWS account
2. ✅ Domain in Amplify (autoreportform.click)
3. ⏳ RDS endpoint (from Part 1)
4. ⏳ EB backend URL (from Part 2)
5. ⏳ Updated frontend (Part 3)

Start with Part 1 (RDS) now! Let me know when you have the RDS endpoint ready.
