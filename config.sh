#!/bin/bash
ES_HOST="localhost"
ES_PORT="9200"
ES_USER="elastic"
ES_PASS="your_password"
GPG_RECIPIENT="your.email@domain.com"  # Email associated with your GPG key
TEMP_DIR="/tmp/es_backup"
MINIO_ENDPOINT="http://your-minio:9000"
MINIO_ACCESS_KEY="your_access_key"
MINIO_SECRET_KEY="your_secret_key"
MINIO_BUCKET="es-backups"