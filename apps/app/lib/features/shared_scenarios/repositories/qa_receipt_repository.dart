import '../models/qa_receipt.dart';
import '../services/qa_receipt_file_service.dart';

class QaReceiptRepository {
  QaReceiptRepository(this.files);
  final QaReceiptFileService files;
  Future<QaReceipt?> read(String project, String qa) => files.read(project, qa);
  Future<void> write(QaReceipt receipt) => files.write(receipt);
}
