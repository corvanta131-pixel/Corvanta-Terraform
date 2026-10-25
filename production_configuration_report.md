# Corvanta — Secure Production Configuration Report

## 1. AWS SDK Authentication (IAM Role Support) ✅

**Answer**: YES — SQS can use the EC2 instance IAM role via the AWS SDK default credential provider chain.

**Evidence**:
- SQS provider: `src/services/providers/sqsQueue.js` creates `SQSClient` with only `region` config — no explicit credentials passed
- The AWS SDK v3 automatically falls back to EC2 Instance Profile if no explicit credentials configured
- IAM role `corvanta-production-ec2-role` attached with `sqs:*` and `s3:*` policies

**How to configure**:
- In `.env`: Set `QUEUE_TYPE=sqs`  
- Set `SQS_QUEUE_URL=https://sqs.eu-central-1.amazonaws.com/072718160542/Corvanta-production-queue`  
- Set `AWS_REGION=eu-central-1` OR omit (defaults to same region)  
- **Do NOT set** `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` — let the SDK use the instance role

**Action**: The IAM role can authenticate SQS without secrets when `QUEUE_TYPE=sqs`.

---

## 2. Secure JWT Configuration ✅

**Required variables**:
- `JWT_ACCESS_SECRET` — for signing access tokens
- `JWT_REFRESH_SECRET` — for signing refresh tokens
- Both must be strong, independent random values

**Local generation command** (run on your workstation):
```bash
# Generate first secret (for access tokens)
openssl rand -base64 32

# Generate second secret (for refresh tokens)
openssl rand -base64 32
```

**Usage**:
1. Save each output securely (e.g., password manager)
2. Add to `.env`:
   ```
   JWT_ACCESS_SECRET=<output-from-first-command>
   JWT_REFRESH_SECRET=<output-from-second-command>
   ```

**Validation**: Code rejects placeholders starting `development-placeholder-`.

---

## 3. MongoDB Requirement ⚠️

**Status**: **Required** — must provide production MongoDB URI before deployment.

**Evidence** (`src/config/config.js` lines 106-147):
- Startup validation throws error if `MONGO_URI` not set
- In production, rejects `MONGO_URI=mongodb://localhost:27017/corvanta_dev`

**Options**:
1. **MongoDB Atlas** (recommended)
   - Deploy a free cluster at cloud.mongodb.com
   - Create database user with read/write access to `corvanta` database
   - Get connection string: `mongodb+srv://user:password@cluster.mongodb.net/corvanta`

2. **Existing self-hosted MongoDB**
   - Must be network-reachable from EC2 instance

**What I cannot do**:
- Create database account or cluster
- Provide production URI (credentials needed)

---

## 4. Minimum Prerequisites Checklist

### Required (deploy blockers):
| Item | Status | Notes |
|------|--------|-------|
| MongoDB production URI | ❌ MISSING | Provide connection string |
| JWT_ACCESS_SECRET | ❌ MISSING | Generate via `openssl rand -base64 32` |
| JWT_REFRESH_SECRET | ❌ MISSING | Generate via `openssl rand -base64 32` |

### Ready to proceed:
| Item | Status | Notes |
|------|--------|-------|
| EC2 instance running | ✅ | `ip-10-0-1-216` @ `18.159.47.196` |
| Node.js 18 available | ✅ | In Ubuntu 24.04 repos |
| IAM role for SQS/S3 | ✅ | Attached via module.iam |
| SQS queue exists | ✅ | `Corvanta-production-queue` |

---

## 5. Proposed Deployment Procedure

### Step 1: Create production `.env` (local, on your workstation)
```bash
# After generating secrets and obtaining MongoDB URI:
cat > /home/louis/corvanta/corvanta-backend/.env << EOF
NODE_ENV=production
PORT=5000
MONGO_URI=<your-production-mongodb-uri>
JWT_ACCESS_SECRET=<openssl-generated-access-secret>
JWT_REFRESH_SECRET=<openssl-generated-refresh-secret>
CLIENT_URL=<your-frontend-url>
RESEND_API_KEY=<optional-or-leave>
CLOUDINARY_<...>=<optional-or-leave>
OPENAI_API_KEY=<optional-or-leave>
QUEUE_TYPE=sqs
SQS_QUEUE_URL=https://sqs.eu-central-1.amazonaws.com/072718160542/Corvanta-production-queue
AWS_REGION=eu-central-1
EOF
```

### Step 2: Install Node.js on EC2
```bash
ssh -i ~/.ssh/corvanta-ec2 ubuntu@18.159.47.196
sudo apt-get update
sudo apt-get install -y nodejs npm
node --version && npm --version
```

### Step 3: Transfer application
```bash
rsync -avz --exclude 'node_modules' --exclude '.git' --exclude '.env' \
  /home/louis/corvanta/corvanta-backend/ \
  ubuntu@18.159.47.196:/home/ubuntu/corvanta-backend/
```

### Step 4: Install dependencies
```bash
cd /home/ubuntu/corvanta-backend
npm ci --omit=dev
```

### Step 5: Create systemd service (on EC2)
```bash
sudo tee /etc/systemd/system/corvanta-backend.service > /dev/null << 'EOF'
[Unit]
Description=Corvanta Backend API
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/corvanta-backend
EnvironmentFile=/home/ubuntu/corvanta-backend/.env
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now corvanta-backend
sudo systemctl status corvanta-backend
```

### Step 6: Verify
```bash
curl -s http://localhost:5000/
# Expected: {"success":true,"message":"Welcome to Corvanta API","version":"v1"}
```

---

## What I Need From You

1. **Production MongoDB URI** — connection string to the production MongoDB database
2. **JWT secrets** — two 32-byte base64 values (generate with `openssl rand -base64 32`)
3. **Public/frontend URL** — for `CLIENT_URL` and CORS (if applicable)
4. **Optional integrations** (email, AI, cloud storage) — provide only if you want them enabled

**I have NOT executed any of these steps yet.** Provide credentials/info above, then approve deployment.