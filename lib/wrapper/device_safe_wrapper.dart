import 'package:flutter/material.dart';
import 'dart:io';

class DeviceSafeWrapper extends StatelessWidget {
  final Widget child;
  final bool respectBottomSafeArea;
  final bool respectTopSafeArea;

  const DeviceSafeWrapper({
    super.key,
    required this.child,
    this.respectBottomSafeArea = true,
    this.respectTopSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    final viewInsets = mediaQuery.viewInsets;

    // Detectar dispositivos específicos ou versões que podem ter problemas
    final isProblematicDevice = _isProblematicDevice(mediaQuery);

    return Container(
      padding: EdgeInsets.only(
        top: respectTopSafeArea && !isProblematicDevice ? padding.top : 0,
        bottom: respectBottomSafeArea && !isProblematicDevice
            ? padding.bottom + viewInsets.bottom
            : viewInsets.bottom,
      ),
      child: child,
    );
  }

  bool _isProblematicDevice(MediaQueryData mediaQuery) {
    // Lógica para detectar dispositivos com problemas conhecidos
    final size = mediaQuery.size;
    final ratio = size.height / size.width;

    // Dispositivos com aspect ratio muito estranho ou telas muito pequenas
    return ratio < 1.5 || ratio > 2.5 || size.height < 600;
  }
}
