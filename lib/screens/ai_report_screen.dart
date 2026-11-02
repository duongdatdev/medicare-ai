import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../models/appointment.dart';
import '../services/ai_reports.dart';

class AiReportScreen extends StatefulWidget {
  const AiReportScreen({required this.appointment, super.key});
  final Appointment appointment;
  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen> {
  final _symptoms = TextEditingController();
  final _picker = ImagePicker();
  final _ai = AiReports();
  Uint8List? _image;
  String _filename = 'symptom.jpg';
  List<Map<String, dynamic>> _imageResults = [];
  List<Map<String, dynamic>> _symptomResults = [];
  Uint8List? _pdf;
  bool _busy = false;

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(source: source, maxWidth: 1280);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _image = bytes;
        _filename = file.name;
        _pdf = null;
      });
    }
  }

  Future<void> _submit() async {
    final image = _image;
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ảnh triệu chứng trước')),
      );
      return;
    }
    final symptoms = _symptoms.text.trim();
    setState(() {
      _busy = true;
      _pdf = null;
      _imageResults = [];
      _symptomResults = [];
    });
    try {
      final imageResults = await _ai.diagnoseImage(image, _filename);
      final symptomResults = symptoms.isEmpty
          ? <Map<String, dynamic>>[]
          : await _ai.analyzeSymptoms(symptoms);
      final pdf = await _ai.buildReport(
        image: image,
        filename: _filename,
        symptoms: symptoms,
        appointmentId: widget.appointment.id,
      );
      if (mounted) {
        setState(() {
          _imageResults = imageResults;
          _symptomResults = symptomResults;
          _pdf = pdf;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPdf() async {
    final pdf = _pdf;
    if (pdf == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async => pdf,
      name: 'ai-report-${widget.appointment.id}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Báo cáo AI · Lịch #${widget.appointment.id}')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Bác sĩ: ${widget.appointment.name ?? 'Phòng khám'}'),
        const SizedBox(height: 12),
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_image!, height: 220, fit: BoxFit.cover),
          )
        else
          Container(
            height: 180,
            alignment: Alignment.center,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Text('Chưa chọn ảnh'),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Thư viện'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Chụp ảnh'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _symptoms,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Mô tả triệu chứng'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.smart_toy),
          label: Text(_busy ? 'Đang phân tích…' : 'Phân tích và tạo PDF'),
        ),
        if (_imageResults.isNotEmpty)
          _predictionSection('Kết quả phân tích ảnh', _imageResults),
        if (_symptomResults.isNotEmpty)
          _predictionSection('Phân tích triệu chứng', _symptomResults),
        if (_pdf != null) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _openPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Mở báo cáo PDF'),
          ),
        ],
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Kết quả AI chỉ mang tính tham khảo, không thay thế chẩn đoán của bác sĩ.',
          ),
        ),
      ],
    ),
  );

  Widget _predictionSection(
    String title,
    List<Map<String, dynamic>> results,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          for (var i = 0; i < results.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text('${results[i]['disease'] ?? 'Chưa xác định'}'),
              subtitle: results[i]['reason'] == null
                  ? null
                  : Text('${results[i]['reason']}'),
              trailing: results[i]['confidence'] == null
                  ? null
                  : Text(
                      '${((results[i]['confidence'] as num) * 100).toStringAsFixed(1)}%',
                    ),
            ),
        ],
      ),
    ),
  );
}
