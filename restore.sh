#!/bin/bash
source ./config.sh

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_name>"
    echo "Example: $0 es_backup_20240203_123456"
    exit 1
fi

BACKUP_NAME=$1
BACKUP_PATH="${TEMP_DIR}/${BACKUP_NAME}"

# Create temporary directory
mkdir -p $TEMP_DIR

# Download from MinIO
mc alias set myminio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY
mc cp "myminio/${MINIO_BUCKET}/${BACKUP_NAME}.tar.gz.gpg" "${BACKUP_PATH}.tar.gz.gpg"

# Decrypt with GPG
gpg --decrypt "${BACKUP_PATH}.tar.gz.gpg" > "${BACKUP_PATH}.tar.gz"

# Extract backup
tar xzf "${BACKUP_PATH}.tar.gz" -C $TEMP_DIR

# Create snapshot repository if it doesn't exist
curl -k -X PUT "https://${ES_HOST}:${ES_PORT}/_snapshot/my_backup" \
  -H "Content-Type: application/json" \
  -u "${ES_USER}:${ES_PASS}" \
  -d '{
    "type": "fs",
    "settings": {
      "location": "'${BACKUP_PATH}'"
    }
  }'

# Get list of backed up indices
INDICES=$(ls "${BACKUP_PATH}" | grep -oP '(?<=es_backup_).*?(?=_\d{8}_\d{6})')

for INDEX in $INDICES; do
  SNAPSHOT_NAME="es_backup_${INDEX}_${BACKUP_DATE}"

  # Check if snapshot exists
  SNAPSHOT_CHECK=$(curl -k -s -o /dev/null -w "%{http_code}" -u "${ES_USER}:${ES_PASS}" \
    "https://${ES_HOST}:${ES_PORT}/_snapshot/my_backup/${SNAPSHOT_NAME}")

  if [ "$SNAPSHOT_CHECK" -ne 200 ]; then
    echo "Snapshot $SNAPSHOT_NAME not found, skipping..."
    continue
  fi

  # Close index before restore
  echo "Closing index: $INDEX"
  curl -k -X POST "https://${ES_HOST}:${ES_PORT}/${INDEX}/_close" \
    -u "${ES_USER}:${ES_PASS}"

  # Restore snapshot
  echo "Restoring snapshot: $SNAPSHOT_NAME for index: $INDEX"
  curl -k -X POST "https://${ES_HOST}:${ES_PORT}/_snapshot/my_backup/${SNAPSHOT_NAME}/_restore" \
    -H "Content-Type: application/json" \
    -u "${ES_USER}:${ES_PASS}" \
    -d '{
      "indices": "'${INDEX}'"
    }'

  # Wait for restore completion
  sleep 10

  # Open index after restore
  echo "Opening index: $INDEX"
  curl -k -X POST "https://${ES_HOST}:${ES_PORT}/${INDEX}/_open" \
    -u "${ES_USER}:${ES_PASS}"
done

# Cleanup
rm -rf "${BACKUP_PATH}" "${BACKUP_PATH}.tar.gz" "${BACKUP_PATH}.tar.gz.gpg"
echo "Restore completed for all indices from backup: ${BACKUP_NAME}"
