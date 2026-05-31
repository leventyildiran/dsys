import 'package:flutter_test/flutter_test.dart';
import 'package:dsys/core/hesaplama_motoru.dart';

void main() {
  group('HesaplamaMotoru', () {
    group('kdvHaricMatrahHesapla', () {
      test('KDV %20 ile brüt tutardan matrah hesaplanır', () {
        // 120.000 TL brüt tutar, %20 KDV → matrah = 100.000
        final matrah = HesaplamaMotoru.kdvHaricMatrahHesapla(120000.0, 20);
        expect(matrah, equals(100000.0));
      });

      test('KDV %18 ile hesaplama', () {
        // 118.000 TL brüt, %18 KDV → matrah = 100.000
        final matrah = HesaplamaMotoru.kdvHaricMatrahHesapla(118000.0, 18);
        expect(matrah, equals(100000.0));
      });

      test('KDV %0 ile matrah aynı kalır', () {
        final matrah = HesaplamaMotoru.kdvHaricMatrahHesapla(50000.0, 0);
        expect(matrah, equals(50000.0));
      });

      test('Küçük tutarlarla kuruş hassasiyeti', () {
        // 1.180 TL, %18 KDV → matrah = 1.000
        final matrah = HesaplamaMotoru.kdvHaricMatrahHesapla(1180.0, 18);
        expect(matrah, equals(1000.0));
      });
    });

    group('standartKesintiler', () {
      test('Standart kesintiler doğru hesaplanır', () {
        final sonuc = HesaplamaMotoru.standartKesintiler(
          brutTutar: 120000.0,
          kdvOrani: 20,
          hazinePayiOrani: 5,
          bapPayiOrani: 5,
          aracGerecPayiOrani: 1,
        );

        // Matrah = 100.000
        expect(sonuc.kdvHaricMatrah, equals(100000.0));
        // Hazine = 5.000
        expect(sonuc.hazinePayi, equals(5000.0));
        // BAP = 5.000
        expect(sonuc.bapPayi, equals(5000.0));
        // Araç-Gereç = 1.000
        expect(sonuc.aracGerecPayi, equals(1000.0));
        // Dağıtılabilir = 100.000 - 11.000 = 89.000
        expect(sonuc.dagitilabilirTutar, equals(89000.0));
      });

      test('toplamKesinti getter doğru çalışır', () {
        final sonuc = HesaplamaMotoru.standartKesintiler(
          brutTutar: 120000.0,
          kdvOrani: 20,
          hazinePayiOrani: 5,
          bapPayiOrani: 5,
          aracGerecPayiOrani: 1,
        );

        expect(sonuc.toplamKesinti, equals(11000.0));
      });
    });

    group('sanayiIsbirligiKesintiler (58/k)', () {
      test('58/k kesintilerinde hazine, BAP, araç-gereç sıfır', () {
        final sonuc = HesaplamaMotoru.sanayiIsbirligiKesintiler(
          brutTutar: 120000.0,
          kdvOrani: 20,
        );

        expect(sonuc.hazinePayi, equals(0.0));
        expect(sonuc.bapPayi, equals(0.0));
        expect(sonuc.aracGerecPayi, equals(0.0));
      });

      test('58/k dağıtılabilir tutar %85 matrah olmalı', () {
        final sonuc = HesaplamaMotoru.sanayiIsbirligiKesintiler(
          brutTutar: 120000.0,
          kdvOrani: 20,
        );

        // Matrah = 100.000, %85 = 85.000
        expect(sonuc.dagitilabilirTutar, equals(85000.0));
      });

      test('58/k birim kalanı %15 olmalı', () {
        final sonuc = HesaplamaMotoru.sanayiIsbirligiKesintiler(
          brutTutar: 120000.0,
          kdvOrani: 20,
        );

        // Matrah = 100.000, birim kalanı = 15.000
        expect(sonuc.birimKalani, equals(15000.0));
      });
    });

    group('katsayiSimulasyonu', () {
      test('Basit simülasyonda toplam dağıtılabiliri aşmaz', () {
        final personeller = [
          const PersonelPuanModel(
            personelId: 'p1',
            faaliyetPuani: 100,
            unvanKatsayisi: 1.5,
          ),
          const PersonelPuanModel(
            personelId: 'p2',
            faaliyetPuani: 80,
            unvanKatsayisi: 1.2,
          ),
          const PersonelPuanModel(
            personelId: 'p3',
            faaliyetPuani: 60,
            unvanKatsayisi: 1.0,
          ),
        ];

        final toplamPuan = personeller.fold<double>(
          0,
          (sum, p) => sum + p.bireyselPuan,
        );

        final katsayi = HesaplamaMotoru.katsayiSimulasyonu(
          10000.0,
          toplamPuan,
          personeller,
        );

        // Katsayı pozitif olmalı
        expect(katsayi, greaterThan(0));

        // Toplam hakediş, dağıtılabiliri aşmamalı
        double toplamHakedis = 0;
        for (final p in personeller) {
          toplamHakedis += double.parse(
              (p.bireyselPuan * katsayi).toStringAsFixed(2));
        }
        expect(toplamHakedis, lessThanOrEqualTo(10000.0));
      });

      test('Tek kişi ile simülasyon', () {
        final personeller = [
          const PersonelPuanModel(
            personelId: 'p1',
            faaliyetPuani: 200,
            unvanKatsayisi: 1.0,
          ),
        ];

        final katsayi = HesaplamaMotoru.katsayiSimulasyonu(
          5000.0,
          200.0,
          personeller,
        );

        // 5000 / 200 = 25.00
        expect(katsayi, equals(25.0));
      });
    });

    group('artikBakiyeHesapla', () {
      test('Artık bakiye her zaman >= 0 olmalı', () {
        final personeller = [
          const PersonelPuanModel(
            personelId: 'p1',
            faaliyetPuani: 100,
            unvanKatsayisi: 1.5,
          ),
          const PersonelPuanModel(
            personelId: 'p2',
            faaliyetPuani: 80,
            unvanKatsayisi: 1.2,
          ),
        ];

        final toplamPuan = personeller.fold<double>(
          0,
          (sum, p) => sum + p.bireyselPuan,
        );

        final katsayi = HesaplamaMotoru.katsayiSimulasyonu(
          10000.0,
          toplamPuan,
          personeller,
        );

        final artik = HesaplamaMotoru.artikBakiyeHesapla(
          10000.0,
          katsayi,
          personeller,
        );

        expect(artik, greaterThanOrEqualTo(0));
      });
    });
  });
}
