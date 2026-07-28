import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/models.dart';

class ScanScreen extends StatefulWidget {
  final Subject? selectedSubject;

  const ScanScreen({super.key, this.selectedSubject});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  Question? _parsedQuestion;
  Answer? _aiAnswer;
  Subject? _selectedSubject;

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.selectedSubject;
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _parsedQuestion = null;
      _aiAnswer = null;
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text;

      Question? question = _parseQuestionFromText(extractedText);

      if (question != null) {
        setState(() => _parsedQuestion = question);
        Answer? answer = await _getAIAnswer(question);
        if (answer != null) setState(() => _aiAnswer = answer);
      } else {
        _showSnackBar('سوال شناسایی نشد. واضح‌تر عکس بگیرید.');
      }
    } catch (e) {
      _showSnackBar('خطا: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Question? _parseQuestionFromText(String text) {
    text = text.trim();
    List<String> lines =
        text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    RegExp persianOpt = RegExp(r'^(الف|ب|پ|ج)[\.\)\-:]\s*(.*)');
    RegExp englishOpt = RegExp(r'^([abcd])[\.\)\-:]\s*(.*)', caseSensitive: false);

    List<String> questionLines = [];
    List<String> options = [];

    for (String line in lines) {
      var pMatch = persianOpt.firstMatch(line);
      var eMatch = englishOpt.firstMatch(line);

      if (pMatch != null) {
        options.add(pMatch.group(2)!.trim());
      } else if (eMatch != null) {
        options.add(eMatch.group(2)!.trim());
      } else {
        questionLines.add(line);
      }
    }

    String questionText = questionLines.join(' ').trim();

    if (options.length >= 2 && questionText.isNotEmpty) {
      return Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: questionText,
        options: options,
        subjectId: _selectedSubject?.id ?? '',
      );
    }
    return null;
  }

  Future<Answer?> _getAIAnswer(Question question) async {
    String context = _selectedSubject?.content ?? '';
    if (context.length > 8000) context = context.substring(0, 8000);

    // در اینجا باید API هوش مصنوعی فراخوانی شود
    // برای دمو، پاسخ نمونه برمی‌گرداند
    await Future.delayed(const Duration(seconds: 2));

    return Answer(
      correctOptionIndex: 0,
      correctOptionText: question.options[0],
      explanation:
          'این پاسخ بر اساس تحلیل محتوای کتاب درسی است. برای پاسخ دقیق، API هوش مصنوعی را تنظیم کنید.',
      reference: _selectedSubject?.name ?? 'کتاب درسی',
      confidence: 0.75,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📷 اسکن سوال'),
        centerTitle: true,
        actions: [
          if (_selectedSubject != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(_selectedSubject!.name),
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: _isCameraInitialized
                ? ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: _cameraController!.buildPreview(),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          // Capture Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _captureAndProcess,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  label:
                      Text(_isProcessing ? 'در حال پردازش...' : 'عکس بگیر'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('ورود دستی'),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            flex: 4,
            child: _buildResultsArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('در حال تحلیل سوال...'),
          ],
        ),
      );
    }

    if (_aiAnswer != null && _parsedQuestion != null) {
      return _buildAnswerCard();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('از سوال چهارگزینه‌ای عکس بگیرید',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAnswerCard() {
    final question = _parsedQuestion!;
    final answer = _aiAnswer!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // سوال
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('❓ سوال:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(question.text),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // گزینه‌ها
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋 گزینه‌ها:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...question.options.asMap().entries.map((entry) {
                    int index = entry.key;
                    String option = entry.value;
                    bool isCorrect = index == answer.correctOptionIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect ? Colors.green : Colors.grey,
                          width: isCorrect ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isCorrect ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(option)),
                          if (isCorrect)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('✓ صحیح',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // توضیح
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.lightbulb, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('💡 توضیح:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 8),
                  Text(answer.explanation),
                  const SizedBox(height: 8),
                  Text('📖 مرجع: ${answer.reference}',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // دکمه‌ها
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _parsedQuestion = null;
                      _aiAnswer = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('اسکن جدید'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    TextEditingController questionCtrl = TextEditingController();
    List<TextEditingController> optCtrls =
        List.generate(4, (_) => TextEditingController());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✏️ ورود دستی سوال'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionCtrl,
                decoration: const InputDecoration(
                    labelText: 'متن سوال', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: optCtrls[i],
                    decoration: InputDecoration(
                        labelText: 'گزینه ${['الف', 'ب', 'پ', 'ج'][i]}',
                        border: const OutlineInputBorder()),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (questionCtrl.text.isNotEmpty &&
                  optCtrls.every((c) => c.text.isNotEmpty)) {
                setState(() {
                  _parsedQuestion = Question(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    text: questionCtrl.text,
                    options: optCtrls.map((c) => c.text).toList(),
                    subjectId: _selectedSubject?.id ?? '',
                  );
                  _isProcessing = true;
                });
                _getAIAnswer(_parsedQuestion!).then((answer) {
                  setState(() {
                    _aiAnswer = answer;
                    _isProcessing = false;
                  });
                });
              }
            },
            child: const Text('تحلیل'),
          ),
        ],
      ),
    );
  }
}