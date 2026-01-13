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

## Cara Bikin (Ringkas)
1) **Bootstrap Flutter app**
   - `flutter create delivery_app`
   - Atur UI halaman: home, detail, cart, checkout, payment, activity, profile.
2) **Buat backend Express**
   - Init: `npm init -y`, install `express`, `sqlite3`, `dotenv`, `jsonwebtoken`, `zod`, `midtrans-client`, dll.
   - Buat struktur `backend/src` + routes/controllers.
3) **Database SQLite**
   - Tambahkan migrasi: products, users, orders, order_items, cart_items, ulasan, promos, addresses.
   - Jalankan `npm run migrate` untuk create table.
4) **Integrasi API di Flutter**
   - Buat service layer (`lib/services/*`) untuk auth, products, cart, orders, reviews.
   - Set base URL di `lib/services/app_services.dart` (port harus sesuai backend).
5) **Payment QRIS**
   - Simpan key di `backend/.env`.
   - Generate QR lewat Midtrans sandbox dan tampilkan QR di UI.

## Struktur Folder (Ringkas)
- `lib/` → UI Flutter & logic app
- `backend/src/` → API, database, dan logic server
- `lib/assets/` → gambar & asset UI

## Catatan
- Gunakan Midtrans sandbox untuk testing QRIS.
- Jika ada error asset gambar, cek path di `pubspec.yaml`.
- Jika backend port berbeda, sesuaikan `PORT` di `.env` **dan** base URL di `lib/services/app_services.dart`.
