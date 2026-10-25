# SSH and Backend Verification Report

## SSH Connection Test

| Target | Result |
|--------|--------|
| Elastic IP `18.159.47.196` (after security group update) | ✅ Connected |

- SSH key: `~/.ssh/corvanta-ec2` (used, never exposed)
- Username: `ubuntu`
- Host: `ip-10-0-1-216`

## Read-Only Backend Checks

### OS / Hostname
- **Ubuntu**: 24.04.1 LTS (Noble), kernel `7.0.0-1014-aws`
- **Hostname**: `ip-10-0-1-216`

### Application Directory
- `/home/ubuntu/` — only default Ubuntu dotfiles (`.bashrc`, `.profile`, `.ssh`). No Corvanta files.
- `/opt/` — empty
- `/srv/` — empty
- `/var/www/` — does not exist
- **Result**: Corvanta application directory NOT found

### Node.js / npm
- `which node` — not installed
- `which npm` — not installed
- `which nginx` — not installed
- `which docker` — not installed
- `which docker-compose` — not installed
- `which pm2` — not installed
- **Result**: Node.js, npm, and runtime tools NOT installed

### Systemd Services
- No services matching `corvanta`, `node`, `nginx`, or `backend`
- Only standard systemd services (kmod, tmpfiles, etc.)
- **Result**: No Corvanta systemd service exists

### Listening Ports
```
LISTEN  127.0.0.53:53        (DNS resolver)
LISTEN  0.0.0.0:22            (SSH)
LISTEN  127.0.0.54:53         (DNS resolver)
LISTEN  [::]:22               (SSH)
```
- **Result**: No application ports listening (no 3000, 80, 443, etc.)

## Conclusion

**The Corvanta backend application is NOT installed and NOT running.**

The EC2 instance `i-0ce140cb522998b9a` is a clean Ubuntu 24.04 server with only the OS, SSH access, and basic DNS resolver. None of the following are present:
- Application files or directory
- Node.js / npm
- Nginx / Docker / PM2
- Systemd service for Corvanta
- Listening application ports

## Terraform Apply Result

- **0 added, 1 changed, 0 destroyed**
- Security group `sg-0df46ead27b9b657f` SSH ingress updated:
  - Old CIDR: `102.88.114.118/32`
  - New CIDR: `102.88.108.143/32`
- All other resources (EC2, EIP, VPC, subnets, S3, SQS, IAM) unchanged

## Next Action: Install and Deploy Corvanta Backend

**Approval required** before proceeding with:
1. Install Node.js and npm on the EC2 instance
2. Deploy the Corvanta backend application from the project repository
3. Configure Nginx as a reverse proxy (if needed)
4. Set up systemd service for the backend
5. Open HTTP/HTTPS ports and configure the application

Until then, the instance is verified as reachable via SSH but has no backend services running.