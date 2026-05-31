import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/personel_model.dart';

/// Excel import/export servisi.
///
/// Personel listesi gibi verileri Excel formatında
/// dışa aktarma ve içe aktarma işlemlerini yönetir.
class ExcelService {
  ExcelService._();

  // ─────────────────────────────────────────────────────────────
  // EXPORT (Dışa Aktarma)
  // ─────────────────────────────────────────────────────────────

  /// Personel listesini Excel formatında dışa aktarır.
  static Uint8List personelExport(List<PersonelModel> personeller) {
    final excel = Excel.createExcel();
    final sheet = excel['Personel Listesi'];

    // Başlık satırı
    final headers = [
      'Sıra',
      'Ad Soyad',
      'Ünvan',
      'Ünvan Katsayısı',
      'TC Kimlik No',
      'Birim ID',
      'Aktif',
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(headers[i]);
    }

    // Veri satırları
    for (int row = 0; row < personeller.length; row++) {
      final p = personeller[row];
      final dataRow = row + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: dataRow)).value =
          IntCellValue(row + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dataRow)).value =
          TextCellValue(p.adSoyad);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: dataRow)).value =
          TextCellValue(p.unvan);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: dataRow)).value =
          DoubleCellValue(p.unvanKatsayisi);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: dataRow)).value =
          TextCellValue(p.tcKimlikNo);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: dataRow)).value =
          TextCellValue(p.birimId);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: dataRow)).value =
          TextCellValue(p.aktif ? 'Evet' : 'Hayır');
    }

    // Varsayılan Sheet1 sayfasını sil
    excel.delete('Sheet1');

    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  /// Dağıtım sonuçlarını Excel formatında dışa aktarır.
  static Uint8List dagitimExport({
    required String baslik,
    required List<Map<String, dynamic>> veriler,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel[baslik];

    if (veriler.isEmpty) {
      excel.delete('Sheet1');
      return Uint8List.fromList(excel.encode()!);
    }

    // Başlık satırı (ilk kaydın anahtarlarından)
    final headers = veriler.first.keys.toList();
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(headers[i]);
    }

    // Veri satırları
    for (int row = 0; row < veriler.length; row++) {
      final veri = veriler[row];
      for (int col = 0; col < headers.length; col++) {
        final value = veri[headers[col]];
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));

        if (value is int) {
          cell.value = IntCellValue(value);
        } else if (value is double) {
          cell.value = DoubleCellValue(value);
        } else {
          cell.value = TextCellValue(value?.toString() ?? '');
        }
      }
    }

    excel.delete('Sheet1');
    return Uint8List.fromList(excel.encode()!);
  }

  // ─────────────────────────────────────────────────────────────
  // IMPORT (İçe Aktarma)
  // ─────────────────────────────────────────────────────────────

  /// Excel dosyasından personel listesi import eder.
  ///
  /// Beklenen sütunlar: Sıra, Ad Soyad, Ünvan, Ünvan Katsayısı, TC, Birim ID
  static List<PersonelModel> personelImport(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final personeller = <PersonelModel>[];

    // İlk sayfayı al
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null || sheet.rows.isEmpty) return [];

    // İlk satırı başlık olarak atla
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      final adSoyad = _cellToString(row.length > 1 ? row[1] : null);
      if (adSoyad.isEmpty) continue;

      final unvan = _cellToString(row.length > 2 ? row[2] : null);
      final katsayi = _cellToDouble(row.length > 3 ? row[3] : null);
      final tc = _cellToString(row.length > 4 ? row[4] : null);
      final birimId = _cellToString(row.length > 5 ? row[5] : null);

      personeller.add(PersonelModel(
        id: '',
        adSoyad: adSoyad,
        unvan: unvan,
        unvanKatsayisi: katsayi,
        tcKimlikNo: tc,
        birimId: birimId,
      ));
    }

    return personeller;
  }

  static String _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString();
  }

  static double _cellToDouble(Data? cell) {
    if (cell == null || cell.value == null) return 1.0;
    final val = cell.value;
    if (val is DoubleCellValue) return val.value;
    if (val is IntCellValue) return val.value.toDouble();
    return double.tryParse(val.toString()) ?? 1.0;
  }
}
