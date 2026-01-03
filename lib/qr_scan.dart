import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !isScanned) {
                isScanned = true;
                final String code = barcodes.first.rawValue ?? "Unknown";
                Navigator.pop(context, code);
              }
            },
          ),


          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 260,
                    width: 260,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellowAccent, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),


          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.yellowAccent),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

Positioned(
  top: 50,
  right: 20,
  child: CircleAvatar(
    backgroundColor: Colors.black45,
    child: ValueListenableBuilder<TorchState>(

      valueListenable: controller.torchState, 
      builder: (context, state, child) {
        return IconButton(
          icon: Icon(
            state == TorchState.on ? Icons.flash_on : Icons.flash_off,
            color: state == TorchState.on ? Colors.yellowAccent : Colors.white,
          ),
          onPressed: () => controller.toggleTorch(),
        );
      },
    ),
  ),
), 
        
        ],
      ),
    );
  }
}