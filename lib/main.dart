import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'Detail.dart';
import 'AdMobConfig.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<List<Surat>> fetchSurat() async {
  final response = await http.get(Uri.parse('https://api.i-as.dev/api/quran/surat'));

  if (response.statusCode == 200) {
    var data = json.decode(response.body) as List;
    return data.map((json) => Surat.fromJson(json)).toList();
  } else {
    throw Exception('Terjadi Kesalahan Coba Lagi!');
  }
}

class Surat {
  final int nomor;
  final String nama;
  final String namaLatin;
  final int jumlahAyat;
  final String tempatTurun;
  final String arti;
  final String deskripsi;

  Surat({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
    required this.deskripsi,
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
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SuratList(),
      theme: ThemeData(
        primaryColor: Colors.blue,
        fontFamily: 'SansSerif',
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}

class SuratList extends StatefulWidget {
  @override
  _SuratListState createState() => _SuratListState();
}

class _SuratListState extends State<SuratList> {
  Future<List<Surat>>? suratList;
  bool _isSearchVisible = false;
  TextEditingController _searchController = TextEditingController();
  late BannerAd _bannerAd;
  
  @override
  void initState() {
    super.initState();
    suratList = fetchSurat();
	
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
    _bannerAd.dispose();
    super.dispose();
  }
  
  Future<void> _refreshSuratList() async {
    setState(() {
      suratList = fetchSurat();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshSuratList,
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
              });
            },
          ),
        ],
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 36.0),
            SizedBox(width: 8.0),
            Text('Al-Qur\'an', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),

      body: Column(
        children: [
          if (_isSearchVisible)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari...',
                  prefixIcon: Icon(Icons.search),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (query) {
                  setState(() {
                    suratList = fetchSurat().then((allSurat) {
                      return allSurat
                          .where((surat) =>
                              surat.namaLatin.toLowerCase().contains(query.toLowerCase()) ||
                              surat.nama.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                    });
                  });
                },
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshSuratList,
              child: FutureBuilder<List<Surat>>(
                future: suratList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}', style: TextStyle(color: Colors.red)));
                  } else if (snapshot.hasData) {
                    var suratList = snapshot.data!;
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: suratList.length,
                      itemBuilder: (context, index) {
                        var surat = suratList[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 3.0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          color: Colors.white,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16.0),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text('${surat.nomor}', style: TextStyle(color: Colors.white)),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text('${surat.namaLatin} (${surat.nama})', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
                                      Text('${surat.jumlahAyat}', style: TextStyle(color: Colors.white, fontSize: 12.0)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 18.0, color: Colors.blue),
                                      SizedBox(width: 10.0),
                                      Expanded(
                                        child: Text('${surat.tempatTurun}', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6.0),
                                  Row(
                                    children: [
                                      Icon(Icons.g_translate, size: 18.0, color: Colors.blue),
                                      SizedBox(width: 10.0),
                                      Expanded(
                                        child: Text('${surat.arti}', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.0),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SuratDetail(nomor: surat.nomor),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('Tidak ada data', style: TextStyle(color: Colors.black)));
                  }
                },
              ),
            ),
          ),
          if (_bannerAd != null)
            Container(
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
    );
  }
}
