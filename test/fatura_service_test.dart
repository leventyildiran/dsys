import 'package:dsys/services/fatura_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FaturaService.metinAyristir', () {
    final service = FaturaService();

    test('çoklu kayıtları script-first kurallarıyla ayrıştırır', () {
      final sonuc = service.metinAyristir('''
Firma: ABC Ltd.
Hizmet: Tahlil
Tutar: 1.500,00

Firma: XYZ A.Ş.
Hizmet: Analiz
Tutar: 2.300,00
''');

      expect(sonuc, hasLength(2));
      expect(sonuc.first.firmaUnvan, 'ABC Ltd.');
      expect(sonuc.first.hizmetDetay, 'Tahlil');
      expect(sonuc.first.tutar, 1500);
      expect(sonuc.last.firmaUnvan, 'XYZ A.Ş.');
      expect(sonuc.last.hizmetDetay, 'Analiz');
      expect(sonuc.last.tutar, 2300);
    });

    test('eksik tutar olsa bile firma bazlı kayıt üretir', () {
      final sonuc = service.metinAyristir('''
Şirket: Uşak Teknoloji
Hizmet: Kalibrasyon
''');

      expect(sonuc, hasLength(1));
      expect(sonuc.single.firmaUnvan, 'Uşak Teknoloji');
      expect(sonuc.single.hizmetDetay, 'Kalibrasyon');
      expect(sonuc.single.tutar, 0);
    });
  });
}
