import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final printerManager = FlutterThermalPrinter.instance;

  List<Printer> printers = [];
  StreamSubscription<List<Printer>>? _sub;

  bool isScanning = false;
  Printer? connectedPrinter;

  // ---------------- SCAN ----------------
  void startScan() async {
    setState(() {
      printers.clear();
      isScanning = true;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("🔍 Scanning...")));

    await printerManager.getPrinters(
      connectionTypes: [ConnectionType.BLE], // يشمل Bluetooth
    );

    _sub = printerManager.devicesStream.listen((event) {
      setState(() {
        printers = event;
      });
    });

    await Future.delayed(const Duration(seconds: 5));
    setState(() => isScanning = false);
  }

  // ---------------- CONNECT + PRINT ----------------
  Future<void> connectAndPrint(Printer printer) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🔗 Connecting to ${printer.name}")),
      );

      await printerManager.connect(printer);

      connectedPrinter = printer;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🖨️ Printing...")),
      );

      await printTicket(printer);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Printed successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  // ---------------- PRINT DATA ----------------
  Future<void> printTicket(printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];

    // Title
    bytes += generator.text(
      "My Business",
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );

    bytes += generator.hr();

    // Car Number
    bytes += generator.text(
      "Car Number: 1234",
      styles: const PosStyles(align: PosAlign.left),
    );

    bytes += generator.hr();

    // QR
    bytes += generator.qrcode("Car:1234 | Business:My Business");

    bytes += generator.feed(2);
    bytes += generator.cut();

    await printerManager.printData( printer,bytes);
  }

  // ---------------- DISCONNECT ----------------
  Future<void> disconnect() async {
    if (connectedPrinter != null) {
      await printerManager.disconnect(connectedPrinter!);
      connectedPrinter = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔌 Disconnected")),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    disconnect(); // 🔥 مهم جداً
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Printer"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Scan Button
          ElevatedButton(
            onPressed: isScanning ? null : startScan,
            child: Text(isScanning ? "Scanning..." : "Scan Printers"),
          ),

          const SizedBox(height: 10),

          // Devices List
          Expanded(
            child: ListView.builder(
              itemCount: printers.length,
              itemBuilder: (context, index) {
                final p = printers[index];

                return Card(
                  child: ListTile(
                    title: Text(p.name ?? "Unknown"),
                    subtitle: Text(p.address ?? ""),
                    trailing: const Icon(Icons.print),
                    onTap: () => connectAndPrint(p),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}