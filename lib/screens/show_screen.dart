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
    this.withCountdown = true,
  }) : super(key: key);

  @override
  State<ShowScreen> createState() => _ShowScreenState();
}

class _ShowScreenState extends State<ShowScreen> {
  // Senkronizasyon Durumu
  bool _isPhase1 = true; // true: Primary Color + Flash ON; false: Secondary Color + Flash OFF
  bool _isTorchOn = false;
  bool _isTorchAvailable = false;
  bool _isTorchInProgress = false;
  Timer? _syncTimer;

  // Ortak Küresel Geri Sayım Durumu
  bool _isCountdownActive = false;
  int _targetStartEpochMs = 0;
  int _secondsLeft = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initTorch();

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
      } catch (_) {
        _isTorchAvailable = false;
      }
    }
  }

  /// Ortak Küresel Geri Sayım
  /// Farklı cihazlar 1-2 saniye arayla "Şovu Başlat" dese bile
  /// dünya saatindeki aynı ortak saniyeye (Epoch Slot) kilitlenirler ve tam aynı salisede başlarlar.
  void _startGlobalCountdown() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    // 4 saniyelik küresel dilimlere kilitlen
    int slot = ((now ~/ 4000) + 1) * 4000;
    if (slot - now < 1200) {
      slot += 4000; // Kullanıcıya en az 1.2 saniye hazırlanma süresi tanı
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
  /// Aşama 1 (0 - 2400 ms): Ağır & Tok Başlangıç (800ms periyot: 400ms 1. Renk+Flaş / 400ms 2. Renk)
  /// Aşama 2 (2400 - 4800 ms): Orta Tempo (480ms periyot: 240ms 1. Renk+Flaş / 240ms 2. Renk)
  /// Aşama 3 (4800 - 6600 ms): Yüksek Hız (300ms periyot: 150ms 1. Renk+Flaş / 150ms 2. Renk)
  /// Aşama 4 (6600 - 8000 ms): ÇILGIN TURBO STROBE (140ms periyot: 70ms 1. Renk+Flaş / 70ms 2. Renk)
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
      return (rel % 140) < 70;
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
      int remInPulse = 70 - (rel % 70);
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
    final int cycleMs = nowMs % 8000;
    final bool targetPhase1 = _calculateIsPhase1(cycleMs);

    if (_isPhase1 != targetPhase1) {
      setState(() {
        _isPhase1 = targetPhase1;
      });
    }

    _applyTorch(targetPhase1);

    int msUntilNext = _calculateMsUntilNext(cycleMs);
    if (msUntilNext <= 0) msUntilNext = 50;

    _syncTimer = Timer(Duration(milliseconds: msUntilNext), _onSyncBeat);
  }

  void _applyTorch(bool targetOn) async {
    if (!_isTorchAvailable || !widget.useFlash) return;
    if (_isTorchOn == targetOn) return;
    if (_isTorchInProgress) return; // Donanım çakışmasını önle

    _isTorchInProgress = true;
    try {
      if (targetOn) {
        await TorchLight.enableTorch();
        _isTorchOn = true;
      } else {
        await TorchLight.disableTorch();
        _isTorchOn = false;
      }
    } catch (_) {
      // Donanım meşguliyet hatasını güvenle yut
    } finally {
      _isTorchInProgress = false;
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
            // Büyük Geri Sayım Sayacı
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
            // Geri sayımı beklemek istemeyenler için hemen başla butonu
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

  /// SAF TAKIM RENKLERİ ŞOV EKRANI (Logo Yok - Sadece Ekrana Yayılan Takım Renkleri)
  Widget _buildPureColorShowView() {
    // 1. Fazda Birincil Renk, 2. Fazda İkincil Renk tüm ekranı kaplar
    Color currentColor = widget.useScreen
        ? (_isPhase1 ? widget.primaryColor : widget.secondaryColor)
        : Colors.black;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      width: double.infinity,
      height: double.infinity,
      color: currentColor,
      child: SafeArea(
        child: Stack(
          children: [
            // Ekranda hiçbir logo veya amblem yok; sadece altta çok sade durdurma uyarısı
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
