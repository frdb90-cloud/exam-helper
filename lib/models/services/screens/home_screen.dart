import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import '../models/models.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Subject> subjects = [];
  bool isLoading = false;

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        String? filePath = result.files.single.path;
        String fileName = result.files.single.name;

        String? subjectName = await _showSubjectNameDialog(fileName);
        if (subjectName != null && subjectName.isNotEmpty) {
          setState(() => isLoading = true);

          String pdfText = await _extractTextFromPDF(filePath!);

          Subject newSubject = Subject(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: subjectName,
            filePath: filePath,
            content: pdfText,
            createdAt: DateTime.now(),
          );

          setState(() {
            subjects.add(newSubject);
            isLoading = false;
          });

          _showSnackBar('درس "$subjectName" اضافه شد');
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('خطا: $e');
    }
  }

  Future<String> _extractTextFromPDF(String filePath) async {
    try {
      final document = await PdfDocument.openFile(filePath);
      String fullText = '';

      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final textContent = await page.getTextContent();
        fullText += textContent.items.map((item) => item.str).join(' ');
        fullText += '\n\n';
        await page.close();
      }

      await document.close();
      return fullText;
    } catch (e) {
      return 'خطا در خواندن PDF: $e';
    }
  }

  Future<String?> _showSubjectNameDialog(String defaultName) async {
    TextEditingController controller = TextEditingController(
      text: defaultName.replaceAll('.pdf', ''),
    );

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نام درس'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'نام درس',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 دستیار امتحان'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('در حال پردازش PDF...'),
                ],
              ),
            )
          : subjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 100,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5)),
                      const SizedBox(height: 24),
                      Text('هنوز کتابی اضافه نشده',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('فایل PDF کتاب درسی خود را اضافه کنید',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _pickPDF,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('بارگذاری PDF'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.primaries[index % Colors.primaries.length],
                          child: const Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(subject.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'اضافه شده: ${subject.createdAt.year}/${subject.createdAt.month}/${subject.createdAt.day}'),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'scan', child: Text('اسکن سوال')),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف',
                                    style: TextStyle(color: Colors.red))),
                          ],
                          onSelected: (value) {
                            if (value == 'scan') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ScanScreen(selectedSubject: subject),
                                ),
                              );
                            } else if (value == 'delete') {
                              setState(() => subjects.removeAt(index));
                              _showSnackBar('حذف شد');
                            }
                          },
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ScanScreen(selectedSubject: subject),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickPDF,
        icon: const Icon(Icons.add),
        label: const Text('افزودن کتاب'),
      ),
    );
  }
}