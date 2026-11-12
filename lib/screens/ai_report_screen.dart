import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../models/appointment.dart';
import '../services/ai_reports.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
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
    body: ResponsiveCenter(
      maxWidth: 740,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Card(
            child: ListTile(
              leading: AppAvatar(
                imagePath: widget.appointment.avatar,
                name: widget.appointment.name,
                fallbackIcon: Icons.medical_services_outlined,
              ),
              title: Text(
                'Bác sĩ: ${widget.appointment.name ?? 'Phòng khám'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Báo cáo AI sẽ được đính kèm vào lịch khám'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: '1. Ảnh vùng tổn thương / triệu chứng',
                    subtitle: 'Chọn ảnh rõ nét để hệ thống AI hỗ trợ phân tích',
                  ),
                  const SizedBox(height: 10),
                  if (_image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _image!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 116,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Chưa chọn ảnh',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Thư viện'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Chụp ảnh'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: '2. Mô tả triệu chứng',
                    subtitle: 'Cung cấp thêm thời gian khởi phát, mức độ đau/ngứa',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _symptoms,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả triệu chứng',
                      hintText:
                          'Ví dụ: Nổi mẩn đỏ kèm ngứa nhẹ 3 ngày nay ở cánh tay...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.smart_toy_outlined),
            label: Text(_busy ? 'Đang phân tích…' : 'Phân tích và tạo PDF'),
          ),
          if (_imageResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            _predictionSection('Kết quả phân tích ảnh', _imageResults),
          ],
          if (_symptomResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            _predictionSection('Phân tích triệu chứng', _symptomResults),
          ],
          if (_pdf != null) ...[
            const SizedBox(height: 14),
            Card(
              color: AppColors.primarySoft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: AppColors.primaryDark,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Báo cáo PDF đã sẵn sàng',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                'Bạn có thể mở xem, lưu hoặc in báo cáo này.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _openPdf,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Mở báo cáo PDF'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const ClinicBanner(
            message:
                'Kết quả AI chỉ mang tính tham khảo, không thay thế chẩn đoán của bác sĩ.',
            tone: BadgeTone.warning,
          ),
        ],
        ),
      ),
    ),
  );

  Widget _predictionSection(String title, List<Map<String, dynamic>> results) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: title),
              const SizedBox(height: 10),
              for (var i = 0; i < results.length; i++) ...[
                if (i > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primaryDark,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${results[i]['disease'] ?? 'Chưa xác định'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (results[i]['confidence'] != null)
                            StatusBadge(
                              label:
                                  '${(((results[i]['confidence'] as num)) * 100).toStringAsFixed(1)}%',
                              tone: BadgeTone.primary,
                            ),
                        ],
                      ),
                      if (results[i]['confidence'] != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: ((results[i]['confidence'] as num))
                                .toDouble()
                                .clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppColors.neutralBg,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      if (results[i]['reason'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${results[i]['reason']}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
