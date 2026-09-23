import 'dart:async';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:easy_localization/easy_localization.dart';

class ShowScreen extends StatefulWidget {
  final String teamName;
  final Color primaryColor;
  final Color secondaryColor;
  final String? league;
  final bool useFlash;
  final bool useScreen;
  final bool withCountdown;

  const ShowScreen({
    Key? key,
    this.teamName = 'Takım',
    required this.primaryColor,
    required this.secondaryColor,
    this.league,
    this.useFlash = true,
    this.useScreen = true,
    this.withCountdown = false,
  }) : super(key: key);

  @override
  State<ShowScreen> createState() => _ShowScreenState();
}

class _ShowScreenState extends State<ShowScreen> {
  static const int _kCyclePeriodMs = 8000;

  // Senkronizasyon Durumu
  late bool _isPhase1; // true: Primary Color + Flash ON; false: Secondary Color + Flash OFF
  bool _isTorchOn = false;
  bool _isTorchAvailable = false;
  bool _isTorchInProgress = false;
  bool? _pendingTorchState;
  Timer? _syncTimer;

  // İsteğe Bağlı Küresel Geri Sayım Durumu
  bool _isCountdownActive = false;
  int _targetStartEpochMs = 0;
  int _secondsLeft = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    // 1. İLK KAREDE (Frame 0) Doğrudan Dünya Saatine Göre Fazı Belirle (Sıfır Gecikme)
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    _isPhase1 = _calculateIsPhase1(nowMs % _kCyclePeriodMs);

    // 2. Flaş Donanımını Hazırla
    _initTorch();

    // 3. Şovu Başlat
    if (widget.withCountdown) {
      _startGlobalCountdown();
    } else {
      _startMasterSync();
    }
  }

  void _initTorch() async {
    if (widget.useFlash) {
      try {
        _isTorchAvailable = await TorchLight.isTorchAvailable();
        // Flaş donanımı hazır olur olmaz, o anki küresel faza anında kilitle!
        if (_isTorchAvailable && mounted && !_isCountdownActive) {
          final int nowMs = DateTime.now().millisecondsSinceEpoch;
          final bool currentPhase = _calculateIsPhase1(nowMs % _kCyclePeriodMs);
          _applyTorch(currentPhase);
        }
      } catch (_) {
        _isTorchAvailable = false;
      }
    }
  }

  /// İsteğe Bağlı Ortak Küresel Geri Sayım
  /// Kullanıcı geri sayımla başlatmayı seçtiyse, tam bir sonraki 8 saniyelik döngü başına kilitler.
  void _startGlobalCountdown() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    int slot = ((now ~/ _kCyclePeriodMs) + 1) * _kCyclePeriodMs;
    if (slot - now < 2000) {
      slot += _kCyclePeriodMs;
    }
    _targetStartEpochMs = slot;

    setState(() {
      _isCountdownActive = true;
      _secondsLeft = ((_targetStartEpochMs - now) / 1000).ceil();
    });

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final int current = DateTime.now().millisecondsSinceEpoch;
      final int remaining = _targetStartEpochMs - current;

      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          _isCountdownActive = false;
        });
        _startMasterSync();
      } else {
        final int sec = (remaining / 1000).ceil();
        if (sec != _secondsLeft) {
          setState(() {
            _secondsLeft = sec;
          });
        }
      }
    });
  }

  /// 8 Saniyelik Hızlanan Koreografi Döngüsü (8000 ms)
  /// Dünya saatine (Epoch ms % 8000) kilitlidir.
  /// Farklı saniyelerde, dakikalarda veya saatlerde girilse bile
  /// tüm cihazlar bu 8 saniyenin tam aynı milisaniyesini yaşar!
  ///
  /// - Aşama 1 (0 - 2400 ms): Tok & Güçlü Giriş (800ms periyot: 400ms 1. Renk+Flaş / 400ms 2. Renk)
  /// - Aşama 2 (2400 - 4800 ms): Orta Tempo (480ms periyot: 240ms 1. Renk+Flaş / 240ms 2. Renk)
  /// - Aşama 3 (4800 - 6600 ms): Yüksek Hız (300ms periyot: 150ms 1. Renk+Flaş / 150ms 2. Renk)
  /// - Aşama 4 (6600 - 8000 ms): ÇILGIN TURBO STROBE (200ms periyot: 100ms 1. Renk+Flaş / 100ms 2. Renk)
  bool _calculateIsPhase1(int cycleMs) {
    if (cycleMs < 2400) {
      return (cycleMs % 800) < 400;
    } else if (cycleMs < 4800) {
      int rel = cycleMs - 2400;
      return (rel % 480) < 240;
    } else if (cycleMs < 6600) {
      int rel = cycleMs - 4800;
      return (rel % 300) < 150;
    } else {
      int rel = cycleMs - 6600;
      return (rel % 200) < 100;
    }
  }

  int _calculateMsUntilNext(int cycleMs) {
    if (cycleMs < 2400) {
      int remInPulse = 400 - (cycleMs % 400);
      int untilPhaseEnd = 2400 - cycleMs;
      return remInPulse < untilPhaseEnd ? remInPulse : untilPhaseEnd;
    } else if (cycleMs < 4800) {
      int rel = cycleMs - 2400;
      int remInPulse = 240 - (rel % 240);
      int untilPhaseEnd = 4800 - cycleMs;
      return remInPulse < untilPhaseEnd ? remInPulse : untilPhaseEnd;
    } else if (cycleMs < 6600) {
      int rel = cycleMs - 4800;
      int remInPulse = 150 - (rel % 150);
      int untilPhaseEnd = 6600 - cycleMs;
      return remInPulse < untilPhaseEnd ? remInPulse : untilPhaseEnd;
    } else {
      int rel = cycleMs - 6600;
      int remInPulse = 100 - (rel % 100);
      int untilPhaseEnd = 8000 - cycleMs;
      return remInPulse < untilPhaseEnd ? remInPulse : untilPhaseEnd;
    }
  }

  void _startMasterSync() {
    _onSyncBeat();
  }

  void _onSyncBeat() {
    if (!mounted || _isCountdownActive) return;

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int cycleMs = nowMs % _kCyclePeriodMs;
    final bool targetPhase1 = _calculateIsPhase1(cycleMs);

    if (_isPhase1 != targetPhase1) {
      setState(() {
        _isPhase1 = targetPhase1;
      });
    }

    _applyTorch(targetPhase1);

    // Bir sonraki vuruşa kalan süreyi hesapla (Sıfır kayma / Drift-free)
    int msUntilNext = _calculateMsUntilNext(cycleMs);
    if (msUntilNext <= 0) msUntilNext = 50;

    _syncTimer = Timer(Duration(milliseconds: msUntilNext), _onSyncBeat);
  }

  /// Kuyruklu & Donanım Korumalı Flaş Kontrolü
  /// Kamera HAL işlemdeyken gelen istekleri düşürmez, bittiği anda en son durumu anında uygular.
  void _applyTorch(bool targetOn) async {
    if (!_isTorchAvailable || !widget.useFlash) return;
    if (_isTorchOn == targetOn && _pendingTorchState == null) return;

    if (_isTorchInProgress) {
      _pendingTorchState = targetOn;
      return;
    }

    _isTorchInProgress = true;
    _pendingTorchState = null;

    try {
      if (targetOn) {
        await TorchLight.enableTorch();
        _isTorchOn = true;
      } else {
        await TorchLight.disableTorch();
        _isTorchOn = false;
      }
    } catch (_) {
      // Donanım hatasını yut
    } finally {
      _isTorchInProgress = false;
      if (_pendingTorchState != null && _pendingTorchState != _isTorchOn) {
        final nextState = _pendingTorchState!;
        _pendingTorchState = null;
        _applyTorch(nextState);
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _countdownTimer?.cancel();
    _turnOffTorch();
    super.dispose();
  }

  void _turnOffTorch() async {
    try {
      if (_isTorchOn) {
        await TorchLight.disableTorch();
        _isTorchOn = false;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: _isCountdownActive ? _buildCountdownView() : _buildPureColorShowView(),
      ),
    );
  }

  /// Ortak Küresel Geri Sayım Ekranı
  Widget _buildCountdownView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            widget.primaryColor.withOpacity(0.6),
            Colors.black,
          ],
          radius: 1.1,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'sync_countdown_title'.tr(),
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'sync_countdown_sub'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.yellow, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_secondsLeft',
                  style: const TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'countdown_ready'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 36),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.yellow,
                side: const BorderSide(color: Colors.yellow, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                _countdownTimer?.cancel();
                setState(() {
                  _isCountdownActive = false;
                });
                _startMasterSync();
              },
              child: Text(
                'skip_countdown'.tr(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SAF TAKIM RENKLERİ ŞOV EKRANI (Logo Yok - Keskin ve Canlı Renk Patlaması)
  Widget _buildPureColorShowView() {
    // 1. Fazda Birincil Renk, 2. Fazda İkincil Renk tam ekran görünür (Gecikmesiz, anlık geçiş)
    Color currentColor = widget.useScreen
        ? (_isPhase1 ? widget.primaryColor : widget.secondaryColor)
        : Colors.black;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: currentColor,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'tap_to_stop'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
