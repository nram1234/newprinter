// // ============================================================
// // PACKAGE 3: bluetooth_print_plus
// // BLE (Bluetooth Low Energy) - يدعم TSC/TSPL + CPCL + ESC/POS
// // آخر تحديث: مارس 2025
// // يدعم Android + iOS
// // ============================================================
// //
// // pubspec.yaml:
// // dependencies:
// //   bluetooth_print_plus: ^3.1.1
// //   permission_handler: ^11.3.1
// //
// // AndroidManifest.xml أضف:
// //   <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
// //   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30"/>
// //   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
// //   <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation"/>
// //   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
// //
// // ios/Runner/Info.plist أضف:
// //   <key>NSBluetoothAlwaysUsageDescription</key>
// //   <string>Bluetooth access to connect thermal printers</string>
// //   <key>UIBackgroundModes</key>
// //   <array>
// //     <string>bluetooth-central</string>
// //     <string>bluetooth-peripheral</string>
// //   </array>
// // ============================================================
//
// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class BluetoothPrintPlusPage extends StatefulWidget {
//   const BluetoothPrintPlusPage({super.key});
//
//   @override
//   State<BluetoothPrintPlusPage> createState() => _BluetoothPrintPlusPageState();
// }
//
// class _BluetoothPrintPlusPageState extends State<BluetoothPrintPlusPage> {
//   // ---- State ----
//   List<BluetoothDevice> _scanResults = [];
//   BluetoothDevice? _connectedDevice;
//   bool _isScanning = false;
//   bool _isConnected = false;
//   bool _isLoading = false;
//   String _statusMessage = 'اضغط "بحث" لإيجاد الطابعات';
//
//   // Subscriptions
//   StreamSubscription? _scanResultsSub;
//   StreamSubscription? _connectStateSub;
//   StreamSubscription? _isScanSub;
//
//   // ---- Lifecycle ----
//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _setupListeners();
//   }
//
//   @override
//   void dispose() {
//     _scanResultsSub?.cancel();
//     _connectStateSub?.cancel();
//     _isScanSub?.cancel();
//     super.dispose();
//   }
//
//   // ---- Permissions ----
//   Future<void> _requestPermissions() async {
//     await [
//       Permission.bluetooth,
//       Permission.bluetoothConnect,
//       Permission.bluetoothScan,
//       Permission.locationWhenInUse,
//     ].request();
//   }
//
//   // ---- Setup Stream Listeners ----
//   void _setupListeners() {
//     // Listen to scan results
//     _scanResultsSub = BluetoothPrintPlus.scanResults.listen((devices) {
//       if (mounted) {
//         setState(() => _scanResults = devices);
//         if (devices.isNotEmpty) {
//           _setStatus('تم إيجاد ${devices.length} جهاز');
//         }
//       }
//     });
//
//     // Listen to scanning state
//     _isScanSub = BluetoothPrintPlus.isScanning.listen((isScanning) {
//       if (mounted) {
//         setState(() => _isScanning = isScanning);
//         if (!isScanning && _scanResults.isEmpty) {
//           _setStatus('انتهى البحث - لم يُوجد أجهزة');
//         }
//       }
//     });
//
//     // Listen to connection state
//     _connectStateSub = BluetoothPrintPlus.connectState.listen((state) {
//       if (mounted) {
//         final connected = state == ConnectState.connected;
//         setState(() => _isConnected = connected);
//         if (!connected && _connectedDevice != null) {
//           _setStatus('انقطع الاتصال بـ ${_connectedDevice?.name}');
//           setState(() => _connectedDevice = null);
//         }
//       }
//     });
//   }
//
//   // ---- Scan ----
//   Future<void> _startScan() async {
//     setState(() {
//       _scanResults = [];
//       _statusMessage = 'جاري البحث عن الطابعات...';
//     });
//
//     try {
//       await BluetoothPrintPlus.startScan(
//         timeout: const Duration(seconds: 10),
//       );
//     } catch (e) {
//       _setStatus('خطأ في البحث: $e');
//     }
//   }
//
//   Future<void> _stopScan() async {
//     await BluetoothPrintPlus.stopScan();
//   }
//
//   // ---- Connect ----
//   Future<void> _connect(BluetoothDevice device) async {
//     _setLoading(true);
//     _setStatus('جاري الاتصال بـ ${device.name}...');
//
//     try {
//       // Disconnect first if connected to another device
//       if (_isConnected) {
//         await BluetoothPrintPlus.disconnect();
//       }
//
//       await BluetoothPrintPlus.connect(device);
//       setState(() => _connectedDevice = device);
//       _setStatus('✅ متصل بـ ${device.name}');
//     } catch (e) {
//       _setStatus('❌ فشل الاتصال: $e');
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // ---- Disconnect ----
//   Future<void> _disconnect() async {
//     await BluetoothPrintPlus.disconnect();
//     setState(() {
//       _connectedDevice = null;
//       _isConnected = false;
//     });
//     _setStatus('تم قطع الاتصال');
//   }
//
//   // ---- Print Receipt (ESC/POS) ----
//   Future<void> _printEscPos() async {
//     if (!_isConnected) {
//       _showSnack('❌ مش متصل بطابعة!');
//       return;
//     }
//
//     _setLoading(true);
//     _setStatus('جاري الطباعة...');
//
//     try {
//       // Build ESC/POS bytes manually
//       final bytes = _buildEscPosReceipt();
//
//       // Send to printer
//       await BluetoothPrintPlus.write(Uint8List.fromList(bytes));
//
//       _setStatus('✅ تمت الطباعة بنجاح!');
//     } catch (e) {
//       _setStatus('❌ خطأ في الطباعة: $e');
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   // ---- Build ESC/POS Bytes ----
//   List<int> _buildEscPosReceipt() {
//     final List<int> bytes = [];
//
//     // ESC @ - Initialize printer
//     bytes.addAll([0x1B, 0x40]);
//
//     // ESC a 1 - Center align
//     bytes.addAll([0x1B, 0x61, 0x01]);
//
//     // ESC E 1 - Bold ON
//     bytes.addAll([0x1B, 0x45, 0x01]);
//
//     // GS ! 0x11 - Double width + height
//     bytes.addAll([0x1D, 0x21, 0x11]);
//     bytes.addAll('test\n'.codeUnits);
//
//     // Reset size
//     bytes.addAll([0x1D, 0x21, 0x00]);
//     bytes.addAll(' test\n'.codeUnits);
//     bytes.addAll([0x1B, 0x45, 0x00]); // Bold OFF
//
//     bytes.addAll('01234567890\n'.codeUnits);
//
//     // ESC a 0 - Left align
//     bytes.addAll([0x1B, 0x61, 0x00]);
//     bytes.addAll('================================\n'.codeUnits);
//
//     // Date
//     final now = DateTime.now();
//     bytes.addAll(
//       'date: ${now.day}/${now.month}/${now.year}\n'.codeUnits,
//     );
//     bytes.addAll(
//       'time:   ${now.hour}:${now.minute.toString().padLeft(2, '0')}\n'.codeUnits,
//     );
//     bytes.addAll(
//       ' number: #${now.millisecondsSinceEpoch % 100000}\n'.codeUnits,
//     );
//     bytes.addAll('================================\n'.codeUnits);
//
//     // Items header
//     bytes.addAll([0x1B, 0x45, 0x01]); // Bold ON
//     bytes.addAll('        \n'.codeUnits);
//     bytes.addAll([0x1B, 0x45, 0x00]); // Bold OFF
//     bytes.addAll('--------------------------------\n'.codeUnits);
//
//     // Items
//     final items = [
//       {'name': ' 500', 'qty': 2, 'price': 20.0},
//       {'name': 'test', 'qty': 1, 'price': 15.5},
//       {'name': 'test', 'qty': 3, 'price': 12.0},
//       {'name': 'test', 'qty': 2, 'price': 18.0},
//     ];
//
//     double total = 0;
//     for (final item in items) {
//       final qty = item['qty'] as int;
//       final price = item['price'] as double;
//       final lineTotal = qty * price;
//       total += lineTotal;
//
//       final line =
//           '${item['name']}  ${qty}    ${lineTotal.toStringAsFixed(1)}ج\n';
//       bytes.addAll(line.codeUnits);
//     }
//
//     bytes.addAll('================================\n'.codeUnits);
//
//     // Total
//     bytes.addAll([0x1B, 0x45, 0x01]); // Bold ON
//     bytes.addAll([0x1D, 0x21, 0x01]); // Double height
//     bytes.addAll('all : ${total.toStringAsFixed(2)}  test\n'.codeUnits);
//     bytes.addAll([0x1D, 0x21, 0x00]); // Reset
//     bytes.addAll([0x1B, 0x45, 0x00]); // Bold OFF
//
//     bytes.addAll('================================\n'.codeUnits);
//
//     // Footer - center
//     bytes.addAll([0x1B, 0x61, 0x01]);
//     bytes.addAll('test \n'.codeUnits);
//     bytes.addAll('testً\n'.codeUnits);
//
//     // Feed lines
//     bytes.addAll('\n\n\n'.codeUnits);
//
//     // GS V A - Full cut
//     bytes.addAll([0x1D, 0x56, 0x41, 0x10]);
//
//     return bytes;
//   }
//
//   // ---- Helpers ----
//   void _setStatus(String msg) => setState(() => _statusMessage = msg);
//   void _setLoading(bool v) => setState(() => _isLoading = v);
//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
//     );
//   }
//
//   // ---- UI ----
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'طباعة بلوتوث  ',
//
//         ),
//         backgroundColor: Colors.teal[800],
//         foregroundColor: Colors.white,
//         actions: [
//           if (_isConnected)
//             IconButton(
//               icon: const Icon(Icons.bluetooth_disabled),
//               tooltip: 'قطع الاتصال',
//               onPressed: _disconnect,
//             ),
//         ],
//       ),
//       body: Directionality(
//         textDirection: TextDirection.rtl,
//         child: Column(
//           children: [
//             // ---- Status Banner ----
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               color: _isConnected ? Colors.teal[50] : Colors.orange[50],
//               padding: const EdgeInsets.all(12),
//               width: double.infinity,
//               child: Row(
//                 children: [
//                   Icon(
//                     _isConnected
//                         ? Icons.bluetooth_connected
//                         : Icons.bluetooth_searching,
//                     color: _isConnected ? Colors.teal[700] : Colors.orange,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       _statusMessage,
//                       style: TextStyle(
//                         color: _isConnected
//                             ? Colors.teal[800]
//                             : Colors.orange[800],
//                          fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   if (_isLoading || _isScanning)
//                     const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                 ],
//               ),
//             ),
//
//             // ---- Package Info ----
//             Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.teal[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.teal[200]!),
//               ),
//               child: const Text(
//                 'test ',
//                 style: TextStyle(
//                   fontSize: 12,
//
//                   color: Colors.teal,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//
//             // ---- Scan Controls ----
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: _isScanning ? null : _startScan,
//                       icon: const Icon(Icons.search),
//                       label: Text(
//                         _isScanning ? 'جاري البحث...' : 'بحث',
//                        ),
//                       style: ElevatedButton.styleFrom(
//                         minimumSize: const Size(0, 50),
//                         backgroundColor: Colors.teal[700],
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                   if (_isScanning) ...[
//                     const SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: _stopScan,
//                       style: ElevatedButton.styleFrom(
//                         minimumSize: const Size(0, 50),
//                         backgroundColor: Colors.red[700],
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         'إيقاف',
//                        ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 8),
//
//             // ---- Devices List ----
//             Expanded(
//               child: _scanResults.isEmpty
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.print_disabled,
//                             size: 64,
//                             color: Colors.grey[400],
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             'لا توجد طابعات\nاضغط "بحث" للبدء',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: Colors.grey[500],
//                                fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'ملاحظة: هذا الباكدج يستخدم BLE\nتأكد إن الطابعة تدعم BLE',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: Colors.teal[400],
//                                fontSize: 13,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : ListView.separated(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: _scanResults.length,
//                       separatorBuilder: (_, __) => const SizedBox(height: 8),
//                       itemBuilder: (context, index) {
//                         final device = _scanResults[index];
//                         final isConnected =
//                             _connectedDevice?.address == device.address &&
//                                 _isConnected;
//
//                         return Card(
//                           elevation: isConnected ? 4 : 1,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             side: BorderSide(
//                               color: isConnected
//                                   ? Colors.teal
//                                   : Colors.transparent,
//                               width: 2,
//                             ),
//                           ),
//                           child: ListTile(
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 8,
//                             ),
//                             leading: CircleAvatar(
//                               backgroundColor: isConnected
//                                   ? Colors.teal
//                                   : Colors.teal[100],
//                               child: Icon(
//                                 Icons.print,
//                                 color: isConnected ? Colors.white : Colors.teal,
//                               ),
//                             ),
//                             title: Text(
//                               device.name?.isNotEmpty == true
//                                   ? device.name!
//                                   : 'طابعة غير معروفة',
//                               style: const TextStyle(
//                                  fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   device.address ?? '',
//                                   style: const TextStyle(
//                                     fontSize: 11,
//                                     fontFamily: 'monospace',
//                                   ),
//                                 ),
//                                 if (device.address != null)
//                                   Text(
//                                     'قوة الإشارة: ${device.address} dBm',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                               ],
//                             ),
//                             trailing: isConnected
//                                 ? Chip(
//                                     label: const Text(
//                                       'متصل ✓',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                          fontSize: 12,
//                                       ),
//                                     ),
//                                     backgroundColor: Colors.teal[700],
//                                   )
//                                 : ElevatedButton(
//                                     onPressed: _isLoading
//                                         ? null
//                                         : () => _connect(device),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.teal,
//                                       foregroundColor: Colors.white,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                     ),
//                                     child: const Text(
//                                       'اتصال',
//                                      ),
//                                   ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//
//             // ---- Print Button ----
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: ElevatedButton.icon(
//                 onPressed: _isConnected && !_isLoading ? _printEscPos : null,
//                 icon: const Icon(Icons.print, size: 28),
//                 label: const Text(
//                   'طباعة الفاتورة',
//                  ),
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 60),
//                   backgroundColor: Colors.green[700],
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor: Colors.grey[300],
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
