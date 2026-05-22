# Billing Software

## Project Structure

- `backend` - Spring Boot API
- `frontend` - React/Vite UI
- `Dockerfile` - production image that runs MySQL, the API, and the UI from one container

## Local Docker Build

```bash
docker build -t billing-software:local .
docker run --env-file .env -p 80:80 -v "%cd%/uploads:/app/uploads" -v "%cd%/mysql:/var/lib/mysql" billing-software:local
```

Use `.env.example` as the template for runtime variables.

The container initializes `billing_app` from `billing_app.sql` the first time `/var/lib/mysql` is empty. Keep the MySQL volume mounted if you want database data to survive container rebuilds.

## GitHub Actions EC2 Secrets

This workflow deploys to:

- EC2 user: `ubuntu`
- EC2 host: `13.55.135.40`
- App port: `80`

MySQL runs inside the app container and is persisted on EC2 at `/home/ubuntu/billing-software/mysql`.

Add these repository secrets before enabling deploys from `main`:

- `EC2_SSH_PRIVATE_KEY`
- `SPRING_DATASOURCE_PASSWORD`
- `SPRING_JPA_HIBERNATE_DDL_AUTO`
- `JWT_SECRET_KEY`
- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `CORS_ALLOWED_ORIGINS`

You can set them with:

```powershell
.\scripts\set-github-secrets.ps1 -SshKeyPath C:\path\to\ec2-key.pem `
  -DatasourceUsername root `
  -DatasourcePassword "your-mysql-password"
```

The script generates `JWT_SECRET_KEY` automatically if you do not pass one, prompts for Razorpay values if omitted, and uses EC2 defaults already configured for this project.

S3 is not used. Uploaded images are stored locally in the host-mounted `uploads` directory.
