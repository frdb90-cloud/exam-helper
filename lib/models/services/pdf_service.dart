import 'package
/pdfx.dart';

class PDFService {

static Future<PDFResult> extractText(String filePath) async {

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

  return PDFResult(
    success: true,
    fullText: fullText.trim(),
    pageCount: document.pagesCount,
  );
} catch (e) {
  return PDFResult(
    success: false,
    error: 'خطا: $e',
  );
}
}

}

class PDFResult {

final bool success;

final String fullText;

final int pageCount;

final String? error;

PDFResult({

required this.success,

this.fullText = '',

this.pageCount = 0,

this.error,

});

}

