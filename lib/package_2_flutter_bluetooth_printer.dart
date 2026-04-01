

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';

class FlutterBluetoothPrinterPage extends StatefulWidget {
  const FlutterBluetoothPrinterPage({super.key});

  @override
  State<FlutterBluetoothPrinterPage> createState() =>
      _FlutterBluetoothPrinterPageState();
}

class _FlutterBluetoothPrinterPageState
    extends State<FlutterBluetoothPrinterPage> {
  BluetoothDevice? _selectedDevice;
  bool _isPrinting = false;
  String _statusMessage = 'جاري البحث تلقائياً...';

  // ---- Print ----
  Future<void> _printReceipt() async {
    if (_selectedDevice == null) {
      _showSnack('❌ اختار طابعة الأول!');
      return;
    }
    setState(() {
      _isPrinting = true;
      _statusMessage = 'جاري الطباعة...';
    });
    try {
      await FlutterBluetoothPrinter.printBytes(
        address: _selectedDevice!.address,
        data: _buildEscPosReceipt(), // ✅ Uint8List
        keepConnected: false,
      );
      setState(() => _statusMessage = '✅ تمت الطباعة بنجاح!');
    } catch (e) {
      setState(() => _statusMessage = '❌ فشل الطباعة: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  // ---- Build ESC/POS → Uint8List ✅ ----
  Uint8List _buildEscPosReceipt() {
    final List<int> b = [];
    b.addAll([0x1B, 0x40]);                     // Initialize
    b.addAll([0x1B, 0x61, 0x01]);               // Center
    b.addAll([0x1B, 0x45, 0x01, 0x1D, 0x21, 0x11]); // Bold + Double size
    b.addAll('فاتورة مبيعات\n'.codeUnits);
    b.addAll([0x1D, 0x21, 0x00, 0x1B, 0x45, 0x00]); // Reset
    b.addAll('المحل الكبير\n'.codeUnits);
    b.addAll('0100-000-0000\n'.codeUnits);
    b.addAll([0x1B, 0x61, 0x00]);               // Left
    b.addAll('================================\n'.codeUnits);

    final now = DateTime.now();
    b.addAll('التاريخ: ${now.day}/${now.month}/${now.year}\n'.codeUnits);
    b.addAll('الوقت: ${now.hour}:${now.minute.toString().padLeft(2, '0')}\n'.codeUnits);
    b.addAll('رقم: #${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}\n'.codeUnits);
    b.addAll('================================\n'.codeUnits);
    b.addAll([0x1B, 0x45, 0x01]);
    b.addAll('الصنف             الكمية  السعر\n'.codeUnits);
    b.addAll([0x1B, 0x45, 0x00]);
    b.addAll('--------------------------------\n'.codeUnits);

    final items = [
      {'name': 'كوكاكولا 500ml', 'qty': 2, 'price': 20.0},
      {'name': 'شيبسي كبير   ', 'qty': 1, 'price': 15.5},
      {'name': 'مياه معدنية  ', 'qty': 3, 'price': 12.0},
      {'name': 'عصير مانجو   ', 'qty': 2, 'price': 18.0},
    ];

    double total = 0;
    for (final item in items) {
      final qty = item['qty'] as int;
      final price = item['price'] as double;
      final lineTotal = qty * price;
      total += lineTotal;
      b.addAll('${item['name']}  ${qty}x  ${lineTotal.toStringAsFixed(1)}ج\n'.codeUnits);
    }

    b.addAll('================================\n'.codeUnits);
    b.addAll([0x1B, 0x45, 0x01, 0x1D, 0x21, 0x01]);
    b.addAll('الإجمالي: ${total.toStringAsFixed(2)} جنيه\n'.codeUnits);
    b.addAll([0x1D, 0x21, 0x00, 0x1B, 0x45, 0x00]);
    b.addAll('================================\n'.codeUnits);
    b.addAll([0x1B, 0x61, 0x01]);
    b.addAll('شكراً لزيارتكم\n'.codeUnits);
    b.addAll('نتشرف بخدمتكم دائماً\n'.codeUnits);
    b.addAll('\n\n\n'.codeUnits);
    b.addAll([0x1D, 0x56, 0x41, 0x10]); // Full cut

    return Uint8List.fromList(b); // ✅ Uint8List صح
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طباعة بلوتوث - Package 2',
            style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Status Banner
            Container(
              color: _selectedDevice != null ? Colors.purple[50] : Colors.orange[50],
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              child: Row(
                children: [
                  Icon(
                    _selectedDevice != null
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_searching,
                    color: _selectedDevice != null ? Colors.purple[700] : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _selectedDevice != null
                            ? Colors.purple[800]
                            : Colors.orange[800],
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_isPrinting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            // Package Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: const Text(
                'flutter_bluetooth_printer v4.1.0\n'
                    'discovery تلقائي بـ StreamBuilder<List<BluetoothDevice>>\n'
                    'آخر تحديث: سبتمبر 2025',
                style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.purple),
                textAlign: TextAlign.center,
              ),
            ),

            // ✅ StreamBuilder<List<BluetoothDevice>> - الطريقة الصح
            Expanded(
              child:
              StreamBuilder(
                stream: FlutterBluetoothPrinter.discovery,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data;

                  try {
                    // 🔥 جرب تحوله لقائمة مباشرة
                    final devices = data as List<BluetoothDevice>;

                    if (devices.isEmpty) {
                      return const Center(child: Text('No printers found'));
                    }

                    return ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];

                        return ListTile(
                          title: Text(device.name ?? 'Unknown'),
                          subtitle: Text(device.address),
                          onTap: () {
                            setState(() {
                              _selectedDevice = device;
                              _statusMessage = 'Selected: ${device.name}';
                            });
                          },
                          trailing: _selectedDevice?.address == device.address
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                        );
                      },
                    );
                  } catch (e) {
                    // 🔥 هنا بيكون Permission أو State تاني
                    return const Center(
                      child: Text('❌ Please enable Bluetooth & permissions'),
                    );
                  }
                },
              ),
            ),

            // Print Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _selectedDevice != null && !_isPrinting ? _printReceipt : null,
                icon: const Icon(Icons.print, size: 28),
                label: const Text('طباعة الفاتورة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
