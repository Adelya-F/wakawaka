# 🚀 LKS Serverless Order Management — Terraform Infrastructure

**Case Study:** Serverless Event-Driven Automation with AWS  
**Source Code:** https://github.com/handipradana/wakawaka.git  
**Region:** us-east-1 | **Runtime:** Python 3.11 | **DB:** PostgreSQL 15

---

## 📁 Struktur Direktori

```
terraform-lks/
├── main.tf                           # Root module — orchestrates semua
├── variables.tf
├── outputs.tf
├── terraform.tfvars                  # ⚠️  EDIT INI DULU
├── amplify.yml                       # AWS Amplify build config
│
├── modules/
│   ├── vpc/          VPC, Subnets, Security Groups, VPC Endpoints
│   ├── s3/           Bucket orders + logs (versioning, lifecycle, CORS)
│   ├── rds/          PostgreSQL 15.x db.t3.micro
│   ├── sns/          SNS topic + email subscription
│   ├── lambda/       6 Lambda functions + Layer
│   ├── stepfunctions/ State machine order workflow
│   ├── apigateway/   REST API + Usage Plan + API Key
│   ├── eventbridge/  3 EventBridge rules
│   └── cloudwatch/   4 Alarms + Dashboard
│
├── lambda/                           # Source code dari instruktur
│   ├── order_management/lambda_function.py
│   ├── process_payment/lambda_function.py
│   ├── update_inventory/lambda_function.py
│   ├── send_notification/lambda_function.py
│   ├── generate_report/lambda_function.py
│   └── init_database/lambda_function.py
│
├── layer/
│   ├── README.md     ← Cara build dependencies.zip
│   └── dependencies.zip  ⚠️  HARUS DIBUILD DULU
│
├── frontend/
│   ├── index.html    UI dari instruktur
│   └── app.js        JavaScript dari instruktur
│
├── step_function/
│   └── order.json    Contoh input Step Functions
│
└── .github/workflows/
    └── deploy.yml    CI/CD GitHub Actions dari instruktur
```

---

## ⚙️  Prasyarat

- [ ] Terraform >= 1.3.0
- [ ] AWS CLI configured (AWS Academy / Learner Lab)
- [ ] Docker (untuk build Lambda Layer)
- [ ] Git

---

## 🔧 Langkah Deploy

### Step 1 — Edit terraform.tfvars

```hcl
your_name          = "namaanda"        # huruf kecil, tanpa spasi
notification_email = "email@anda.com"
```

### Step 2 — Build Lambda Layer (WAJIB)

```bash
cd layer/

docker run --rm \
  -v $(pwd):/output \
  public.ecr.aws/lambda/python:3.11 \
  bash -c "pip install psycopg2-binary==2.9.9 boto3==1.34.34 \
           requests==2.31.0 pandas==2.1.4 openpyxl==3.1.2 \
           -t /tmp/python/ && \
           cd /tmp && zip -r9 /output/dependencies.zip python/"

cd ..
```

### Step 3 — Terraform Init & Apply

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

> ⏳ Estimasi waktu: 15–20 menit (RDS butuh ~10 menit)

### Step 4 — Inisialisasi Database

```bash
aws lambda invoke \
  --function-name lks-lambda-init-db \
  --payload '{"insert_sample_data": true}' \
  --region us-east-1 \
  response.json

cat response.json
```

### Step 5 — Ambil Output untuk Amplify

```bash
terraform output api_gateway_url    # → API_ENDPOINT
terraform output -raw api_key_value # → API_KEY
```

### Step 6 — Deploy Frontend ke AWS Amplify

1. Buat Amplify app di AWS Console: **lks-amplify-order-app**
2. Hubungkan ke GitHub repository (branch: master)
3. Set environment variables:
   - `API_ENDPOINT` = URL dari output step 5
   - `API_KEY` = key dari output step 5
4. File `amplify.yml` sudah ada di root repo

### Step 7 — Setup GitHub Secrets untuk CI/CD

Di GitHub repository → Settings → Secrets → Actions:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

---

## 📊 Resource yang Dibuat

| Service | Resource Name | Keterangan |
|---------|---------------|------------|
| VPC | lks-vpc-serverless | CIDR 20.1.0.0/20 |
| Subnet | lks-public-subnet-1,2 | 20.1.0.0/25, 20.1.1.0/25 |
| Subnet | lks-private-subnet-1,2 | 20.1.11.0/25, 20.1.12.0/25 |
| Security Group | lks-sg-lambda, lks-sg-rds | |
| VPC Endpoints | lks-s3/eventbridge/steps/sns-endpoints | |
| S3 | lks-orders-{name}-2026 | Versioning + lifecycle |
| S3 | lks-logs-{name}-2026 | Lifecycle 90 days |
| RDS | lks-rds-orders | PostgreSQL 15, db.t3.micro |
| Lambda | lks-lambda-order-management | 512MB, 30s |
| Lambda | lks-lambda-process-payment | 512MB, 30s |
| Lambda | lks-lambda-update-inventory | 256MB, 45s |
| Lambda | lks-lambda-send-notification | 256MB, 60s |
| Lambda | lks-lambda-generate-report | 1024MB, 60s |
| Lambda | lks-lambda-init-db | 512MB, 300s |
| Layer | lks-layer-dependencies | Python packages |
| SNS | lks-sns-order-notifications | Email subscription |
| API Gateway | lks-api-orders | REST + TLS 1.3 |
| Usage Plan | lks-usage-plan | 1000 rps, 100k/month |
| API Key | lks-api-key | |
| Step Functions | lks-stepfunctions-order-workflow | Standard |
| EventBridge | lks-eventbridge-daily-report | cron 23:59 |
| EventBridge | lks-eventbridge-order-status | custom pattern |
| EventBridge | lks-eventbridge-low-stock | rate 1 hour |
| CloudWatch | lks-dashboard-serverless | 4 widgets |
| Alarms | lks-alarm-* | 4 alarms |

---

## 🧪 Testing API

```bash
API_URL=$(terraform output -raw api_gateway_url)
API_KEY=$(terraform output -raw api_key_value)

# List orders
curl -H "x-api-key: $API_KEY" "$API_URL/orders"

# List customers
curl -H "x-api-key: $API_KEY" "$API_URL/customers"

# List products
curl -H "x-api-key: $API_KEY" "$API_URL/products"

# Create order
curl -X POST \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "CUST001",
    "items": [
      {"product_id": "PROD001", "quantity": 1},
      {"product_id": "PROD002", "quantity": 2}
    ]
  }' \
  "$API_URL/orders"

# Check workflow status (gunakan order_id dari response create)
curl -H "x-api-key: $API_KEY" "$API_URL/status/{order_id}"
```

---

## 🗑️  Cleanup

```bash
terraform destroy -auto-approve
```
