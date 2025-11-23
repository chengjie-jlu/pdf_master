import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pdf_master_method_channel.dart';

abstract class PdfMasterPlatform extends PlatformInterface {
  /// Constructs a PdfMasterPlatform.
  PdfMasterPlatform() : super(token: _token);

  static final Object _token = Object();

  static PdfMasterPlatform _instance = MethodChannelPdfMaster();

  /// The default instance of [PdfMasterPlatform] to use.
  ///
  /// Defaults to [MethodChannelPdfMaster].
  static PdfMasterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PdfMasterPlatform] when
  /// they register themselves.
  static set instance(PdfMasterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
