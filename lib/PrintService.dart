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
  static const String savedPrinterKey = "saved_printer";

  // ==============================
  // 🔐 طلب الصلاحيات
  // ==============================
  Future<bool> requestPermissions({ScaffoldMessengerState? messenger}) async {
    messenger?.showSnackBar(
      const SnackBar(content: Text("Requesting permissions..."),backgroundColor: Colors.black,),
    );

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    messenger?.showSnackBar(
      SnackBar(
        content: Text(allGranted
            ? "Permissions granted ✅"
            : "Permissions denied ❌")
        ,backgroundColor: Colors.black, ),
    );

    return allGranted;
  }
  Future<Uint8List> renderWidgetToImage(Widget widget) async {
    final repaintBoundary = RenderRepaintBoundary();

    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        physicalConstraints: const BoxConstraints(
          maxWidth: 384,
          maxHeight: 1200,
        ),
        logicalConstraints: const BoxConstraints(
          maxWidth: 384,
          maxHeight: 1200,
        ),
        devicePixelRatio: 2.5,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Material(
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
  // ==============================
  // 🔹 حفظ الطابعة
  // ==============================
  Future<void> savePrinter(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(savedPrinterKey, address);
  }

  // ==============================
  // 🔹 جلب الطابعة المحفوظة
  // ==============================
  Future<String?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(savedPrinterKey);
  }

  // ==============================
  // 🔹 جلب الأجهزة المتاحة
  // ==============================
  Future<List<BluetoothDevice>> getDevices({ScaffoldMessengerState? messenger}) async {
    messenger?.showSnackBar(
      const SnackBar(content: Text("Scanning for paired devices..."),backgroundColor: Colors.black,),
    );
    devices = await printer.getPairedDevices();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(devices.isEmpty
            ? "No devices found ❌"
            : "${devices.length} device(s) found ✅")
        ,backgroundColor: Colors.black,    ),
    );
    return devices;
  }

  // ==============================
  // 🔹 اتصال بجهاز
  // ==============================
  Future<bool> connect(BluetoothDevice device, {ScaffoldMessengerState? messenger}) async {
    messenger?.showSnackBar(
      SnackBar(content: Text("Connecting to ${device.name}..."),backgroundColor: Colors.black,),
    );

    await printer.disconnectFromDevice();
    bool result = await printer.connectToDevice(device);

    messenger?.showSnackBar(
      SnackBar(
        content: Text(result
            ? "Connected to ${device.name} ✅"
            : "Failed to connect ❌")
        ,backgroundColor: Colors.black,),
    );

    return result;
  }

  // ==============================
  // 🔹 generate QR → Image
  // ==============================
  Future<Uint8List> generateQr(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    final image = await qrPainter.toImage(300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ==============================
  // 🧾 طباعة نص
  // ==============================
  Future<void> printText(
      String text, {
        bool bold = false,
        TA align = TA.left,
        FS size = FS.medium,
      }) async {
    await printer.printData(
      data: text,
      bold: bold,
      textAlign: align,
      fontSize: size,
    );
  }

  // ==============================
  // 🖼️ طباعة صورة
  // ==============================
  Future<void> printImage(Uint8List bytes) async {
    await printer.printImage(
      bytes: bytes,
      textAlign: TA.center,
    );
  }

  // ==============================
  // 🖼️ طباعة Widget بواسطة GlobalKey
  // ==============================
  Future<bool> printWidget(GlobalKey widgetKey,
      {double pixelRatio = 2.0, required BuildContext context}) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text("Preparing widget for printing..."),backgroundColor: Colors.black,),
    );

    final boundary = widgetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Widget not found ❌"),backgroundColor: Colors.black,),
      );
      return false;
    }

    try {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;
      final bytes = byteData.buffer.asUint8List();

      // ✅ نستخدم الدالة الجديدة اللي تظهر الأجهزة قبل الطباعة
      return await executePrintWithSelection(
            () async {
          await printImage(bytes);
        },
        context: context,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Error printing widget: $e"),backgroundColor: Colors.black,),
      );
      return false;
    }
  }

  // ==============================
  // 📦 تنفيذ الطباعة بعد اختيار الطابعة من القائمة
  // ==============================
  Future<bool> executePrintWithSelection(
      Future<void> Function() printFunction, {
        required BuildContext context,
      }) async {
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(content: Text("Scanning for available printers..."),backgroundColor: Colors.black,),
    );

    // 🔹 جلب الأجهزة المتاحة
    devices = await getDevices(messenger: messenger);

    if (devices.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("No printers found ❌",),backgroundColor: Colors.black,),
      );
      return false;
    }

    // 🔹 إظهار قائمة للاختيار
    BluetoothDevice? selectedDevice = await showDialog<BluetoothDevice>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select a Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (_, index) {
                final d = devices[index];
                return ListTile(
                  leading: const Icon(Icons.print_outlined),
                  title: Text(d.name),
                  subtitle: Text(d.address),
                  onTap: () => Navigator.of(dialogContext).pop(d),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            )
          ],
        );
      },
    );

    if (selectedDevice == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("No printer selected ❌"),backgroundColor: Colors.black,),
      );
      return false;
    }

    // 🔹 الاتصال بالطابعة المختارة
    messenger.showSnackBar(
      SnackBar(content: Text("Connecting to ${selectedDevice.name}..."),backgroundColor: Colors.black,),
    );

    bool connected = await connect(selectedDevice, messenger: messenger);
    if (!connected) return false;

    // 🔹 تنفيذ الطباعة
    try {
      await printFunction();
      await printer.printEmptyLine(callTimes: 3);
      messenger.showSnackBar(
        const SnackBar(content: Text("Print completed ✅"),backgroundColor: Colors.black,),
      );
      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Print error: $e"),backgroundColor: Colors.black,),
      );
      return false;
    }
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
