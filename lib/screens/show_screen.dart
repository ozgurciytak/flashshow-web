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
  // Senkronizasyon Durumu
  bool _isPhase1 = true; // Phase 1: Primary + Flash ON; Phase 2: Secondary + Flash OFF
  bool _isTorchOn = false;
  bool _isTorchAvailable = false;
  Timer? _syncTimer;

  // Geri Sayım Durumu
  bool _isCountdownActive = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initTorch();

    if (widget.withCountdown) {
      _startCountdown();
    } else {
      _startMasterSync();
    }
  }

  void _initTorch() async {
    if (widget.useFlash) {
      try {
        _isTorchAvailable = await TorchLight.isTorchAvailable();
      } catch (e) {
        _isTorchAvailable = false;
      }
    }
  }

  /// Geri Sayım (Koreografi Modu)
  void _startCountdown() {
    setState(() {
      _isCountdownActive = true;
      _countdownSeconds = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCountdownActive = false;
        });
        _startMasterSync();
      }
    });
  }

  /// Master Epoch Senkronizasyonu (Global Saat Kilidi)
  /// Kullanıcı hangi saniyede girerse girsin (epoch % 1000) ile
  /// stadyumdaki herkesle tam aynı milisaniyede aynı renge ve flaş durumuna oturur.
  void _startMasterSync() {
    _onSyncBeat();
  }

  void _onSyncBeat() {
    if (!mounted || _isCountdownActive) return;

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    // 1000ms'lik döngü: 0-499ms -> Phase 1, 500-999ms -> Phase 2
    final int cyclePos = nowMs % 1000;
    final bool targetPhase1 = cyclePos < 500;

    if (_isPhase1 != targetPhase1) {
      setState(() {
        _isPhase1 = targetPhase1;
      });
    }

    _applyTorch(targetPhase1);

    // Bir sonraki 500ms sınırına kalan tam milisaniye (Self-correcting, sıfır kayma)
    int msUntilNextBoundary = 500 - (nowMs % 500);
    if (msUntilNextBoundary <= 0) msUntilNextBoundary = 500;

    _syncTimer = Timer(Duration(milliseconds: msUntilNextBoundary), _onSyncBeat);
  }

  void _applyTorch(bool targetOn) async {
    if (!_isTorchAvailable || !widget.useFlash) return;
    if (_isTorchOn == targetOn) return;

    try {
      if (targetOn) {
        await TorchLight.enableTorch();
        _isTorchOn = true;
      } else {
        await TorchLight.disableTorch();
        _isTorchOn = false;
      }
    } catch (_) {
      // Flaş donanım meşguliyeti durumunda hatayı yut
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

  // Takım Baş Harflerini Çıkarma (Örn: Galatasaray -> GS, Real Madrid -> RM)
  String _getTeamInitials(String name) {
    if (name.isEmpty) return 'FS';
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: _isCountdownActive ? _buildCountdownView() : _buildShowView(),
      ),
    );
  }

  /// Geri Sayım Ekranı
  Widget _buildCountdownView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            widget.primaryColor.withOpacity(0.5),
            Colors.black,
          ],
          radius: 1.0,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'countdown_starting'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Text(
              widget.teamName,
              style: TextStyle(
                color: widget.primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: widget.secondaryColor.withOpacity(0.8), blurRadius: 15),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Geri Sayım Sayacı
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.yellow, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.yellow.withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: Center(
                child: Text(
                  '$_countdownSeconds',
                  style: const TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'countdown_ready'.tr(),
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Canlı Senkronize Flaş ve Takım Ekran Resmi Görünümü
  Widget _buildShowView() {
    Color currentColor = widget.useScreen
        ? (_isPhase1 ? widget.primaryColor : widget.secondaryColor)
        : Colors.black;

    Color contrastColor = (_isPhase1 ? widget.secondaryColor : widget.primaryColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: currentColor,
        gradient: widget.useScreen
            ? RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  currentColor,
                  _isPhase1 ? currentColor.withOpacity(0.85) : contrastColor.withOpacity(0.4),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.3, 0.7, 1.0],
              )
            : null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Üst Bar: Canlı Senkronizasyon Rozeti
            Positioned(
              top: 20,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Yanıp sönen yeşil canlı nokta
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _isPhase1 ? Colors.greenAccent : Colors.green[800],
                            shape: BoxShape.circle,
                            boxShadow: _isPhase1
                                ? [
                                    const BoxShadow(
                                      color: Colors.greenAccent,
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'sync_badge'.tr(),
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'sync_subtext'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),

            // Orta Bölüm: Takım Ekran Resmi / Arması ve Ritmik Nabız
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dinamik Takım Arması (Ekran Resmi)
                  _buildTeamShield(contrastColor),
                  const SizedBox(height: 24),
                  // Takım Adı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.teamName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          const Shadow(color: Colors.black, blurRadius: 16, offset: Offset(0, 4)),
                          Shadow(color: contrastColor, blurRadius: 24),
                        ],
                      ),
                    ),
                  ),
                  if (widget.league != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.league!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                        shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Alt Bar: Durdurma Bilgisi
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'tap_to_stop'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
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

  /// Çift Renkli Dinamik Stadyum Arması (Ekran Resmi)
  Widget _buildTeamShield(Color contrastColor) {
    String initials = _getTeamInitials(widget.teamName);
    double scale = _isPhase1 ? 1.08 : 0.98;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isPhase1 ? widget.primaryColor : widget.secondaryColor).withOpacity(0.6),
              blurRadius: _isPhase1 ? 35 : 15,
              spreadRadius: _isPhase1 ? 8 : 2,
            ),
            const BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // Sol Yarı: Birincil Renk
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(color: widget.primaryColor),
                    ),
                    Expanded(
                      child: Container(color: widget.secondaryColor),
                    ),
                  ],
                ),
              ),
              // Stadyum Işık Halkası / Dış Çerçeve
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.9),
                    width: 5,
                  ),
                ),
              ),
              // İç Amblem Rozeti ve Takım Harfleri
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.yellowAccent,
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(color: Colors.yellowAccent, blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
