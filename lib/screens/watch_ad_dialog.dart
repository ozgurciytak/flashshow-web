import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ad_model.dart';
import '../services/database_service.dart';

class WatchAdDialog extends StatefulWidget {
  final String teamId;
  final String teamName;
  final AdModel ad;

  const WatchAdDialog({
    Key? key,
    required this.teamId,
    required this.teamName,
    required this.ad,
  }) : super(key: key);

  static Future<bool?> show(BuildContext context, {
    required String teamId,
    required String teamName,
    required AdModel ad,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WatchAdDialog(
        teamId: teamId,
        teamName: teamName,
        ad: ad,
      ),
    );
  }

  @override
  State<WatchAdDialog> createState() => _WatchAdDialogState();
}

class _WatchAdDialogState extends State<WatchAdDialog> {
  late int _secondsLeft;
  late final int _totalDuration;
  Timer? _timer;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.ad.rewardSeconds > 0 ? widget.ad.rewardSeconds : 15;
    _secondsLeft = _totalDuration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 0;
          _isFinished = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalDuration - _secondsLeft) / _totalDuration;

    return Dialog(
        backgroundColor: Colors.grey[900],
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.ad.type == 'google' ? Colors.blue[900] : Colors.amber[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.ad.type == 'google' ? 'Google AdMob' : 'Sponsor Reklamı',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!_isFinished)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_secondsLeft sn',
                        style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                ],
              ),
              const SizedBox(height: 16),
              // Reklam Görseli & İçeriği
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.ad.type == 'google' ? Icons.ads_click : Icons.campaign,
                      size: 64,
                      color: Colors.yellow,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.ad.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.ad.targetUrl,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // İlerleme Çubuğu
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(_isFinished ? Colors.greenAccent : Colors.yellow),
              ),
              const SizedBox(height: 14),
              Text(
                _isFinished
                    ? 'Tebrikler! Reklam tamamen izlendi. ${widget.teamName} takımına 1 destek gönderildi!'
                    : 'Takımınıza destek sayılması için reklam sonuna kadar izlenmelidir. Erken kapatılırsa sayılmaz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isFinished ? Colors.greenAccent : Colors.white70,
                  fontSize: 13,
                  fontWeight: _isFinished ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isFinished)
                    TextButton(
                      onPressed: () async {
                        final exit = await _showExitWarning();
                        if (exit && mounted) {
                          Navigator.pop(context, false);
                        }
                      },
                      child: const Text('Vazgeç / Kapat', style: TextStyle(color: Colors.white38)),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFinished ? Colors.yellow : Colors.grey[700],
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isFinished
                        ? () async {
                            final db = Provider.of<DatabaseService>(context, listen: false);
                            await db.recordAdSupport(widget.teamId, adId: widget.ad.id);
                            if (mounted) Navigator.pop(context, true);
                          }
                        : null,
                    child: Text(_isFinished ? 'Desteği Gönder ve Kapat' : 'İzleniyor...'),
                  ),
                ],
              )
            ],
          ),
        ),
      );
  }

  Future<bool> _showExitWarning() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.grey[850],
            title: const Text('Reklam Tamamlanmadı', style: TextStyle(color: Colors.yellow)),
            content: const Text(
              'Reklamı bitirmeden çıkarsanız takımınıza destek puanı EKLENMEYECEKTİR. Çıkmak istiyor musunuz?',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İzlemeye Devam Et', style: TextStyle(color: Colors.yellow)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Evet, Çık', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
