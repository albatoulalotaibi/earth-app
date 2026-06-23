// lib/widgets/viewers/pdf_viewer_screen.dart
import 'dart:io' as io;
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String name;
  final String? assetId; 

  const PdfViewerScreen({
    Key? key,
    required this.pdfUrl,
    required this.name,
    this.assetId, 
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _hasError = false;
  late String _currentName; // 👈 متغير لحفظ الاسم حتى يتحدث فوراً بعد التعديل

  @override
  void initState() {
    super.initState();
    _currentName = widget.name;
  }

  Future<void> _downloadOrOpenFile(BuildContext context) async {
    final originalUrl = widget.pdfUrl;
    final googleDocsViewerUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(originalUrl)}';
    
    final uri = Uri.parse(googleDocsViewerUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن فتح العارض الخارجي')));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  وظيفة تعديل اسم الملف (مربوطة بالباك إند)
  // ═══════════════════════════════════════════════════════════════════
  void _showEditDialog(BuildContext context, bool isDark) {
    final TextEditingController nameController = TextEditingController(text: _currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              title: Text('تعديل اسم الملف', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'الاسم الجديد',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'لا يمكن ترك الاسم فارغاً' : null,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSaving = true);
                      try {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('auth_token');
                        final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/${widget.assetId}/');
                        
                        final response = await http.patch(
                          uri,
                          headers: {
                            'Content-Type': 'application/json',
                            if (token != null) 'Authorization': 'Token $token',
                          },
                          body: jsonEncode({'name': nameController.text.trim()}),
                        );

                        if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 201) {
                          setState(() {
                            _currentName = nameController.text.trim();
                          });
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('تم تعديل الاسم بنجاح'), backgroundColor: Colors.green),
                          );
                        } else {
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('فشل تعديل الاسم'), backgroundColor: Colors.red),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('خطأ في الاتصال'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('حفظ', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  وظيفة حذف الملف (مربوطة بالباك إند)
  // ═══════════════════════════════════════════════════════════════════
  void _showDeleteDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              title: Text('حذف الملف', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              content: Text('هل أنت متأكد من حذف هذا الملف نهائياً؟', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isDeleting ? null : () async {
                    setDialogState(() => isDeleting = true);
                    try {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('auth_token');
                      final uri = Uri.parse('https://ruba-gsh7.onrender.com/api/documents/${widget.assetId}/delete/');
                      
                      final response = await http.delete(
                        uri,
                        headers: {
                          'Content-Type': 'application/json',
                          if (token != null) 'Authorization': 'Token $token',
                        },
                      );

                      if (response.statusCode == 200 || response.statusCode == 204) {
                        if (!mounted) return;
                        Navigator.pop(ctx); // إغلاق نافذة التأكيد
                        Navigator.pop(this.context, true); // إغلاق شاشة الـ PDF والرجوع للصفحة السابقة
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('تم الحذف بنجاح'), backgroundColor: Colors.green),
                        );
                      } else {
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('فشل الحذف'), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('خطأ في الاتصال'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: isDeleting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                    : const Text('حذف', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text(
          _currentName, // 👈 نستخدم المتغير اللي يتحدث فورياً بدل widget.name
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 1,
        actions: [
          if (widget.assetId != null) ...[
            IconButton(
              icon: Icon(Icons.edit, color: isDark ? Colors.white : Colors.black),
              onPressed: () => _showEditDialog(context, isDark),
              tooltip: 'تعديل',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _showDeleteDialog(context, isDark),
              tooltip: 'حذف',
            ),
          ],
          if (widget.pdfUrl.startsWith('http'))
            IconButton(
              icon: Icon(Icons.download, color: isDark ? Colors.white : Colors.black),
              onPressed: () => _downloadOrOpenFile(context),
              tooltip: 'فتح خارجياً',
            ),
        ],
      ),
      body: _hasError ? _buildErrorFallback(isDark) : _buildPdfChild(isDark),
    );
  }

  Widget _buildPdfChild(bool isDark) {
    if (widget.pdfUrl.startsWith('http://') || widget.pdfUrl.startsWith('https://')) {
      return SfPdfViewer.network(
        widget.pdfUrl,
        key: _pdfViewerKey,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          debugPrint('❌ فشل عرض الـ PDF: ${details.error}');
          debugPrint('❌ الوصف: ${details.description}');
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        },
      );
    }

    if (widget.pdfUrl.startsWith('assets/')) {
      return SfPdfViewer.asset(widget.pdfUrl);
    }

    if (!kIsWeb) {
      return SfPdfViewer.file(io.File(widget.pdfUrl));
    }

    return const Center(
      child: Text(
        "Format not supported on Web",
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildErrorFallback(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined,
                size: 80, color: Colors.red.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'لا يمكن عرض الملف داخل التطبيق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قد يكون الملف محمياً أو غير متوافق مع العارض الداخلي.\nيمكنك فتحه وتنزيله بأمان من المتصفح الخارجي.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _downloadOrOpenFile(context),
              icon: const Icon(Icons.open_in_browser, color: Colors.white),
              label: const Text(
                'عرض الملف خارجياً',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}