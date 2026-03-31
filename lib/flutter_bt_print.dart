import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:easy_blue_printer/easy_blue_printer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ParkingInvoiceScreen extends StatefulWidget {
  const ParkingInvoiceScreen({super.key});

  @override
  State<ParkingInvoiceScreen> createState() =>
      _ParkingInvoiceScreenState();
}

class _ParkingInvoiceScreenState extends State<ParkingInvoiceScreen> {
  final printer = EasyBluePrinter.instance;

  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;

  bool isConnected = false;
  bool isLoading = false;

  StreamSubscription? scanSub;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  // 🔐 Permissions
  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  // 📡 Scan صح
  Future<void> startScan() async {
    setState(() {
      isLoading = true;
    });

    devices = await printer.getPairedDevices();

    setState(() {
      isLoading = false;
    });

    showDevices();
  }

  // 🔗 Connect
  Future<void> connect(BluetoothDevice device) async {
    setState(() => isLoading = true);

    bool result = await printer.connectToDevice(device);

    if (result) {
      selectedDevice = device;
      isConnected = true;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connected ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection Failed ❌")),
      );
    }

    setState(() => isLoading = false);
  }

  // 🔥 تحويل QR لصورة
  Future<Uint8List> generateQrImage(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );

    final image = await qrPainter.toImage(300);
    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  // 🖨️ Print
  Future<void> printInvoice() async {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connect printer first")),
      );
      return;
    }

    await printer.printData(
      data: 'Parking Invoice',
      fontSize: FS.large,
      textAlign: TA.center,
      bold: true,
    );

    await printer.printData(
      data: '------------------------',
      textAlign: TA.center,
      fontSize: FS.huge,
      bold: true,
    );

    await printer.printData(
      data: 'Car: ABC-123',
      fontSize: FS.normal,
      bold: true, textAlign: TA.center,
    );

    await printer.printData(data: 'Time: 2 Hours' ,textAlign: TA.center, fontSize: FS.huge, bold:true,);
    await printer.printData(
      data: 'Price: 20 EGP',
      bold: true,
      textAlign: TA.center, fontSize: FS.huge,
    );

    await printer.printData(
      data: '------------------------',
      textAlign: TA.center, fontSize: FS.huge, bold:true,
    );

    // 🔥 طباعة QR كصورة
    final qrBytes = await generateQrImage("ABC123456");

    await printer.printImage( bytes: qrBytes, textAlign: TA.center);

    await printer.printData(
      data: 'Thank You',
      textAlign: TA.center,
      bold: true, fontSize: FS.huge,
    );

    await printer.printEmptyLine(callTimes: 3);
  }

  // 📋 Devices UI
  void showDevices() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        if (devices.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("No devices found"),
            ),
          );
        }

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (_, i) {
            final d = devices[i];

            return ListTile(
              leading: const Icon(Icons.print),
              title: Text(d.name),
              subtitle: Text(d.address),
              onTap: () async {
                Navigator.pop(context);
                await connect(d);
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    scanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parking Invoice")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Parking Receipt",
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    const Text("Car: ABC-123"),
                    const Text("Time: 2 Hours"),
                    const Text("Price: 20 EGP"),
                    const SizedBox(height: 20),

                    QrImageView(
                      data: "ABC123456",
                      size: 120,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : startScan,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Scan Printers"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: printInvoice,
              child: const Text("Print Invoice"),
            ),
          ],
        ),
      ),
    );
  }
}