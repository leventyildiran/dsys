import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extract docx headers', () {
    try {
      final file = File(r'E:\antivaty\dsys\ornek\Yürütme Kurulu Kararları.docx');
      if (!file.existsSync()) {
        print('File not found');
        return;
      }
      
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      print('--- ZIP FILES ---');
      for (final f in archive.files) {
        if (f.name.contains('header') || f.name.contains('document')) {
          print('File: ${f.name} (size: ${f.size})');
        }
      }
      
      // Extract header files
      for (final f in archive.files) {
        if (f.name.contains('header')) {
          final content = String.fromCharCodes(f.content as List<int>);
          // Try to get plain text
          final textRegExp = RegExp(r'<w:t[^>]*>(.*?)</w:t>');
          final matches = textRegExp.allMatches(content);
          final plainText = matches.map((m) => m.group(1)).join(' ');
          print('\n--- HEADER ${f.name} PLAIN TEXT ---');
          print(plainText);
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  });
}
