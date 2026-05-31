import 'package:flutter_test/flutter_test.dart';
import 'package:dsys/core/karar_metni_servisi.dart';

void main() {
  group('KararMetniServisi', () {
    group('Şablon A (Standart) doğrulama', () {
      test('Tüm alanlar dolu — geçerli', () {
        final veriler = {
          'BIRIM_AD': 'UBATAM',
          'BIRIM_EVRAK_TARIHI': '01.05.2026',
          'BIRIM_EVRAK_SAYISI': 'E-12345',
          'BIRIM_KURUL_TARIHI': '15.04.2026',
          'BIRIM_TOPLANTI_SAYI': '5',
          'BIRIM_KARAR_NO': '2026/12',
          'YK_KARAR_TARIHI': '20.04.2026',
          'YK_KARAR_NO': '2026/45',
          'FIRMA_UNVAN': 'ABC Mühendislik Ltd.',
          'ISIN_KONUSU': 'Teknik Danışmanlık',
          'DANISMANLIK_SURESI': '6',
          'HOCA_UNVAN': 'Prof. Dr.',
          'HOCA_AD_SOYAD': 'Ali Veli',
          'KATSAYI': '19,50',
        };

        final sonuc = KararMetniServisi.dogrula(
          isStandart: true,
          veriler: veriler,
        );

        expect(sonuc.gecerli, isTrue);
        expect(sonuc.eksikAlanlar, isEmpty);
      });

      test('Eksik alan varsa — geçersiz', () {
        final veriler = <String, String?>{
          'BIRIM_AD': 'UBATAM',
          'BIRIM_EVRAK_TARIHI': null,
          'BIRIM_EVRAK_SAYISI': 'E-12345',
          'BIRIM_KURUL_TARIHI': null,
          'BIRIM_TOPLANTI_SAYI': '5',
          'BIRIM_KARAR_NO': '2026/12',
          'YK_KARAR_TARIHI': '20.04.2026',
          'YK_KARAR_NO': '2026/45',
          'FIRMA_UNVAN': 'ABC Ltd.',
          'ISIN_KONUSU': 'Danışmanlık',
          'DANISMANLIK_SURESI': '6',
          'HOCA_UNVAN': 'Prof. Dr.',
          'HOCA_AD_SOYAD': 'Ali Veli',
          'KATSAYI': '19,50',
        };

        final sonuc = KararMetniServisi.dogrula(
          isStandart: true,
          veriler: veriler,
        );

        expect(sonuc.gecerli, isFalse);
        expect(sonuc.eksikAlanlar, isNotEmpty);
      });
    });

    group('Şablon B (58/k) doğrulama', () {
      test('Tüm alanlar dolu — geçerli', () {
        final veriler = {
          'UYK_KARAR_TARIHI': '20.04.2026',
          'UYK_TOPLANTI_SAYI': '3',
          'UYK_KARAR_NO': '2026/7',
          'FIRMA_UNVAN': 'XYZ A.Ş.',
          'HOCA_UNVAN': 'Doç. Dr.',
          'HOCA_AD_SOYAD': 'Mehmet Can',
          'HIZMET_BASLANGIC_TARIHI': '01.01.2026',
          'HIZMET_BITIS_TARIHI': '30.06.2026',
          'DANISMANLIK_SURESI': '6',
          'GELIR_TUTARI': '100.000,00',
          'KATKI_PAYI_TUTARI': '85.000,00',
        };

        final sonuc = KararMetniServisi.dogrula(
          isStandart: false,
          veriler: veriler,
        );

        expect(sonuc.gecerli, isTrue);
      });
    });

    group('metinUret', () {
      test('Standart şablon metin üretimi placeholder içermez', () {
        final veriler = {
          'BIRIM_AD': 'UBATAM',
          'BIRIM_EVRAK_TARIHI': '01.05.2026',
          'BIRIM_EVRAK_SAYISI': 'E-12345',
          'BIRIM_KURUL_TARIHI': '15.04.2026',
          'BIRIM_TOPLANTI_SAYI': '5',
          'BIRIM_KARAR_NO': '2026/12',
          'YK_KARAR_TARIHI': '20.04.2026',
          'YK_KARAR_NO': '2026/45',
          'FIRMA_UNVAN': 'ABC Mühendislik Ltd.',
          'ISIN_KONUSU': 'Teknik Danışmanlık',
          'DANISMANLIK_SURESI': '6',
          'HOCA_UNVAN': 'Prof. Dr.',
          'HOCA_AD_SOYAD': 'Ali Veli',
          'KATSAYI': '19,50',
        };

        final metin = KararMetniServisi.metinUret(
          isStandart: true,
          veriler: veriler,
        );

        // Placeholder kalmamalı
        expect(metin.contains('{'), isFalse);
        expect(metin.contains('}'), isFalse);
        // İçerik mevcut olmalı
        expect(metin.contains('UBATAM'), isTrue);
        expect(metin.contains('ABC Mühendislik Ltd.'), isTrue);
        expect(metin.contains('Ali Veli'), isTrue);
      });
    });
  });
}
