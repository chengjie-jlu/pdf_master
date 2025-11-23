import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:pdf_master/src/core/ffi_define.dart';
import 'package:pdf_master/src/utils/log.dart';

const String _tag = 'PDF_SAVE';

/// 文件写入上下文
/// 用于在 WriteBlock 回调中访问 RandomAccessFile
class _FileWriteContext {
  final RandomAccessFile file;

  _FileWriteContext(this.file);
}

/// 全局文件写入上下文映射
/// Key: FPDF_FILEWRITE 结构体指针地址
/// Value: 文件写入上下文
final Map<int, _FileWriteContext> _fileWriteContexts = {};

/// 全局变量：保存操作的结果状态
bool _writeBlockHasError = false;

/// WriteBlock 回调函数实现
void _writeBlockImpl(Pointer<FPDFFileWrite> pThis, Pointer<Void> pData, int size) {
  try {
    // 从全局映射中获取文件写入上下文
    final contextKey = pThis.address;
    final context = _fileWriteContexts[contextKey];
    if (context == null) {
      Log.e(_tag, "WriteBlock: context not found for address: $contextKey");
      _writeBlockHasError = true;
      return;
    }

    final data = pData.cast<Uint8>().asTypedList(size);
    context.file.writeFromSync(data);
  } catch (e) {
    Log.e(_tag, "WriteBlock error: $e");
    _writeBlockHasError = true;
  }
}

/// WriteBlock 回调包装函数
int _writeBlockWrapper(Pointer<FPDFFileWrite> pThis, Pointer<Void> pData, int size) {
  _writeBlockHasError = false;
  _writeBlockImpl(pThis, pData, size);
  return _writeBlockHasError ? 0 : 1;
}

/// 创建 WriteBlock 回调的 NativeCallable
/// 使用 isolateLocal 模式，因为这个回调会被多次调用
/// exceptionalReturn: 0 表示写入失败
final _writeBlockCallable = NativeCallable<NativeWriteBlockCallback>.isolateLocal(
  _writeBlockWrapper,
  exceptionalReturn: 0,
);

bool savePdfDocument(
  PdfDocument pdfDoc,
  String filePath, {
  int flags = 0, // 使用0表示完整保存（FPDF_NO_INCREMENTAL）
}) {
  if (pdfDoc.document == nullptr) {
    Log.e(_tag, "Can't save: document is null");
    return false;
  }

  RandomAccessFile? file;
  Pointer<FPDFFileWrite>? fileWrite;
  String? tempFilePath;

  try {
    tempFilePath = '$filePath.tmp';
    Log.i(_tag, "Saving PDF to temp file: $tempFilePath");
    file = File(tempFilePath).openSync(mode: FileMode.write);
    fileWrite = calloc<FPDFFileWrite>();
    fileWrite.ref.version = 1;
    fileWrite.ref.writeBlock = _writeBlockCallable.nativeFunction;

    final contextKey = fileWrite.address;
    _fileWriteContexts[contextKey] = _FileWriteContext(file);

    final result = fpdfSaveAsCopy(pdfDoc.document, fileWrite, flags);
    Log.i(_tag, "Save Pdf Result: $result");
    _fileWriteContexts.remove(contextKey);
    file.flushSync();
    file.closeSync();
    file = null;

    final tempFile = File(tempFilePath);
    final targetFile = File(filePath);
    if (targetFile.existsSync()) {
      targetFile.deleteSync();
    }

    tempFile.renameSync(filePath);
    Log.i(_tag, "PDF saved successfully to: $filePath");
    return true;
  } catch (e, stackTrace) {
    Log.e(_tag, "Save PDF error: $e");
    Log.e(_tag, "Stack trace: $stackTrace");
    return false;
  } finally {
    if (fileWrite != null) {
      calloc.free(fileWrite);
    }
    if (file != null) {
      try {
        file.flushSync();
        file.closeSync();
      } catch (e) {
        Log.e(_tag, "Error closing file: $e");
      }
    }
    if (tempFilePath != null) {
      try {
        final tempFile = File(tempFilePath);
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      } catch (e) {
        Log.e(_tag, "Error deleting temp file: $e");
      }
    }
  }
}
