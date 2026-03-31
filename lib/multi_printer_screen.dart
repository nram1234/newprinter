import 'package:flutter/material.dart';

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
          _btn(context, "bt_print", ParkingInvoiceScreen()),
     _btn(context, "flutter_receipt_printer", ParkingReceiptScreen()),

     //     _btn(context, "flutter_bt_print", BtPrintScreen()),
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
