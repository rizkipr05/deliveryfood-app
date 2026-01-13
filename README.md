# Delivery App (Flutter + Node.js)

Aplikasi delivery makanan: jelajah produk, promo, detail menu, keranjang, checkout, pembayaran QRIS (Midtrans sandbox), aktivitas pesanan, dan profil + ulasan.

## Fitur Utama
- Home: list produk, kategori, promo
- Detail produk: menu lainnya, ulasan, tambah keranjang
- Keranjang & checkout
- Pembayaran (Midtrans QRIS sandbox)
- Aktivitas pesanan (riwayat & proses)
- Profil + upload avatar
- Alamat pengiriman

## Tech Stack
- Frontend: Flutter (Dart)
- Backend: Node.js + Express
- Database: SQLite
- Payment: Midtrans (sandbox)

## Menjalankan Project

### 1) Backend (API)
```bash
cd /Delivery-app/backend
npm install
npm run migrate
npm run dev
```
Backend jalan di `http://localhost:3002` (bisa diubah via `PORT` di `.env`).

#### Contoh `backend/.env`
```env
PORT=3002
DATABASE_PATH=./data/app.sqlite
MIDTRANS_SERVER_KEY=...
MIDTRANS_CLIENT_KEY=...
MIDTRANS_IS_PRODUCTION=false
```

### 2) Frontend (Flutter)
```bash
cd /Delivery-app
flutter pub get
flutter run
```

## Struktur Folder (Ringkas)
- `lib/` → UI Flutter & logic app
- `backend/src/` → API, database, dan logic server
- `lib/assets/` → gambar & asset UI

## Catatan
- Gunakan Midtrans sandbox untuk testing QRIS.
- Jika ada error asset gambar, cek path di `pubspec.yaml`.
