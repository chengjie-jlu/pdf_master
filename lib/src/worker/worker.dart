import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:pdf_master/src/core/pdf_ffi_api.dart';
import 'package:pdf_master/src/utils/log.dart';

typedef WorkerFunction<R, P> = R Function(P);

class _WorkRequest<R, P> {
  int id;
  WorkerFunction<R, P> func;
  P params;
  late final R result;

  _WorkRequest(this.id, this.func, this.params);
}

const _kPdfRenderWorkerName = "PdfRenderWorker";
final Map<String, Completer> _completerMap = {_kPdfRenderWorkerName: Completer()};

final class Worker {
  final String tag;

  final _kMaxRequestCount = 0x7fffffff;
  int _currentRequestId = -1;
  SendPort? _childSendPort;

  final Map<int, Completer> _queue = {};

  Worker._(this.tag);

  Future<void> init() async {
    Log.i(tag, "Start Init Background Worker.");
    final ReceivePort port = ReceivePort();
    Isolate.spawn(_onIsolateStart, [port.sendPort, RootIsolateToken.instance], debugName: "PdfRenderIsolate");
    port.listen(_onMainMsg);
    return _completerMap[tag]?.future;
  }

  void _onIsolateStart(args) {
    SendPort port = args[0];
    RootIsolateToken rootIsolateToken = args[1];
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    initLibrary();

    Log.i(tag, "On IsolateStart Success.");
    final receivePort = ReceivePort();
    port.send(receivePort.sendPort);
    receivePort.listen((dynamic) {
      dynamic.result = dynamic.func.call(dynamic.params);
      port.send(dynamic);
    });
  }

  void _onMainMsg(dynamic) {
    if (dynamic is SendPort) {
      _childSendPort = dynamic;
      _completerMap[tag]?.complete();
      return;
    }

    final req = dynamic as _WorkRequest;
    _queue.remove(req.id)?.complete(req.result);
  }

  Future<R> executeInIsolate<R, P>(WorkerFunction<R, P> func, P params) async {
    _currentRequestId = (_currentRequestId + 1) % _kMaxRequestCount;
    final req = _WorkRequest(_currentRequestId, func, params);
    final completer = Completer<R>();
    _queue[_currentRequestId] = completer;
    _childSendPort?.send(req);
    return completer.future;
  }
}

final Worker pdfRenderWorker = Worker._("PdfRenderWorker");
