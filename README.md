# Absorbed: The Lost Lab

![Game Status](https://img.shields.io/badge/Status-In_Development-yellow)
![Version](https://img.shields.io/badge/Version-v0.1.0-blue)
![Platform](https://img.shields.io/badge/Platform-Desktop-black)
![Engine](https://img.shields.io/badge/Engine-Godot_Engine-blue)

**Absorbed: The Lost Lab** adalah sebuah game *2D Side-scroller* bergenre *Sci-Fi, Adventure, & Puzzle*. Game ini menjembatani kesenjangan antara pembelajaran keselamatan kerja konvensional di buku teks dengan keterlibatan praktis yang imersif. Di sini, protokol K3 laboratorium yang kaku diubah menjadi mekanik perjalanan waktu yang penuh risiko tinggi, di mana setiap keputusan keselamatan memengaruhi alur cerita dan keselamatan karakter secara langsung.

---

##  Sinopsis & Cerita:
Seorang ilmuwan perfeksionis bernama **Xeno** terobsesi untuk membuktikan anomali sejarah setelah melihat penemuan alat modern di lapisan masa lalu. Ia membangun mesin waktu secara diam-diam di laboratoriumnya pada tahun 2112. Namun, akibat kecemasan ekstrem dan sifat cerobohnya yang mengabaikan protokol keselamatan kerja, terjadi kecelakaan fatal yang melemparkannya bersama seluruh laboratorium ke masa prasejarah.

Terbangun dengan amnesia parsial di dunia purba dan reaktor mesin waktu yang rusak total, Xeno harus bertahan hidup, menjelajahi hutan prasejarah yang berbahaya, mengumpulkan sumber daya alam (*gathering*), serta mempelajari kembali keahlian kimianya yang terlupa demi bisa pulang ke tahun 2112.

---

##  Fitur Utama (Core Gameplay):
* **Eksplorasi 2D Side-Scrolling & Interaksi Kontekstual:** Menjelajahi dunia prasejarah yang berbahaya sembari berinteraksi dengan sisa-sisa fasilitas lab yang ikut terlempar.
* **Simulasi Teka-teki K3 (Core Puzzle):** Menguji kepatuhan keselamatan kerja industri nyata secara interaktif, bukan sekadar teori tekstual.
* **Sistem Pengumpulan Bahan (Gathering):** Mengumpulkan sumber daya alam di zaman purba untuk keperluan bertahan hidup dan eksperimen kimia.
* **Player Progression (Sistem Bar Ingatan):** Memulihkan keahlian kimia Xeno secara bertahap seiring berjalannya cerita berbasis *Chapter*.
* **Sistem Banyak Akhir (Multiple Endings):** Setiap keputusan K3 memiliki dampak langsung pada akhir cerita, memberikan daya tarik tinggi untuk dimainkan ulang (*replayability*).
* **Penghargaan Sertifikasi Kompetensi K3:** Pemain yang berhasil menyelesaikan game dengan tingkat kepatuhan keselamatan minimal **95%** akan mendapatkan penghargaan berupa **Sertifikat Kompetensi K3 Digital** langsung di dalam game.

---

## 🎯 Target Market:
1. **Student:** Membantu pelajar mengatasi kebosanan belajar sains konvensional melalui metode petualangan interaktif.
2. **Chem Student:** Menjadi media simulasi digital praktikum K3 industri nyata untuk persiapan masuk laboratorium dan ujian sertifikasi kompetensi.
3. **Gamers:** Menyukai tantangan teka-teki logika, alur cerita misteri fiksi ilmiah, dan sistem *multiple endings*.

---

## 🛠️ Tech Stack & Tools:
* **Engine:** Godot Engine (Desktop Target)
* **Languages:** GDScript
* **Design & UI:** Figma & Canva
* **Assets & Editor:** Custom graphics (ibis Paint Pro), visual presentation assets.

---

## 📂 Arsitektur Proyek (Feature-Based):
Struktur folder *repository* ini dirancang menggunakan pendekatan berbasis fitur (*feature-based*) agar modular dan mudah dirawat:
* `core/` — Autoloads (`global.gd`), pengontrol audio global, dan transisi layar.
* `entities/` — Objek aktif di dunia game (Player, APD station, peralatan kimia, tablet).
* `levels/` — Lingkungan yang dapat dimainkan (Main Lab, minigame Bunsen burner, minigame reaksi tabung).
* `systems/` — Logika sistem game (Quiz manager, aset pertanyaan `.tres`, framework UI & HUD/Bar Ingatan).
* `assets/` — Sumber daya media terbagi (Audio sfx/bgm, Font, Tileset).

---

## Progres Pengembangan:

* **v0.1.0 (Juni 2026):**
  * Refaktorisasi besar-besaran repositori ke struktur folder berbasis fitur.
  * Optimalisasi berkas `.gitignore` untuk menyaring berkas *cache* dan *build artifacts*.
  * Implementasi logika dasar pergerakan karakter (idle, walking, interact) dan stasiun penggantian APD.
  * Penyusunan kerangka awal sistem kuis berbasis tablet, komponen Bunsen burner, dan tata letak laboratorium utama.
* **[Tahapan Selanjutnya]:**
  * Pengembangan sistem *Gathering* bahan alam prasejarah.
  * Implementasi perhitungan persentase kepatuhan K3 untuk kalkulasi kelulusan Sertifikasi Kompetensi.

---

##  Cara Menjalankan Projek:

1. Clone repositori ini:
   ```bash
   git clone [https://github.com/rizkyramadhani10/absorbed-the-lost-lab.git](https://github.com/rizkyramadhani10/absorbed-the-lost-lab.git)

2. Buka Godot Engine (v4.x).
3. Pilih Import, arahkan ke folder hasil klon, lalu pilih berkas project.godot.
