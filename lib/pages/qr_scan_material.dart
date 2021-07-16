import 'dart:io';

import 'package:deltacraft_klic/models/colours.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScanCertMaterial extends StatefulWidget {
  ScanCertMaterial({Key? key}) : super(key: key);

  @override
  _ScanCertMaterialState createState() => _ScanCertMaterialState();
}

class _ScanCertMaterialState extends State<ScanCertMaterial> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool scan = true;

  void _onQRViewCreated(QRViewController controller, BuildContext ctx) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.format == BarcodeFormat.qrcode &&
          scanData.code.length > 20 &&
          scan) {
        setState(() {
          scan = false;
        });
        await controller.pauseCamera();
        Navigator.pop(ctx, scanData);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Naskenuj QR kód"),
        systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height,
              child: QRView(
                key: qrKey,
                onQRViewCreated: (controller) =>
                    _onQRViewCreated(controller, context),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                // margin: const EdgeInsets.only(top: 80),
                height: MediaQuery.of(context).size.width * .68,
                width: MediaQuery.of(context).size.width * .68,
                decoration: BoxDecoration(
                  border: Border.all(color: primary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(.8),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ), // This one will handle background + difference out
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      // margin: const EdgeInsets.only(top: 80),
                      height: MediaQuery.of(context).size.width * .68,
                      width: MediaQuery.of(context).size.width * .68,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        border: Border.all(color: primary, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Text(
                  "Zarovnej QR kód do rámečku",
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
