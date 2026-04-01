import 'package:flutter/material.dart';
import 'package:newprinter/package_1_print_bluetooth_thermal.dart';
import 'package:newprinter/package_3_bluetooth_print_plus.dart';

 import 'bbixolon_screen.dart';
import 'flutter_bt_print.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Printer Tester')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _btn(context, "1", ParkingInvoiceScreen()),
     _btn(context, "2", ParkingReceiptScreen()),

     _btn(context, "3", PrinterScreen()),
   //       _btn(context, "blue_thermal_plus", BlueThermalScreen()),
     //     _btn(context, "bixolon_printer", BixolonScreen()),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, String title, Widget screen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Text(title),
      ),
    );
  }
}
