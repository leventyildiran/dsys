import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/danismanlik_model.dart';
import '../services/data_service.dart';

/// Dashboard istatistik verileri için provider.
///
/// Firestore stream'lerinden gerçek zamanlı veri çekerek
/// dashboard kartlarını güncel tutar.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    DanismanlikService? danismanlikService,
  }) : _danismanlikService = danismanlikService ?? DanismanlikService() {
    _init();
  }

  final DanismanlikService _danismanlikService;

  StreamSubscription<List<DanismanlikModel>>? _danismanlikSub;

  int _aktifDanismanlikSayisi = 0;
  int get aktifDanismanlikSayisi => _aktifDanismanlikSayisi;

  int _bekleyenTaksitSayisi = 0;
  int get bekleyenTaksitSayisi => _bekleyenTaksitSayisi;

  int _onaylananKararSayisi = 0;
  int get onaylananKararSayisi => _onaylananKararSayisi;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  void _init() {
    _danismanlikSub = _danismanlikService.stream().listen(
      (danismanliklar) {
        _aktifDanismanlikSayisi = danismanliklar
            .where((d) => d.durum == DanismanlikDurum.aktif)
            .length;

        _bekleyenTaksitSayisi = danismanliklar
            .where((d) => d.durum == DanismanlikDurum.bekliyor)
            .length;

        _onaylananKararSayisi = danismanliklar
            .where((d) => d.durum == DanismanlikDurum.tamamlandi)
            .length;

        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[DashboardProvider] Stream hatası: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _danismanlikSub?.cancel();
    super.dispose();
  }
}
