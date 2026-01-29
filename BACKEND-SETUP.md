# Backend Setup Guide - MySQL Integration

## Quick Start (Local Development)

### Step 1: Install Node.js
If you don't have Node.js installed:
1. Download from https://nodejs.org/
2. Install the LTS version
3. Verify: `node --version`

### Step 2: Install MySQL
**Download MySQL:**
- Windows: https://dev.mysql.com/downloads/installer/
- Or use XAMPP/WAMP which includes MySQL

**Start MySQL service** (if not auto-started)

### Step 3: Create Database
Run the SQL setup script:

```bash
# Option A: Using MySQL command line
mysql -u root -p < database-setup.sql

# Option B: Using MySQL Workbench
# Open database-setup.sql and execute it
```

### Step 4: Configure Environment
1. Open `.env` file
2. Update your MySQL credentials:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=autoreportai
PORT=3000
```

### Step 5: Install Dependencies
```bash
npm install
```

### Step 6: Start the Server
```bash
npm start

# For development with auto-restart:
npm run dev
```

Server will run at: http://localhost:3000

### Step 7: Test the Website
1. Open http://localhost:3000 in your browser
2. Fill out the contact form
3. Submit and check MySQL database for the entry

---

## AWS Deployment

### Option A: AWS EC2 + RDS (Recommended)

#### 1. Set Up RDS MySQL Database
1. Go to AWS RDS Console
2. Create database:
   - Engine: MySQL
   - Template: Free tier (or Production)
   - DB instance identifier: `autoreportai-db`
   - Master username: `admin`
   - Master password: [create secure password]
   - DB name: `autoreportai`
   
3. Configure:
   - VPC: Default or custom
   - Public access: Yes (for initial setup)
   - Security group: Create new
   - Port: 3306

4. Wait for database to be available
5. Note the endpoint (e.g., `autoreportai-db.xxxxx.us-east-1.rds.amazonaws.com`)

#### 2. Configure RDS Security Group
1. Go to EC2 > Security Groups
2. Find RDS security group
3. Add inbound rule:
   - Type: MySQL/Aurora
   - Port: 3306
   - Source: Your EC2 security group (or IP for testing)

#### 3. Set Up Database Schema
Connect to RDS and run `database-setup.sql`:

```bash
mysql -h your-rds-endpoint.region.rds.amazonaws.com -u admin -p autoreportai < database-setup.sql
```

#### 4. Launch EC2 Instance
1. Go to EC2 Console
2. Launch instance:
   - AMI: Amazon Linux 2 or Ubuntu
   - Instance type: t2.micro (free tier)
   - Configure security group:
     - HTTP (80)
     - HTTPS (443)
     - Custom TCP (3000) for testing
     - SSH (22)

#### 5. Deploy Application to EC2

SSH into your instance:
```bash
ssh -i your-key.pem ec2-user@your-ec2-public-ip
```

Install Node.js:
```bash
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs
```

Upload your files (from local machine):
```bash
scp -i your-key.pem -r * ec2-user@your-ec2-ip:/home/ec2-user/app/
```

Or clone from Git if you have a repository.

On EC2, configure environment:
```bash
cd /home/ec2-user/app
nano .env
```

Update with RDS credentials:
```
DB_HOST=your-rds-endpoint.region.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=your_rds_password
DB_NAME=autoreportai
PORT=3000
```

Install and start:
```bash
npm install
npm start
```

#### 6. Set Up PM2 (Process Manager)
Keep your app running:
```bash
sudo npm install -g pm2
pm2 start server.js --name autoreportai
pm2 startup
pm2 save
```

#### 7. Configure Nginx (Production)
Install Nginx:
```bash
sudo yum install -y nginx
```

Configure reverse proxy:
```bash
sudo nano /etc/nginx/conf.d/autoreportai.conf
```

Add:
```nginx
server {
    listen 80;
    server_name your-domain.com;

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

Start Nginx:
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

---

### Option B: AWS Elastic Beanstalk + RDS

#### 1. Create RDS Database (same as Option A, step 1)

#### 2. Prepare Application
Create `.ebextensions/environment.config`:
```yaml
option_settings:
  aws:elasticbeanstalk:application:environment:
    DB_HOST: your-rds-endpoint.region.rds.amazonaws.com
    DB_USER: admin
    DB_PASSWORD: your_rds_password
    DB_NAME: autoreportai
    PORT: 8080
```

#### 3. Deploy to Elastic Beanstalk
```bash
# Install EB CLI
pip install awsebcli

# Initialize
eb init -p node.js autoreportai

# Create environment
eb create autoreportai-env

# Deploy
eb deploy
```

---

### Option C: AWS Lambda + API Gateway + RDS

This is more complex but serverless. See AWS Lambda documentation for detailed setup.

---

## Testing Database Connection

### Test Script
Create `test-connection.js`:
```javascript
const mysql = require('mysql2');
require('dotenv').config();

const connection = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});

connection.connect((err) => {
    if (err) {
        console.error('Error:', err.message);
        return;
    }
    console.log('✓ Connected to MySQL database');
    
    connection.query('SELECT * FROM contacts', (err, results) => {
        if (err) {
            console.error('Query error:', err.message);
        } else {
            console.log('✓ Contacts table exists');
            console.log('Total contacts:', results.length);
        }
        connection.end();
    });
});
```

Run:
```bash
node test-connection.js
```

---

## API Endpoints

### POST /api/contact
Submit contact form
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "phone": "555-1234",
  "company": "Acme Inc",
  "message": "Interested in your product"
}
```

### GET /api/contacts
Retrieve all contacts (admin only - add authentication in production)

### GET /api/health
Check server and database status

---

## Security Recommendations

1. **Never commit .env file to Git**
   - Already in .gitignore
   
2. **Use strong passwords**
   - Database passwords
   - AWS credentials

3. **Enable SSL/TLS**
   - Use HTTPS in production
   - AWS Certificate Manager for free SSL

4. **Implement rate limiting**
   ```bash
   npm install express-rate-limit
   ```

5. **Add authentication for admin endpoints**
   ```bash
   npm install jsonwebtoken bcrypt
   ```

6. **Input validation**
   ```bash
   npm install express-validator
   ```

7. **Use environment variables**
   - Never hardcode credentials

8. **Restrict database access**
   - Use least privilege principle
   - Whitelist IP addresses

---

## Troubleshooting

### Can't connect to MySQL
- Check MySQL is running: `mysql -u root -p`
- Verify credentials in .env
- Check firewall settings

### CORS errors
- Already configured in server.js
- Update origin if needed

### Database connection timeout
- Check security groups (AWS)
- Verify RDS is publicly accessible (or use VPN)
- Check network ACLs

### Port already in use
- Change PORT in .env
- Kill process: `lsof -ti:3000 | xargs kill` (Mac/Linux)
- Or: `netstat -ano | findstr :3000` then `taskkill /PID [PID] /F` (Windows)

---

## Monitoring & Maintenance

### View Logs
```bash
# PM2 logs
pm2 logs autoreportai

# CloudWatch (AWS)
# Configure in AWS Console
```

### Database Backups
- RDS automated backups (AWS)
- Manual exports: `mysqldump -u root -p autoreportai > backup.sql`

### Update Application
```bash
# Pull latest code
git pull

# Install dependencies
npm install

# Restart
pm2 restart autoreportai
```

---

## Cost Estimates (AWS)

- **RDS MySQL (db.t3.micro)**: ~$15-20/month
- **EC2 (t2.micro)**: Free tier or ~$8/month
- **Data transfer**: ~$0.09/GB
- **Route 53** (domain): ~$0.50/month

**Total**: ~$25-30/month for small scale

---

## Need Help?

- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Node.js MySQL2 Package](https://github.com/sidorares/node-mysql2)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)
