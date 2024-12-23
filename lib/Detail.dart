import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'AdMobConfig.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class Surat {
  final int nomor;
  final String nama;
  final String namaLatin;
  final int jumlahAyat;
  final String tempatTurun;
  final String arti;
  final String deskripsi;
  final List<Ayat> ayat;

  Surat({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
    required this.deskripsi,
    required this.ayat,
  });

  factory Surat.fromJson(Map<String, dynamic> json) {
    return Surat(
      nomor: json['nomor'],
      nama: json['nama'],
      namaLatin: json['namaLatin'],
      jumlahAyat: json['jumlahAyat'],
      tempatTurun: json['tempatTurun'],
      arti: json['arti'],
      deskripsi: json['deskripsi'],
      ayat: List<Ayat>.from(json['ayat'].map((x) => Ayat.fromJson(x))),
    );
  }
}

class Ayat {
  final int nomorAyat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;
  final String audio;
  bool isPlaying;
  
  Ayat({
    required this.nomorAyat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
    required this.audio,
	this.isPlaying = false,
  });

  factory Ayat.fromJson(Map<String, dynamic> json) {
    return Ayat(
      nomorAyat: json['nomorAyat'],
      teksArab: json['teksArab'],
      teksLatin: json['teksLatin'],
      teksIndonesia: json['teksIndonesia'],
      audio: json['audio']['01'],
	  isPlaying: false,
    );
  }
}

class SuratDetail extends StatefulWidget {
  final int nomor;

  SuratDetail({required this.nomor});

  @override
  _SuratDetailState createState() => _SuratDetailState();
}

class _SuratDetailState extends State<SuratDetail> {
  Future<Surat>? suratDetail;
  int currentAyatCount = 10;
  late BannerAd _bannerAd;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    suratDetail = fetchSuratDetail(widget.nomor);
    _bannerAd = BannerAd(
      adUnitId: AdMobConfig.adUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _bannerAd.dispose();
    super.dispose();
  }

  Future<Surat> fetchSuratDetail(int nomor) async {
    final response = await http.get(Uri.parse('https://api.i-as.dev/api/quran/surat/$nomor'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return Surat.fromJson(data);
    } else {
      throw Exception('Failed to load Surat Detail');
    }
  }

  Future<void> _playPauseAudio(String url) async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Surat Detail', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: FutureBuilder<Surat>(
          future: suratDetail,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red, fontSize: 16.0)));
            } else if (snapshot.hasData) {
              var surat = snapshot.data!;
              String deskripsiText = _stripHtml(surat.deskripsi);

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${surat.namaLatin} (${surat.nama})',
                            style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.book, size: 16.0, color: Colors.white),
                                SizedBox(width: 4.0),
                                Text('${surat.jumlahAyat}', style: TextStyle(color: Colors.white, fontSize: 16.0)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue),
                              SizedBox(width: 5.0),
                              Text('${surat.tempatTurun}', style: TextStyle(fontSize: 14.0, color: Colors.black87)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.g_translate, color: Colors.blue),
                              SizedBox(width: 5.0),
                              Text('${surat.arti}', style: TextStyle(fontSize: 14.0, color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10.0),
                      Text(deskripsiText, style: TextStyle(fontSize: 16.0, color: Colors.black87)),
                      if (_bannerAd != null)
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 16.0),
                          height: _bannerAd.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd),
                        ),
                      SizedBox(height: 20.0),
						ListView.builder(
						  shrinkWrap: true,
						  physics: NeverScrollableScrollPhysics(),
						  itemCount: surat.ayat.length < currentAyatCount ? surat.ayat.length : currentAyatCount,
						  itemBuilder: (context, index) {
							var ayat = surat.ayat[index];
							bool isPlaying = ayat.isPlaying;

							return InkWell(
							  onTap: () {
								showDialog(
								  context: context,
								  builder: (BuildContext context) {
									return AlertDialog(
									  backgroundColor: Colors.white,
									  title: Text('Artinya (${ayat.nomorAyat})'),
									  content: Column(
										mainAxisSize: MainAxisSize.min,
										children: [
										  Text('${ayat.teksIndonesia}'),
										],
									  ),
									  actions: [
										TextButton(
										  onPressed: () {
											Navigator.pop(context);
										  },
										  child: Text('Tutup', style: TextStyle(color: Colors.blue)),
										),
									  ],
									);
								  },
								);
							  },
							  child: Card(
								margin: EdgeInsets.symmetric(vertical: 8.0),
								elevation: 3.0,
								shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
								color: Colors.white,
								child: Column(
								  crossAxisAlignment: CrossAxisAlignment.start,
								  children: [
									Padding(
									  padding: const EdgeInsets.all(16.0),
									  child: Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
										  Container(
											padding: EdgeInsets.all(10.0),
											decoration: BoxDecoration(
											  color: Colors.blue,
											  shape: BoxShape.circle,
											),
											child: Text(
											  '${ayat.nomorAyat}',
											  style: TextStyle(
												fontSize: 22.0,
												fontWeight: FontWeight.bold,
												color: Colors.white,
											  ),
											),
										  ),
											ElevatedButton.icon(
											  onPressed: () {
												setState(() {
												  ayat.isPlaying = !ayat.isPlaying;
												  if (ayat.isPlaying) {
													_audioPlayer.setUrl(ayat.audio);
													_audioPlayer.play();
													_audioPlayer.processingStateStream.listen((state) {
													  if (state == ProcessingState.completed) {
														setState(() {
														  ayat.isPlaying = false;
														});
													  }
													});
												  } else {
													_audioPlayer.pause();
												  }
												});
											  },
											  icon: Icon(
												ayat.isPlaying ? Icons.stop : Icons.volume_up,
												color: Colors.blue,
												size: 30,
											  ),
											  label: Text('', style: TextStyle(color: Colors.white, fontSize: 12.0)),
											  style: ElevatedButton.styleFrom(
												backgroundColor: Colors.transparent,
												shape: RoundedRectangleBorder(
												  borderRadius: BorderRadius.circular(30),
												),
												padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
												elevation: 0,
												shadowColor: Colors.transparent,
												overlayColor: Colors.transparent,
											  ),
											),
										],
									  ),
									),
									SizedBox(height: 10.0),
									ListTile(
									  title: Text(
										'${ayat.teksArab}',
										style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87),
										textAlign: TextAlign.right,
									  ),
									  subtitle: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
										  SizedBox(height: 15.0),
										  Text(
											ayat.teksLatin,
											style: TextStyle(fontSize: 16.0, color: Colors.black87),
										  ),
										  SizedBox(height: 15.0),
										],
									  ),
									),
								  ],
								),
							  ),
							);
						  },
						),
                      if (surat.ayat.length > currentAyatCount)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentAyatCount += 10;
                                });
                              },
                              child: Text('Ayat Selanjutnya', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                elevation: 3,
                                textStyle: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            } else {
              return Center(child: Text('Tidak ada data', style: TextStyle(color: Colors.black87)));
            }
          },
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true);
    return html.replaceAll(exp, '');
  }
}
