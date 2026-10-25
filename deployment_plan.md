# Corvanta Backend Deployment Plan

## 1. Backend Repository
**Path**: `/home/louis/corvanta/corvanta-backend`  
**Git status**: Clean, on `main`, up to date with `origin/main`

## 2. Stack & Startup
| Item | Value |
|------|-------|
| Runtime | Node.js (Express 5.x) |
| Entry point | `server.js` → imports `./app` → uses `src/config/config` |
| Start command | `npm start` (runs `node server.js`) |
| Dev command | `npm run dev` (nodemon) |
| Port | `5000` (configurable via `PORT` env) |
| Test | `npm test` |

### Required External Services
- **MongoDB** (required for production startup — `server.js` exits if unavailable)
- **AWS SQS** (queue already deployed; use `QUEUE_TYPE=sqs` with `SQS_QUEUE_URL`)
- **Optional**: OpenAI (`OPENAI_API_KEY`), Cloudinary, Resend, Pinecone

## 3. Missing Prerequisites on EC2
| Prerequisite | Status |
|--------------|--------|
| Node.js | ❌ Not installed (Ubuntu repos: 18.19.1) |
| npm | ❌ Not installed |
| MongoDB | ❌ Not installed (use external or install) |
| Application code | ❌ Not transferred |
| .env file | ❌ Not created (need production values) |

## 4. Proposed Deployment Steps

### A. Server Setup (one-time)
```bash
# SSH into EC2
ssh -i ~/.ssh/corvanta-ec2 ubuntu@18.159.47.196

# Install Node.js 18 + npm (LTS available in Ubuntu 24.04)
sudo apt-get update && sudo apt-get install -y nodejs npm

# Verify
node --version && npm --version

# Optional: Install MongoDB locally (or use external Atlas)
# sudo apt-get install -y mongodb
```

### B. Transfer Application
```bash
# From local machine: rsync the backend (excluding node_modules, .git, .env)
rsync -avz --exclude 'node_modules' --exclude '.git' --exclude '.env' \
  --exclude '*.log' --exclude 'trash.txt' \
  /home/louis/corvanta/corvanta-backend/ \
  ubuntu@18.159.47.196:/home/ubuntu/corvanta-backend/
```

### C. Install Dependencies & Configure
```bash
# On EC2
cd /home/ubuntu/corvanta-backend

# Copy .env.example to .env and populate with production values
cp .env.example .env
# Edit .env with: NODE_ENV=production, MONGO_URI, JWT secrets, SQS_QUEUE_URL, etc.

# Install production dependencies only
npm ci --omit=dev
```

### D. Systemd Service (persistent)
```bash
# Create /etc/systemd/system/corvanta-backend.service
# [Unit]
# Description=Corvanta Backend API
# After=network.target
# [Service]
# Type=simple
# User=ubuntu
# WorkingDirectory=/home/ubuntu/corvanta-backend
# EnvironmentFile=/home/ubuntu/corvanta-backend/.env
# ExecStart=/usr/bin/node server.js
# Restart=on-failure
# RestartSec=5
# StandardOutput=journal
# StandardError=journal
# [Install]
# WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl enable --now corvanta-backend
```

### E. Verify
```bash
# Local health check on server
curl -s http://localhost:5000/
# Should return JSON: {"success":true,"message":"Welcome to Corvanta API","version":"v1"}

# Remote check from PC
curl -s http://18.159.47.196:5000/
```

### F. Security Group (if needed)
- Current SG allows HTTP (80), HTTPS (443), SSH (22 from admin IP)
- **Port 5000 is NOT open** — must add SG rule for `102.88.108.143/32` TCP 5000 (or use Nginx reverse proxy on 80/443)

## 5. Configuration / Secrets Required
You must provide (securely, not in chat):
| Variable | Source |
|----------|--------|
| `MONGO_URI` | MongoDB Atlas URI or local `mongodb://localhost:27017/corvanta` |
| `JWT_ACCESS_SECRET` | Generate: `openssl rand -base64 32` |
| `JWT_REFRESH_SECRET` | Generate: `openssl rand -base64 32` |
| `OPENAI_API_KEY` | Your OpenAI key (or keep `AI_PROVIDER=mock`) |
| `RESEND_API_KEY` | Your Resend key (or placeholder) |
| `CLOUDINARY_*` | Your Cloudinary credentials (or placeholder) |
| `SQS_QUEUE_URL` | `https://sqs.eu-central-1.amazonaws.com/072718160542/Corvanta-production-queue` |
| `AWS_REGION` | `eu-central-1` |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | IAM user with SQS permissions, or use instance profile |

## 6. Port / Security-Group Note
- App listens on **port 5000** by default
- Current SG only has HTTP/HTTPS/SSH open
- **Either**: Add SG rule for TCP 5000 from admin IP, **or** put Nginx in front on 80/443 (recommended for production)

---

**Ready for approval.** No packages installed, no files transferred, no AWS changes made.