import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ParkingReceiptScreen extends StatefulWidget {
  const ParkingReceiptScreen({super.key});

  @override
  State<ParkingReceiptScreen> createState() => _ParkingReceiptScreenState();
}

class _ParkingReceiptScreenState extends State<ParkingReceiptScreen> {
  ReceiptController? controller;
  bool _permissionsGranted = false;

  final String carNumber = "ABC-1234";
  final String location = "Parking";
  final String date = "2026-03-31";
  final String timeIn = "10:00 AM";
  final String timeOut = "12:30 PM";
  final double price = 25.0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parking Receipt")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Receipt(
              onInitialized: (c) => controller = c,
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Parking Invoice",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _row("Car Number", carNumber),
                    _row("Location", location),
                    _row("Date", date),
                    _row("Time In", timeIn),
                    _row("Time Out", timeOut),
                    const SizedBox(height: 10),
                    const Divider(),
                    _row("Total Price", "$price EGP", isBold: true),
                    const SizedBox(height: 20),
                    // QR Code
                    QrImageView(
                      data: "$carNumber|$date|$price",
                      size: 120,
                    ),
                    const SizedBox(height: 10),
                    const Text("Scan for details"),
                  ],
                ),
              ),
            ),
            // زر الطباعة
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: _print,
                child: const Text("Print Receipt"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _print() async {
    // ✅ التحقق من الصلاحيات قبل الطباعة
    if (!_permissionsGranted) {
      bool hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ الرجاء منح صلاحيات البلوتوث أولاً"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      _permissionsGranted = true;
    }

    if (!mounted) return;
    final device = await FlutterBluetoothPrinter.selectDevice(context);

    if (device != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ متصل بـ: ${device.name}"),
          backgroundColor: Colors.green,
        ),
      );

      await controller?.print(address: device.address);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🖨️ جاري الطباعة..."),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ لم يتم اختيار طابعة"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ دالة للتحقق من الصلاحيات الحالية
  Future<bool> _checkPermissions() async {
    final bluetoothScan = await Permission.bluetoothScan.status;
    final bluetoothConnect = await Permission.bluetoothConnect.status;
    final location = await Permission.location.status;

    return bluetoothScan.isGranted &&
        bluetoothConnect.isGranted &&
        location.isGranted;
  }

  /// ✅ دالة طلب الصلاحيات - تُستدعى مرة واحدة فقط في initState
  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (!mounted) return;

    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (allGranted) {
      _permissionsGranted = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ تم منح جميع الصلاحيات"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ تم رفض بعض الصلاحيات - قد لا تتمكن من الطباعة"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}