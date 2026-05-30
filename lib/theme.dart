import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DSYS Uygulama Tema Yapılandırması
/// Material 3 renk paleti ve Google Fonts entegrasyonu.
class DSYSTheme {
  DSYSTheme._();

  static const Color _seedColor = Color(0xFF1565C0); // Kurumsal mavi

  // ─────────────────────────────────────────────────────────────
  // Anlamsal Renkler (Semantic Colors)
  // ─────────────────────────────────────────────────────────────

  /// Para birimi / finansal tutar rengi
  static const Color paraRengi = Color(0xFF1B5E20);

  /// Onay / başarılı durum yeşili
  static const Color onayYesili = Color(0xFF2E7D32);

  /// Bekleyen / süreçte durum sarısı
  static const Color bekleyorSarisi = Color(0xFFF9A825);

  /// Hata / uyarı kırmızısı
  static const Color hataKirmizisi = Color(0xFFC62828);

  /// Tavan aşımı uyarı arkaplanı
  static const Color tavanAsimiBg = Color(0xFFFFEBEE);

  /// Tablo başlık arkaplanı
  static const Color tabloBaslikBg = Color(0xFFE3F2FD);

  /// Kart kenarlık rengi
  static const Color kartKenarligi = Color(0xFFE0E0E0);

  // ─────────────────────────────────────────────────────────────
  // Responsive Spacing Sabitleri (Web-first)
  // ─────────────────────────────────────────────────────────────

  /// Genel sayfa kenar boşluğu
  static const double paddingSayfa = 24.0;

  /// Kart içi padding
  static const double paddingKart = 16.0;

  /// Elemanlar arası dikey boşluk (küçük)
  static const double spacingS = 8.0;

  /// Elemanlar arası dikey boşluk (orta)
  static const double spacingM = 16.0;

  /// Elemanlar arası dikey boşluk (büyük)
  static const double spacingL = 24.0;

  /// Elemanlar arası dikey boşluk (ekstra büyük)
  static const double spacingXL = 32.0;

  /// Web form maksimum genişliği
  static const double formMaxWidth = 1200.0;

  /// Önizleme paneli minimum genişliği
  static const double onizlemeMinWidth = 400.0;

  /// Tablo satır yüksekliği
  static const double tabloSatirYuksekligi = 48.0;

  /// Breakpoint: mobil → tablet
  static const double breakpointTablet = 600.0;

  /// Breakpoint: tablet → masaüstü
  static const double breakpointDesktop = 900.0;

  // ─────────────────────────────────────────────────────────────
  // Rozet / Badge Stilleri
  // ─────────────────────────────────────────────────────────────

  /// Durum rozetleri için renk haritası
  static Color durumRengi(String durum) {
    switch (durum) {
      case 'taslak':
        return Colors.grey;
      case 'mudur_onayinda':
      case 'merkez_onayinda':
      case 'yk_gundeminde':
      case 'bekliyor':
        return bekleyorSarisi;
      case 'aktif':
      case 'onaylandi':
      case 'odendi':
      case 'tamamlandi':
        return onayYesili;
      case 'gecikti':
      case 'iptal':
        return hataKirmizisi;
      default:
        return Colors.grey;
    }
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.outfitTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kartKenarligi, width: 0.5),
        ),
        margin: const EdgeInsets.all(0),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(tabloBaslikBg),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dataTextStyle: const TextStyle(fontSize: 13),
        columnSpacing: 24,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(0),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dataTextStyle: const TextStyle(fontSize: 13),
        columnSpacing: 24,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
