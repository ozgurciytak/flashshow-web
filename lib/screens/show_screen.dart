import 'dart:async';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:easy_localization/easy_localization.dart';

class ShowScreen extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final bool useFlash;
  final bool useScreen;

  const ShowScreen({
    Key? key,
    required this.primaryColor,
    required this.secondaryColor,
    this.useFlash = true,
    this.useScreen = true,
  }) : super(key: key);

  @override
  State<ShowScreen> createState() => _ShowScreenState();
}

class _ShowScreenState extends State<ShowScreen> {
  bool _isPrimaryColor = true;
  bool _isTorchOn = false;
  Timer? _timer;
  bool _isTorchAvailable = false;

  @override
  void initState() {
    super.initState();
    _startShow();
  }

  void _startShow() async {
    if (widget.useFlash) {
      try {
        _isTorchAvailable = await TorchLight.isTorchAvailable();
      } catch (e) {
        print('Flaş desteklenmiyor: $e');
      }
    }

    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (widget.useScreen) {
        setState(() {
          _isPrimaryColor = !_isPrimaryColor;
        });
      }

      if (_isTorchAvailable && widget.useFlash) {
        try {
          if (_isTorchOn) {
            await TorchLight.disableTorch();
          } else {
            await TorchLight.enableTorch();
          }
          _isTorchOn = !_isTorchOn;
        } catch (e) {
          print('Flaş hatası: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _turnOffTorch();
    super.dispose();
  }

  void _turnOffTorch() async {
    try {
      await TorchLight.disableTorch();
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.useScreen 
          ? (_isPrimaryColor ? widget.primaryColor : widget.secondaryColor)
          : Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Text(
            'tap_to_stop'.tr(),
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 10)]
            ),
          ),
        ),
      ),
    );
  }
}
