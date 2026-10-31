# Angker.id 👻

Aplikasi katalog produk berbasis **Flutter** yang memakai API bawaan **DummyJSON Products**, dengan tema warna pastel. Dibuat untuk Tugas Praktikum 2, Pemrograman Perangkat Bergerak.

## 🎥 Video Demo (YouTube)
[Tonton demo di YouTube](https://youtu.be/VEMXLBi4LbI?si=2r2sizLbsX-k14s9)

## Identitas
- Nama: Fahmi Maulana Sitakar
- NIM:230102042
- Kelas: IF24A
- Mata kuliah: Pemrograman Perangkat Bergerak

## Fitur
| Fitur | Endpoint DummyJSON |
|---|---|
| Halaman depan berisi seluruh produk + infinite scroll | `GET /products?limit=&skip=&select=` |
| Urutkan produk (rating, harga, nama) | `GET /products?sortBy=&order=` |
| Detail produk (galeri, rating, ulasan, spesifikasi) | `GET /products/{id}` |
| Search fungsional (debounce + riwayat) | `GET /products/search?q=` |
| Tab kategori | `GET /products/categories` |
| Chip filter kategori di Beranda & dropdown form | `GET /products/category-list` |
| Produk per kategori | `GET /products/category/{slug}` |
| Tambah produk | `POST /products/add` |
| Edit produk | `PUT /products/{id}` |
| Update cepat stok & harga | `PATCH /products/{id}` |
| Hapus produk | `DELETE /products/{id}` |

Fitur tambahan:
- Splash screen **Angker.id** dengan animasi huruf berjatuhan dan memantul
- Wishlist (tersimpan permanen, ada tombol undo)
- Keranjang dengan pengatur jumlah yang dibatasi stok, voucher (`ANGKERHEMAT`, `HANTULUCU`), dan ringkasan pembayaran
- Rating bintang, distribusi bintang, dan daftar ulasan
- Pull to refresh, shimmer loading, empty state, dan error state dengan tombol coba lagi
- Transisi Hero kartu → detail, animasi kartu bertahap, bottom navigation dengan pill yang bergeser

> Catatan: POST/PUT/PATCH/DELETE di DummyJSON hanya **simulasi**. Server tidak menyimpan perubahan, jadi hasilnya disimpan di state aplikasi selama aplikasi berjalan.

## Tech Stack
Flutter · Dio · Provider · GoRouter · CachedNetworkImage · SharedPreferences · Shimmer · Google Fonts

## Palet Warna
`#F9B2D7` · `#CFECF3` · `#DAF9DE` · `#F6FFDC` (aksen: `#993D71`, `#E37AB2`, `#6FAFC2`, `#5DAA6E`)

## Struktur Kode
```
lib/
├── main.dart, app.dart          # entry point + MultiProvider
├── core/                        # tema, router (go_router), formatter
├── models/                      # Product, Review, Dimensions, Meta, ProductCategory, CartItem
├── services/                    # ApiServiceProducts (semua endpoint) + penyimpanan lokal
├── providers/                   # Product, Category, Search, Wishlist, Cart
├── screens/                     # splash, home, search, detail, category, wishlist, cart, form
└── widgets/                     # kartu produk, stepper, shimmer, state view, dll
```

## Cara Menjalankan
Butuh Flutter 3.27 atau lebih baru.

```bash
# 1. Lengkapi folder platform Android (file yang sudah ada tidak akan ditimpa)
flutter create . --org com.angker --project-name angker_id --platforms android

# 2. Ambil dependency
flutter pub get

# 3. Sambungkan HP (USB debugging aktif), lalu jalankan
flutter devices
flutter run
```

Saat pertama kali dibuka, HP harus terhubung internet (untuk data DummyJSON dan font).


## Catatan Penggunaan AI
[Tulis jujur bagian mana yang dibantu AI, dan bagian mana yang kamu kerjakan atau pelajari sendiri]