import 'package:flutter_test/flutter_test.dart';
import 'package:dsys/core/turkce_format.dart';

void main() {
  group('TurkceFormat', () {
    group('para', () {
      test('Basit tutar formatı', () {
        expect(TurkceFormat.para(1500.0), equals('1.500,00 TL'));
      });

      test('Milyon tutar formatı', () {
        expect(TurkceFormat.para(1250000.50), equals('1.250.000,50 TL'));
      });

      test('Sıfır tutar', () {
        expect(TurkceFormat.para(0.0), equals('0,00 TL'));
      });

      test('Negatif tutar', () {
        expect(TurkceFormat.para(-500.0), equals('-500,00 TL'));
      });

      test('Küçük kuruş değeri', () {
        expect(TurkceFormat.para(0.99), equals('0,99 TL'));
      });

      test('Büyük tutar', () {
        expect(TurkceFormat.para(120000.0), equals('120.000,00 TL'));
      });

      test('Binlik ayırıcı olmadan', () {
        expect(TurkceFormat.para(999.99), equals('999,99 TL'));
      });
    });

    group('tarih', () {
      test('Normal tarih formatı', () {
        final date = DateTime(2026, 5, 30);
        expect(TurkceFormat.tarih(date), equals('30.05.2026'));
      });

      test('Yıl başı', () {
        final date = DateTime(2026, 1, 1);
        expect(TurkceFormat.tarih(date), equals('01.01.2026'));
      });

      test('Yıl sonu', () {
        final date = DateTime(2026, 12, 31);
        expect(TurkceFormat.tarih(date), equals('31.12.2026'));
      });
    });

    group('katsayi', () {
      test('Tam sayı katsayı', () {
        expect(TurkceFormat.katsayi(19.0), equals('19,00'));
      });

      test('Ondalıklı katsayı', () {
        expect(TurkceFormat.katsayi(19.5), equals('19,50'));
      });

      test('Küçük katsayı', () {
        expect(TurkceFormat.katsayi(0.42), equals('0,42'));
      });
    });

    group('ondalik', () {
      test('Varsayılan 2 ondalık', () {
        expect(TurkceFormat.ondalik(1.5), equals('1,50'));
      });

      test('Özel basamak sayısı', () {
        expect(TurkceFormat.ondalik(1.5, decimals: 4), equals('1,5000'));
      });
    });
  });
}
