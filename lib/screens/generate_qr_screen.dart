import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  GenerateQrScreenState createState() => GenerateQrScreenState();
}

class GenerateQrScreenState extends State<GenerateQrScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedTemplateId;
  String? _generatedQrCode;
  List<Map<String, dynamic>> _templates = [];

  final GlobalKey _qrKey = GlobalKey(); 

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
  try {
    final snapshot = await _firestore.collection('product_templates').get();
    if (snapshot.docs.isEmpty) {
      debugPrint("Нет данных в коллекции product_templates.");
      return;
    }

    setState(() {
      _templates = snapshot.docs.map((doc) {
        final stages = doc.data().containsKey('stages') && doc['stages'] is List
            ? doc['stages'] as List
            : [];

        final stageDetails = stages.map((stage) {
          if (stage is Map<String, dynamic> && stage.containsKey('stage_name')) {
            final stageName = stage['stage_name'] as String?;
            final requiresOtkCheck = stage['requires_otk_check'] ?? false;
            final coefficient = stage['coefficient'] ?? 1;

            return {
              'stage_name': stageName ?? 'Неизвестный этап',
              'requires_otk_check': requiresOtkCheck,
              'coefficient': coefficient,
            };
          } else {
            return {
              'stage_name': 'Неизвестный этап',
              'requires_otk_check': false,
              'coefficient': 1,
            };
          }
        }).toList();

        final templateName = doc.data().containsKey('template_name') 
            ? (doc['template_name'] is String ? doc['template_name'] as String : 'Неизвестное название') 
            : 'Неизвестное название';

        return {
          'id': doc.id,
          'template_name': templateName,
          'stages': stageDetails,
        };
      }).toList();
    });
  } catch (e) {
    debugPrint("Ошибка при загрузке шаблонов: $e");
  }
}

Future<void> _generateQRCode() async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User? user = auth.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Пожалуйста, войдите в систему")),
    );
    return;
  }

  if (_selectedTemplateId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Пожалуйста, выберите шаблон")),
    );
    return;
  }

  try {
    final detailId = DateTime.now().millisecondsSinceEpoch.toString();
    final template = _templates.firstWhere(
      (template) => template['id'] == _selectedTemplateId,
      orElse: () => <String, Object>{},
    );

    if (template.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка: Шаблон не найден")),
      );
      return;
    }

    debugPrint('Шаблон: $template');

    if (template['stages'] == null || (template['stages'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка: Этапы не найдены в шаблоне")),
      );
      return;
    }

    final stages = (template['stages'] as List).map((stage) {
      if (stage is Map<String, dynamic>) {
        return {
          'stage_name': stage['stage_name'],
          'requires_otk_check': stage['requires_otk_check'] ?? false, 
          'coefficient': stage['coefficient'] ?? 1,  
          'employee_number': '',  
        };
      }
      return {};
    }).toList();

    debugPrint('Этапы перед сохранением: $stages');

    await _firestore.collection('details').doc(detailId).set({
      'detail_name': template['template_name'],
      'name': template['template_name'],
      'status': 'In Progress',
      'employee_id': user.uid,
      'employee_name': user.displayName,
      'start_time': FieldValue.serverTimestamp(),
      'detail_id': detailId,
      'template_id': _selectedTemplateId,
      'steps': stages,
    });

    final qrData = '$detailId|${template['template_name']}';

    setState(() {
      _generatedQrCode = qrData;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("QR-код успешно сгенерирован")),
    );
  } catch (e) {
    debugPrint("Ошибка при сохранении в базе данных: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ошибка: $e")),
    );
  }
}

  Future<Uint8List?> _captureQrImage() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Ошибка захвата изображения: $e");
      return null;
    }
  }

  Future<void> _printQrCode() async {
    final imageBytes = await _captureQrImage();
    if (imageBytes == null) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pw.MemoryImage(imageBytes)),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _shareQrCode() async {
    final imageBytes = await _captureQrImage();
    if (imageBytes == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/qr_code.png');
    await file.writeAsBytes(imageBytes);

    await Share.shareXFiles([XFile(file.path)], text: "QR-код для: ${_generatedQrCode?.split('|')[1]}");
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text("Генерация QR-кода"),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Выбор шаблона",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedTemplateId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.grey[50], 
            ),
            hint: const Text("Выберите шаблон"),
            items: _templates.map((template) {
              return DropdownMenuItem<String>(
                value: template['id'],
                child: Text(template['template_name'] ?? 'Без названия'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTemplateId = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _generateQRCode,
            child: const Text("Создать QR-код", style: TextStyle(color: Colors.white),),
          ),
          const SizedBox(height: 24),
          if (_generatedQrCode != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RepaintBoundary(
                  key: _qrKey,
                  child: QrImageView(
                    data: _generatedQrCode!,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _shareQrCode,
                      icon: const Icon(Icons.share, color: Colors.redAccent),
                      label: const Text("Поделиться"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _printQrCode,
                      icon: const Icon(Icons.print, color: Colors.grey),
                      label: const Text("Печать"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        foregroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ),
  );
}



}
