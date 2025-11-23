import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pdf_master_platform_interface.dart';

/// An implementation of [PdfMasterPlatform] that uses method channels.
class MethodChannelPdfMaster extends PdfMasterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pdf_master');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
