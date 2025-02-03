#!/bin/bash
source ./config.sh

# Create temporary directory
mkdir -p $TEMP_DIR

# Get current date for backup name
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)

# Create snapshot repository
curl -k -X PUT "https://${ES_HOST}:${ES_PORT}/_snapshot/my_backup" \
  -H "Content-Type: application/json" \
  -u "${ES_USER}:${ES_PASS}" \
  -d '{
    "type": "fs",
    "settings": {
      "location": "'${TEMP_DIR}'"
    }
  }'

# Get list of indices
INDICES=$(curl -k -s -X GET "https://${ES_HOST}:${ES_PORT}/_cat/indices?h=index" \
  -u "${ES_USER}:${ES_PASS}" | tr -d '\r')

# Loop through each index and create a snapshot
for INDEX in $INDICES; do
  BACKUP_NAME="es_backup_${INDEX}_${BACKUP_DATE}"
  BACKUP_PATH="${TEMP_DIR}/${BACKUP_NAME}"

  echo "Creating snapshot for index: $INDEX"
  curl -k -X PUT "https://${ES_HOST}:${ES_PORT}/_snapshot/my_backup/${BACKUP_NAME}" \
    -H "Content-Type: application/json" \
    -u "${ES_USER}:${ES_PASS}" \
    -d '{
      "indices": "'${INDEX}'"
    }'

  # Wait for snapshot completion
  sleep 10

  # Compress backup
  tar czf "${BACKUP_PATH}.tar.gz" -C $TEMP_DIR $BACKUP_NAME

  # Encrypt with GPG
  gpg --recipient "$GPG_RECIPIENT" --encrypt "${BACKUP_PATH}.tar.gz"

  # Upload to MinIO using mc client
  mc alias set myminio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY
  mc cp "${BACKUP_PATH}.tar.gz.gpg" "myminio/${MINIO_BUCKET}/${BACKUP_NAME}.tar.gz.gpg"

  # Cleanup
  rm -rf "${BACKUP_PATH}" "${BACKUP_PATH}.tar.gz" "${BACKUP_PATH}.tar.gz.gpg"

  echo "Backup completed for index: $INDEX"
done

echo "All backups completed and uploaded to MinIO."
