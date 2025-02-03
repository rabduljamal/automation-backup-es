# Backup dan Restore Elasticsearch dengan MinIO dan GPG

Skrip ini digunakan untuk melakukan backup dan restore indeks Elasticsearch secara terpisah, dengan penyimpanan di MinIO serta enkripsi menggunakan GPG.

## **Persyaratan**

- Elasticsearch dengan API snapshot diaktifkan
- MinIO sebagai penyimpanan backup
- `mc` (MinIO Client) untuk mengelola file di MinIO
- `gpg` untuk enkripsi dan dekripsi backup
- Bash untuk menjalankan skrip

## **Konfigurasi**

Buat file `config.sh` dengan isi berikut:

```bash
# Elasticsearch
ES_HOST="your-es-host"
ES_PORT="9200"
ES_USER="your-es-username"
ES_PASS="your-es-password"

# MinIO
MINIO_ENDPOINT="https://your-minio-endpoint"
MINIO_ACCESS_KEY="your-access-key"
MINIO_SECRET_KEY="your-secret-key"
MINIO_BUCKET="your-bucket-name"

# Temporary Directory for Backup
TEMP_DIR="/path/to/temp/dir"

# GPG Encryption
GPG_RECIPIENT="your-gpg-recipient"
```

---

## **Backup Indeks Elasticsearch**

Skrip `backup.sh` akan membuat snapshot per indeks dan mengunggahnya ke MinIO.

### **Cara Menggunakan:**

```bash
chmod +x backup.sh
./backup.sh
```

### **Proses yang Dilakukan:**

1. Membuat direktori sementara untuk menyimpan backup.
2. Mengambil daftar indeks dari Elasticsearch.
3. Membuat snapshot untuk setiap indeks.
4. Mengompresi hasil backup dengan tar.
5. Mengenkripsi backup dengan GPG.
6. Mengunggah backup ke MinIO.
7. Membersihkan file sementara.

---

## **Restore Indeks Elasticsearch**

Skrip `restore.sh` akan mengunduh backup dari MinIO, mendekripsi, dan merestore setiap indeks secara terpisah.

### **Cara Menggunakan:**

```bash
chmod +x restore.sh
./restore.sh <backup_name>
```

Contoh:

```bash
./restore.sh es_backup_20240203_123456
```

### **Proses yang Dilakukan:**

1. Mengunduh backup dari MinIO.
2. Mendekripsi backup menggunakan GPG.
3. Mengekstrak backup.
4. Membuat repositori snapshot jika belum ada.
5. Mengecek snapshot dan memulihkan indeks satu per satu.
6. Membersihkan file sementara.

---

## **Catatan Penting**

- Pastikan MinIO sudah dikonfigurasi dengan benar.
- Jangan lupa menambahkan public key penerima ke GPG sebelum menjalankan backup.
- Gunakan akun dengan izin yang cukup untuk membuat snapshot dan memulihkan indeks di Elasticsearch.
- Pastikan tidak ada snapshot yang sedang berjalan sebelum menjalankan restore.

---

## **Troubleshooting**

- **MinIO tidak terhubung?**
  - Pastikan `mc alias set` sudah dijalankan dengan kredensial yang benar.
- **GPG gagal mendekripsi?**
  - Pastikan kunci GPG penerima sudah ditambahkan di sistem.
- **Elasticsearch gagal membuat snapshot?**
  - Periksa pengaturan snapshot repository dan pastikan direktori penyimpanan memiliki izin yang cukup.

---

## **Lisensi**

Proyek ini menggunakan lisensi MIT.

---

Happy Backup & Restore! 🚀
