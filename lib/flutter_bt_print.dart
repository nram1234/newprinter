import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ParkingInvoiceScreen extends StatefulWidget {
  const ParkingInvoiceScreen({super.key});

  @override
  State<ParkingInvoiceScreen> createState() => _ParkingInvoiceScreenState();
}

class _ParkingInvoiceScreenState extends State<ParkingInvoiceScreen> {
  final printer = EasyBluePrinter.instance;

  List<BluetoothDevice> devices = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }


  @override
  void dispose() {
    printer.disconnectFromDevice();

    super.dispose();

  }

  void showMsg(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  // 🔐 Permissions
  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  // 📡 Scan + اختيار
  Future<void> startScan() async {
    setState(() => isLoading = true);

    try {
      devices = await printer.getPairedDevices();

      if (devices.isEmpty) {
        showMsg("لا يوجد أجهزة ❌", error: true);
      } else {
        showDevices();
      }
    } catch (e) {
      showMsg("خطأ: $e", error: true);
    }

    setState(() => isLoading = false);
  }

  // 🔗 Connect + Print مباشرة
  Future<void> connectAndPrint(BluetoothDevice device) async {
    showMsg("جاري الاتصال...");

    try {
      await printer.disconnectFromDevice();

      bool result = await printer.connectToDevice(device);

      if (result) {
        showMsg("تم الاتصال ✅");
        await printInvoice(); // 🔥 طباعة مباشرة
      } else {
        showMsg("فشل الاتصال ❌", error: true);
      }
    } catch (e) {
      showMsg("خطأ: $e", error: true);
    }
  }

  // 🔥 QR Image للطابعة
  Future<Uint8List> generateQrImage(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );

    final image = await qrPainter.toImage(300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  // 🖨️ Print
  Future<void> printInvoice() async {
    try {
      await printer.printData(
        data: 'Parking Invoice',
        fontSize: FS.large,
        textAlign: TA.center,
        bold: true,
      );

      await printer.printData(
        data: '----------------',
        textAlign: TA.center,     bold: true,
        fontSize: FS.large,
      );

      await printer.printData(
        data: 'Driver: naser',
        textAlign: TA.center,
        bold: true,
        fontSize: FS.large,
      );

      await printer.printData(
        data: 'Hours: 2',
        textAlign: TA.center,
        bold: true,
        fontSize: FS.large,
      );

      await printer.printData(
        data: 'Time: ${DateTime.now()}',
        textAlign: TA.center,
        bold: true,
        fontSize: FS.large,
      );

      final qrBytes = await generateQrImage("ABC123456");

      await printer.printImage(bytes: qrBytes, textAlign: TA.center);

      await printer.printData(
        data: 'Thank You',
        textAlign: TA.center,
        fontSize: FS.large,
        bold: true,
       );

      await printer.printEmptyLine(callTimes: 3);

      showMsg("تم الطباعة ✅");
    } catch (e) {
      showMsg("خطأ طباعة: $e", error: true);
    }
  }

  // 📋 عرض الأجهزة
  void showDevices() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (_, i) {
            final d = devices[i];

            return ListTile(
              title: Text(d.name),
              subtitle: Text(d.address),
              onTap: () async {
                Navigator.pop(context);
                await connectAndPrint(d); // 🔥 مباشرة
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = "ABC123456";

    return Scaffold(
      appBar: AppBar(title: const Text("Parking Invoice")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📄 البيانات
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Text("Parking Receipt", style: TextStyle(fontSize: 20)),
                    SizedBox(height: 10),
                    Text("Driver: Ahmed"),
                    Text("Hours: 2"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 QR ظاهر في الشاشة
            QrImageView(
              data: qrData,
              size: 200,
            ),

            const SizedBox(height: 20),

            // 🔘 زر واحد فقط
            ElevatedButton(
              onPressed: isLoading ? null : startScan,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("بحث عن طابعة وطباعة"),
            ),
          ],
        ),
      ),
    );
  }
}