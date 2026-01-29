# AWS Deployment Guide

## Prerequisites
- AWS Account
- AWS CLI installed (optional but recommended)

## Deployment Options

### Option 1: AWS S3 + CloudFront (Recommended for Static Sites)

#### Step 1: Create S3 Bucket
1. Go to AWS S3 Console
2. Click "Create bucket"
3. Bucket name: `your-website-name` (must be unique globally)
4. Region: Choose closest to your users
5. Uncheck "Block all public access"
6. Create bucket

#### Step 2: Upload Website Files
1. Upload all files (index.html, styles.css, script.js, images)
2. Go to bucket properties
3. Enable "Static website hosting"
4. Index document: `index.html`
5. Error document: `index.html`

#### Step 3: Configure Bucket Policy
Add this policy (replace YOUR-BUCKET-NAME):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
        }
    ]
}
```

#### Step 4: Set Up CloudFront (Optional but Recommended)
1. Go to CloudFront Console
2. Create distribution
3. Origin domain: Your S3 bucket
4. Origin access: Public
5. Viewer protocol policy: Redirect HTTP to HTTPS
6. Create distribution

#### Step 5: Configure Custom Domain (Optional)
1. Go to Route 53
2. Create hosted zone for your domain
3. Create A record pointing to CloudFront distribution
4. Update nameservers at your domain registrar

### Option 2: AWS Amplify (Easiest)

#### Quick Deploy
1. Go to AWS Amplify Console
2. Click "Host web app"
3. Choose "Deploy without Git provider"
4. Drag and drop your files or upload as zip
5. Click "Save and deploy"

#### Custom Domain
1. In Amplify app, go to "Domain management"
2. Add domain
3. Follow DNS configuration steps

## Setting Up Contact Form Backend

### Option A: AWS Lambda + API Gateway + SES

#### Create Lambda Function
1. Go to Lambda Console
2. Create function (Node.js or Python)
3. Example code (Node.js):

```javascript
const AWS = require('aws-sdk');
const ses = new AWS.SES();

exports.handler = async (event) => {
    const body = JSON.parse(event.body);
    
    const params = {
        Source: 'noreply@yourdomain.com',
        Destination: {
            ToAddresses: ['your-email@example.com']
        },
        Message: {
            Subject: {
                Data: 'New Contact Form Submission'
            },
            Body: {
                Text: {
                    Data: `
Name: ${body.firstName} ${body.lastName}
Email: ${body.email}
Phone: ${body.phone}
Company: ${body.company}
Message: ${body.message}
                    `
                }
            }
        }
    };
    
    try {
        await ses.sendEmail(params).promise();
        return {
            statusCode: 200,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            body: JSON.stringify({ message: 'Success' })
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: 'Failed to send email' })
        };
    }
};
```

#### Create API Gateway
1. Go to API Gateway Console
2. Create REST API
3. Create POST method
4. Integration type: Lambda Function
5. Enable CORS
6. Deploy API
7. Copy the Invoke URL

#### Update script.js
Replace the API URL in script.js with your API Gateway endpoint.

### Option B: AWS Lambda + DynamoDB

For storing contacts in a database instead of email:

1. Create DynamoDB table (name: contacts)
2. Primary key: id (String)
3. Update Lambda to write to DynamoDB
4. Set up IAM permissions for Lambda to access DynamoDB

## Cost Estimates
- S3 + CloudFront: ~$1-5/month (low traffic)
- Amplify: ~$0.15/GB served + $0.01/build minute
- Lambda: First 1M requests free/month
- SES: First 62,000 emails free/month (when called from Lambda)

## Security Best Practices
1. Always use HTTPS (CloudFront provides free SSL)
2. Set up AWS WAF for CloudFront (if needed)
3. Use environment variables for sensitive data in Lambda
4. Implement rate limiting on API Gateway
5. Validate all form inputs on backend

## Updating Your Website
### S3 Method:
1. Upload new files to S3 bucket
2. Invalidate CloudFront cache (if using): `/*`

### Amplify Method:
1. Drag and drop new files in Amplify Console

## Domain Setup Checklist
- [ ] Purchase domain (AWS Route 53, GoDaddy, Namecheap, etc.)
- [ ] Create hosted zone in Route 53
- [ ] Update nameservers at registrar
- [ ] Request SSL certificate in AWS Certificate Manager
- [ ] Add certificate to CloudFront distribution
- [ ] Configure A and CNAME records

## Testing
1. Test website locally first (open index.html in browser)
2. Test on AWS before setting up custom domain
3. Test contact form submission
4. Test on mobile devices
5. Check page load speed (GTmetrix, PageSpeed Insights)

## Monitoring
- CloudWatch for Lambda logs
- S3 bucket metrics
- CloudFront metrics
- Set up CloudWatch alarms for errors

## Support Resources
- [AWS Documentation](https://docs.aws.amazon.com/)
- [AWS Support](https://aws.amazon.com/support/)
- [AWS Free Tier](https://aws.amazon.com/free/)
