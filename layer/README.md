# Lambda Layer - dependencies.zip

Layer ini berisi package Python yang dibutuhkan semua Lambda functions:
- psycopg2-binary==2.9.9
- boto3==1.34.34
- requests==2.31.0
- pandas==2.1.4
- openpyxl==3.1.2

## ⚠️  WAJIB: Build dependencies.zip sebelum terraform apply

### Cara 1: Docker (Recommended - Compatible dengan Lambda)

```bash
cd layer/

docker run --rm \
  -v $(pwd):/output \
  public.ecr.aws/lambda/python:3.11 \
  bash -c "pip install psycopg2-binary==2.9.9 boto3==1.34.34 requests==2.31.0 pandas==2.1.4 openpyxl==3.1.2 \
           -t /tmp/python/ && \
           cd /tmp && zip -r9 /output/dependencies.zip python/"

echo "✅ dependencies.zip created: $(du -sh dependencies.zip)"
```

### Cara 2: EC2 / Cloud9 Amazon Linux 2023

```bash
mkdir -p python
pip3 install psycopg2-binary==2.9.9 boto3==1.34.34 requests==2.31.0 pandas==2.1.4 openpyxl==3.1.2 -t python/
zip -r9 dependencies.zip python/
```

### Cara 3: AWS Lambda Layer ARN publik (psycopg2 saja)

Jika tidak bisa build, gunakan layer publik untuk psycopg2:
- https://github.com/jetbridge/psycopg2-lambda-layer

Letakkan hasil build sebagai `layer/dependencies.zip`
