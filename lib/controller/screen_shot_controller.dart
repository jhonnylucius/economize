import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';

class CustomScreenshotController {
  final ScreenshotController _screenshotController = ScreenshotController();

  // Configurações padrão
  static const double _scaleFactor = 5.0;
  static const Duration _defaultDelay = Duration(milliseconds: 500);
  static const EdgeInsets _defaultPadding = EdgeInsets.all(16);

  ScreenshotController get screenshotController => _screenshotController;

  Future<Uint8List?> captureFromWidget(
    BuildContext context,
    Widget widget, {
    Duration delay = _defaultDelay,
    double scaleFactor = _scaleFactor,
    EdgeInsets padding = _defaultPadding,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      return await _screenshotController.captureFromWidget(
        Material(
          child: MediaQuery(
            data: MediaQuery.of(context),
            child: Theme(
              data: Theme.of(context),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  decoration: BoxDecoration(color: backgroundColor),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height,
                      ),
                      padding: padding,
                      child: widget,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        context: context,
        delay: delay,
        targetSize: Size(
          MediaQuery.of(context).size.width * scaleFactor,
          MediaQuery.of(context).size.height * scaleFactor,
        ),
      );
    } catch (e) {
      debugPrint('Erro ao capturar screenshot: $e');
      return null;
    }
  }

  // Método auxiliar para salvar em PDF
  Future<bool> saveAsPdf(
    BuildContext context,
    Widget widget,
    String fileName,
  ) async {
    try {
      final imageBytes = await captureFromWidget(context, widget);
      if (imageBytes == null) return false;

      // Criar documento PDF
      final pdf = pw.Document();

      // Adicionar imagem ao PDF
      final image = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Center(child: pw.Image(image));
          },
        ),
      );

      // Obter diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');

      // Salvar arquivo
      await file.writeAsBytes(await pdf.save());

      debugPrint('PDF salvo em: ${file.path}');
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar PDF: $e');
      return false;
    }
  }
}
