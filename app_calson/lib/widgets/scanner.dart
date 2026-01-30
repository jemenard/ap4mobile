import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Scanner extends StatefulWidget {
  const Scanner({Key? key}) : super(key: key);

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  bool scanTerminer = false;

  void fermerEcran() {
    scanTerminer = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scanner un QR code", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF406080),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Placer le QR code dans la zone de scan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Le scan démarrera automatiquement",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: MobileScanner(
                onDetect: (capture) {
                  if (!scanTerminer) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      scanTerminer = true;
                      String code = barcodes.first.displayValue ?? "Inconnu";
                      
                      // On renvoie la valeur scannée à l'écran précédent
                      Navigator.pop(context, code);
                    }
                  }
                },
              ),
            ),
            const Expanded(
              child: FooterWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: const Text(
        "Développé par CaleSons",
        style: TextStyle(color: Colors.white54, letterSpacing: 1),
      ),
    );
  }
}
