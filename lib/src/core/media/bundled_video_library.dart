/// The Manim template renders that ship inside the app bundle.
///
/// The gallery is fed by the backend, which means it is empty on a fresh
/// install, on a flaky connection, and in every offline session — the three
/// situations where a reviewer is most likely to open it. These nine clips are
/// bundled so there is always something to play; they are the same renders the
/// template pack produces, at 854px wide so the whole set costs ~1.7 MB.
class BundledVideo {
  const BundledVideo({
    required this.id,
    required this.assetPath,
    required this.title,
    required this.subject,
    required this.seconds,
    required this.transcript,
  });

  final String id;
  final String assetPath;
  final String title;

  /// Subject and topic, e.g. `Fisika · gelombang`.
  final String subject;
  final int seconds;
  final String transcript;

  String get durationLabel =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
}

class BundledVideoLibrary {
  const BundledVideoLibrary._();

  static const videos = <BundledVideo>[
    BundledVideo(
      id: 'bundled-graph-explanation',
      assetPath: 'assets/videos/graph_explanation.mp4',
      title: 'Limit dan laju perubahan',
      subject: 'Matematika · turunan',
      seconds: 31,
      transcript:
          'Turunan adalah nilai yang didekati oleh kemiringan. Saat selangnya '
          'mengecil, garis potong berputar sampai menyinggung kurva — di x = 2 '
          'kemiringannya berhenti di 4.',
    ),
    BundledVideo(
      id: 'bundled-object-construction',
      assetPath: 'assets/videos/object_construction.mp4',
      title: 'Dari bentuk sederhana ke rumah',
      subject: 'Geometri · membangun objek',
      seconds: 14,
      transcript:
          'Sebuah rumah hanya tersusun dari persegi, segitiga, garis, dan satu '
          'titik. Setiap bagian ditambahkan satu per satu.',
    ),
    BundledVideo(
      id: 'bundled-projectile-scene',
      assetPath: 'assets/videos/projectile_scene.mp4',
      title: 'Lemparan yang menjadi persamaan',
      subject: 'Fisika · gerak parabola',
      seconds: 19,
      transcript:
          'Lintasan benda yang dilempar berbentuk parabola. Tinggi maksimum '
          'dan jangkauan terbaca langsung dari lengkungannya.',
    ),
    BundledVideo(
      id: 'bundled-fourier-epicycles',
      assetPath: 'assets/videos/fourier_epicycles.mp4',
      title: 'Lingkaran yang menggambar bentuk',
      subject: 'Matematika · deret Fourier',
      seconds: 25,
      transcript:
          'Enam puluh empat lingkaran berputar bertingkat. Ujung penanya '
          'menelusuri kembali bentuk semula.',
    ),
    BundledVideo(
      id: 'bundled-linear-transform',
      assetPath: 'assets/videos/linear_transform.mp4',
      title: 'Matriks menekuk ruang',
      subject: 'Matematika · aljabar linear',
      seconds: 19,
      transcript:
          'Sebuah matriks memindahkan seluruh bidang. Garis grid tetap lurus '
          'dan sejajar; eigenvektor bertahan pada garisnya sendiri.',
    ),
    BundledVideo(
      id: 'bundled-ripple-interference',
      assetPath: 'assets/videos/ripple_interference.mp4',
      title: 'Dua sumber, satu pola',
      subject: 'Fisika · gelombang',
      seconds: 20,
      transcript:
          'Ketika dua riak bertemu, keduanya saling menguatkan dan '
          'meniadakan. Sumber yang direnggangkan membuat polanya makin rapat.',
    ),
    BundledVideo(
      id: 'bundled-chaos-pendulum',
      assetPath: 'assets/videos/chaos_pendulum.mp4',
      title: 'Dua awal yang nyaris sama',
      subject: 'Fisika · sistem dinamis',
      seconds: 21,
      transcript:
          'Selisih seperseribu radian. Lima detik pertama keduanya bergerak '
          'seolah satu benda, lalu tidak lagi berhubungan.',
    ),
    BundledVideo(
      id: 'bundled-chem-energy-profile',
      assetPath: 'assets/videos/chem_energy_profile.mp4',
      title: 'Profil energi termokimia',
      subject: 'Kimia · termokimia',
      seconds: 21,
      transcript:
          'Perubahan entalpi dapat dibaca dari posisi energi reaktan dan '
          'produk pada diagram energi.',
    ),
    BundledVideo(
      id: 'bundled-folk-tale',
      assetPath: 'assets/videos/folk_tale.mp4',
      title: 'Malin Kundang',
      subject: 'Bahasa · dongeng Nusantara',
      seconds: 37,
      transcript:
          'Di sebuah desa nelayan, Malin tinggal berdua dengan ibunya. '
          'Setelah kaya, ia menolak mengakuinya — dan berubah menjadi batu.',
    ),
  ];
}
