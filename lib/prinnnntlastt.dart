// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:easy_blue_printer/easy_blue_printer.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class PrintService {
//   static final PrintService _instance = PrintService._internal();
//   factory PrintService() => _instance;
//   PrintService._internal();
//
//   final printer = EasyBluePrinter.instance;
//   List<BluetoothDevice> devices = [];
//   static const String savedPrinterKey = "saved_printer";
//
//   // ==============================
//   // 🔐 طلب الصلاحيات
//   // ==============================
//   Future<bool> requestPermissions({ScaffoldMessengerState? messenger}) async {
//     messenger?.showSnackBar(
//       const SnackBar(content: Text("Requesting permissions...")),
//     );
//
//     final statuses = await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.location,
//     ].request();
//
//     bool allGranted = statuses.values.every((status) => status.isGranted);
//
//     messenger?.showSnackBar(
//       SnackBar(
//         content: Text(allGranted
//             ? "Permissions granted ✅"
//             : "Permissions denied ❌"),
//       ),
//     );
//
//     return allGranted;
//   }
//
//   // ==============================
//   // 🔹 حفظ الطابعة
//   // ==============================
//   Future<void> savePrinter(String address) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(savedPrinterKey, address);
//   }
//
//   // ==============================
//   // 🔹 جلب الطابعة المحفوظة
//   // ==============================
//   Future<String?> getSavedPrinter() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(savedPrinterKey);
//   }
//
//   // ==============================
//   // 🔹 جلب الأجهزة المتاحة
//   // ==============================
//   Future<List<BluetoothDevice>> getDevices({ScaffoldMessengerState? messenger}) async {
//     messenger?.showSnackBar(
//       const SnackBar(content: Text("Scanning for paired devices...")),
//     );
//     devices = await printer.getPairedDevices();
//     messenger?.showSnackBar(
//       SnackBar(
//         content: Text(devices.isEmpty
//             ? "No devices found ❌"
//             : "${devices.length} device(s) found ✅"),
//       ),
//     );
//     return devices;
//   }
//
//   // ==============================
//   // 🔹 اتصال بجهاز
//   // ==============================
//   Future<bool> connect(BluetoothDevice device, {ScaffoldMessengerState? messenger}) async {
//     messenger?.showSnackBar(
//       SnackBar(content: Text("Connecting to ${device.name}...")),
//     );
//
//     await printer.disconnectFromDevice();
//     bool result = await printer.connectToDevice(device);
//
//     messenger?.showSnackBar(
//       SnackBar(
//         content: Text(result
//             ? "Connected to ${device.name} ✅"
//             : "Failed to connect ❌"),
//       ),
//     );
//
//     return result;
//   }
//
//   // ==============================
//   // 🔹 auto connect للطابعة المحفوظة
//   // ==============================
//   Future<bool> autoConnect({ScaffoldMessengerState? messenger}) async {
//     String? saved = await getSavedPrinter();
//     if (saved == null) {
//       messenger?.showSnackBar(
//         const SnackBar(content: Text("No saved printer found.")),
//       );
//       return false;
//     }
//
//     devices = await getDevices(messenger: messenger);
//
//     try {
//       final device = devices.firstWhere((d) => d.address == saved);
//       return await connect(device, messenger: messenger);
//     } catch (_) {
//       messenger?.showSnackBar(
//         const SnackBar(content: Text("Saved printer not found.")),
//       );
//       return false;
//     }
//   }
//
//   // ==============================
//   // 🔹 generate QR → Image
//   // ==============================
//   Future<Uint8List> generateQr(String data) async {
//     final qrPainter = QrPainter(
//       data: data,
//       version: QrVersions.auto,
//       gapless: true,
//       color: const Color(0xFF000000),
//       emptyColor: const Color(0xFFFFFFFF),
//     );
//
//     final image = await qrPainter.toImage(300);
//     final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//     return byteData!.buffer.asUint8List();
//   }
//
//   // ==============================
//   // 🧾 طباعة نص
//   // ==============================
//   Future<void> printText(
//       String text, {
//         bool bold = false,
//         TA align = TA.left,
//         FS size = FS.medium,
//       }) async {
//     await printer.printData(
//       data: text,
//       bold: bold,
//       textAlign: align,
//       fontSize: size,
//     );
//   }
//
//   // ==============================
//   // 🖼️ طباعة صورة
//   // ==============================
//   Future<void> printImage(Uint8List bytes) async {
//     await printer.printImage(
//       bytes: bytes,
//       textAlign: TA.center,
//     );
//   }
//
//   // ==============================
//   // 🖼️ طباعة Widget بواسطة GlobalKey
//   // ==============================
//   Future<bool> printWidget(GlobalKey widgetKey,
//       {double pixelRatio = 2.0, ScaffoldMessengerState? messenger}) async {
//     messenger?.showSnackBar(
//       const SnackBar(content: Text("Preparing widget for printing...")),
//     );
//
//     final boundary = widgetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
//     if (boundary == null) {
//       messenger?.showSnackBar(
//         const SnackBar(content: Text("Widget not found ❌")),
//       );
//       return false;
//     }
//
//     try {
//       final image = await boundary.toImage(pixelRatio: pixelRatio);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       if (byteData == null) return false;
//       final bytes = byteData.buffer.asUint8List();
//
//       messenger?.showSnackBar(
//         const SnackBar(content: Text("Printing widget...")),
//       );
//
//       return await executePrint(() async {
//         await printImage(bytes);
//         messenger?.showSnackBar(
//           const SnackBar(content: Text("Widget printed successfully ✅")),
//         );
//       });
//     } catch (e) {
//       messenger?.showSnackBar(
//         SnackBar(content: Text("Error printing widget: $e")),
//       );
//       return false;
//     }
//   }
//
//   // ==============================
//   // 📦 تنفيذ الطباعة بعد الاتصال مع تتبع العمليات
//   // ==============================
//   Future<bool> executePrint(
//       Future<void> Function() printFunction, {
//         ScaffoldMessengerState? messenger,
//       }) async {
//     messenger?.showSnackBar(
//       const SnackBar(content: Text("Connecting to printer...")),
//     );
//
//     bool connected = await autoConnect(messenger: messenger);
//     if (!connected) {
//       messenger?.showSnackBar(
//         const SnackBar(content: Text("Printer connection failed ❌")),
//       );
//       return false;
//     }
//
//     try {
//       await printFunction();
//       await printer.printEmptyLine(callTimes: 3);
//       messenger?.showSnackBar(
//         const SnackBar(content: Text("Print completed ✅")),
//       );
//       return true;
//     } catch (e) {
//       messenger?.showSnackBar(
//         SnackBar(content: Text("Print error: $e")),
//       );
//       return false;
//     }
//   }
//
//   // ==============================
//   // 🔥 اختيار طابعة مع تتبع العمليات
//   // ==============================
//   Future<void> pickPrinter({
//     required BuildContext context,
//     required Function(BluetoothDevice device) onSelected,
//   }) async {
//     final devices = await getDevices(messenger: ScaffoldMessenger.of(context));
//
//     showModalBottomSheet(
//       context: context,
//       builder: (_) {
//         return ListView.builder(
//           itemCount: devices.length,
//           itemBuilder: (_, i) {
//             final d = devices[i];
//             return ListTile(
//               title: Text(d.name),
//               subtitle: Text(d.address),
//               onTap: () {
//                 Navigator.pop(context);
//                 onSelected(d);
//               },
//             );
//           },
//         );
//       },
//     );
//   }
// }
import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  final printer = EasyBluePrinter.instance;

  List<BluetoothDevice> devices = [];
  BluetoothDevice? _cachedDevice;
  static const String savedPrinterKey = "saved_printer";

  final Queue<Future<void> Function()> _printQueue = Queue();
  bool _isPrinting = false;

  // ==============================
  // 🔐 Permissions
  // ==============================
  Future<bool> requestPermissions({BuildContext? context}) async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // ==============================
  // 💾 Save / Load Printer
  // ==============================
  Future<void> savePrinter(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(savedPrinterKey, address);
  }

  Future<String?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(savedPrinterKey);
  }

  // ==============================
  // 📡 Devices
  // ==============================
  Future<List<BluetoothDevice>> getDevices() async {
    devices = await printer.getPairedDevices();
    return devices;
  }

  // ==============================
  // 🔌 Connect
  // ==============================
  Future<bool> connect(BluetoothDevice device) async {
    await printer.disconnectFromDevice();
    return await printer.connectToDevice(device);
  }

  // ==============================
  // 🧠 Smart Connect
  // ==============================
  Future<bool> _smartConnect() async {
    if (_cachedDevice != null) {
      try {
        if (await printer.isConnected()) return true;
      } catch (_) {}
    }

    final savedAddress = await getSavedPrinter();
    if (savedAddress != null) {
      devices = await getDevices();
      try {
        final device = devices.firstWhere((d) => d.address == savedAddress);
        bool connected = await connect(device);
        if (connected) {
          _cachedDevice = device;
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  // ==============================
  // 🧠 Queue
  // ==============================
  Future<void> _enqueuePrint(Future<void> Function() task) async {
    _printQueue.add(task);
    if (_isPrinting) return;

    _isPrinting = true;
    while (_printQueue.isNotEmpty) {
      final currentTask = _printQueue.removeFirst();
      try {
        await currentTask();
      } catch (_) {}
    }
    _isPrinting = false;
  }

  // ==============================
  // 🧠 Smart Print
  // ==============================
  Future<bool> _smartPrint(Future<void> Function() printFunction) async {
    bool connected = await _smartConnect();
    if (!connected) return false;

    try {
      await printFunction();
      await printer.printEmptyLine(callTimes: 3);
      return true;
    } catch (_) {
      _cachedDevice = null;
      return false;
    }
  }

  // ==============================
  // 🧾 Print Text
  // ==============================
  Future<void> printText(
      String text, {
        bool bold = false,
        TA align = TA.left,
        FS size = FS.medium,
        int copies = 1,
      }) async {
    await _enqueuePrint(() async {
      for (int i = 0; i < copies; i++) {
        await _smartPrint(() async {
          await printer.printData(
            data: text,
            bold: bold,
            textAlign: align,
            fontSize: size,
          );
        });
      }
    });
  }

  // ==============================
  // 🖼️ Optimize Image
  // ==============================
  Future<Uint8List> _optimizeImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 380);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (_) {
      return bytes;
    }
  }

  // ==============================
  // 🖼️ Print Image
  // ==============================
  Future<void> printImage(
      Uint8List bytes, {
        int copies = 1,
      }) async {
    await _enqueuePrint(() async {
      final optimized = await _optimizeImage(bytes);

      for (int i = 0; i < copies; i++) {
        await _smartPrint(() async {
          await printer.printImage(
            bytes: optimized,
            textAlign: TA.center,
          );
        });
      }
    });
  }

  // ==============================
  // 🧾 QR
  // ==============================
  Future<Uint8List> generateQr(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );
    final image = await qrPainter.toImage(250);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ==============================
  // 🖼️ Print Widget
  // ==============================
  Future<bool> printWidget(
      GlobalKey key, {
        int copies = 1,
      }) async {
    final boundary =
    key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return false;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return false;

    final bytes = byteData.buffer.asUint8List();

    for (int i = 0; i < copies; i++) {
      bool result = await _smartPrint(() async {
        await printImage(bytes);
      });
      if (!result) return false;
    }
    return true;
  }
  Future<bool> executePrintWithSelection(
      Future<void> Function() printFunction, {
        required BuildContext context,
      }) async {

    // ✅ 1. حاول تستخدم الطابعة المحفوظة
    final savedAddress = await getSavedPrinter();

    if (savedAddress != null) {
      devices = await getDevices();

      try {
        final device = devices.firstWhere((d) => d.address == savedAddress);

        bool connected = await connect(device);
        if (connected) {
          _cachedDevice = device;

          try {
            await printFunction();
            await printer.printEmptyLine(callTimes: 3);
            _showSnackBar(context, "Printed using saved printer ✅");
            return true;
          } catch (_) {
            _showSnackBar(context, "Print failed, retrying... ❌");
          }
        }
      } catch (_) {
        // الطابعة مش موجودة في الأجهزة
      }
    }

    // ❌ 2. لو فشل → افتح اختيار طابعة
    devices = await getDevices();

    if (devices.isEmpty) {
      _showSnackBar(context, "No printers available ❌");
      return false;
    }

    BluetoothDevice? selectedDevice = await showDialog<BluetoothDevice>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select Printer'),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (_, index) {
                final d = devices[index];
                return ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(d.name),
                  subtitle: Text(d.address),
                  onTap: () => Navigator.pop(dialogContext, d),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedDevice == null) return false;

    bool connected = await connect(selectedDevice);
    if (!connected) return false;

    // ✅ احفظ الطابعة الجديدة
    _cachedDevice = selectedDevice;
    await savePrinter(selectedDevice.address);

    try {
      await printFunction();
      await printer.printEmptyLine(callTimes: 3);
      _showSnackBar(context, "Print completed ✅");
      return true;
    } catch (_) {
      _showSnackBar(context, "Print failed ❌");
      return false;
    }
  }
  // ==============================
  // 🖼️ Render Widget → Image
  // ==============================
  Future<Uint8List> renderWidgetToImage(Widget widget) async {
    final repaintBoundary = RenderRepaintBoundary();

    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: const ViewConfiguration(
        devicePixelRatio: 1.5,
        physicalConstraints: BoxConstraints(maxWidth: 280, maxHeight: 2000),
        logicalConstraints: BoxConstraints(maxWidth: 280, maxHeight: 2000),
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Material(color: Colors.white, child: widget),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 1.5);
    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
  void _showSnackBar(BuildContext? context, String message) {
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
// .ازاي نطبع شاشه مش موجوده
//
//
// final bytes = await printerService.renderWidgetToImage(
// TicketPrintWidget(state: state),
// );
//
// final result = await printerService.executePrintWithSelection(
// () async {
// await printerService.printImage(bytes);
// },
// context: context,
// );
//
// if (result) {
// receiptPrintedSuccessBottomSheet(context);
// } else {
// printingFailedBottomSheet(context);
// }
