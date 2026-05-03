# 🧹 Mac Cleaner

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)
[![Release](https://img.shields.io/github/v/release/orchivillando/MacCleaner)](../../releases)

Aplikasi macOS sederhana berbasis **SwiftUI** untuk membersihkan file sampah dan membebaskan ruang penyimpanan di Mac Anda.

---

## ✨ Fitur

| Kategori | Path yang di-scan |
|---|---|
| 🗂 User Caches | `~/Library/Caches` |
| 📝 User Logs | `~/Library/Logs` |
| ⏰ Temp Files | `/tmp` |
| 🗑 Sampah (Trash) | `~/.Trash` |

- Scan semua kategori sekaligus dengan satu klik
- Lihat ukuran & jumlah file per kategori
- Pilih/batalkan kategori sebelum membersihkan
- File dipindah ke Trash (aman), isi Trash dihapus permanen
- Tampilan modern mengikuti gaya macOS

---

## 📥 Install

### Via DMG *(Direkomendasikan)*
1. Download file `.dmg` dari [**Releases**](../../releases/latest)
2. Buka file DMG → drag **MacCleaner.app** ke **Applications**
3. **Pertama kali**: klik kanan → **Open** (bypass Gatekeeper)

### Build dari Source
```bash
git clone https://github.com/orchivillando/MacCleaner.git
cd MacCleaner
open MacCleaner.xcodeproj
# Tekan ⌘R di Xcode
```

---

## 🖥 Requirement

- macOS **13.0 Ventura** atau lebih baru
- Xcode 15+ *(hanya untuk build dari source)*

---

## 📸 Screenshot

> Tampilan utama dengan sidebar kategori, daftar file, dan progress scanning.
> <img width="1017" height="813" alt="Screenshot 2026-05-03 at 17 08 39" src="https://github.com/user-attachments/assets/4d481c12-26dd-4b87-8e77-9bf56d4d4c4c" />
> <img width="1017" height="813" alt="Screenshot 2026-05-03 at 17 09 13" src="https://github.com/user-attachments/assets/ffe5ea65-9404-4c1b-835e-dabd0879f299" />


---

## 📄 License

[MIT](LICENSE) © 2025 orchivillando
