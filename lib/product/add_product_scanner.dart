part of 'add product.dart';

class CameraScannerPage extends StatefulWidget {
  const CameraScannerPage({super.key});

  @override
  State<CameraScannerPage> createState() => _CameraScannerPageState();
}

class _CameraScannerPageState extends State<CameraScannerPage> {
  MobileScannerController? controller;
  bool isTorchOn = false;
  bool hasError = false;
  String errorMessage = "";
  bool _isPopped = false;

  @override
  void initState() {
    super.initState();
    try {
      controller = MobileScannerController(autoStart: false);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (controller != null) {
            await controller!.start();
          }
        } catch (e) {
          debugPrint("Failed to start scanner controller: $e");
          setState(() {
            hasError = true;
            errorMessage = e.toString();
          });
        }
      });
    } catch (e) {
      debugPrint("Failed to initialize scanner controller: $e");
      setState(() {
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    try {
      controller?.dispose();
    } catch (e) {
      debugPrint("Error disposing scanner controller: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (hasError || controller == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                const SizedBox(height: 16),
                Text(
                  "Camera Scanner Error",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "To use the real camera, please stop the app and run a full build ('flutter run').\nHot restart does not load new native plugins.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_isPopped) return;
                    _isPopped = true;
                    Navigator.pop(context, "HUAYU-REMOTE-123");
                  },
                  icon: const Icon(Icons.flash_on),
                  label: const Text("Use Simulated Scan Instead"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller!,
            errorBuilder: (context, error) {
              return Container(
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      "Camera Scanner Error",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "To use the real camera, please stop the app and run a full build ('flutter run').\nHot restart does not load new native plugins.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_isPopped) return;
                        _isPopped = true;
                        Navigator.pop(context, "HUAYU-REMOTE-123");
                      },
                      icon: const Icon(Icons.flash_on),
                      label: const Text("Use Simulated Scan Instead"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            onDetect: (capture) {
              if (_isPopped) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? rawValue = barcodes.first.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _isPopped = true;
                  Navigator.of(context).pop(rawValue);
                }
              }
            },
          ),
          // Transparent Viewfinder cutout
          Positioned.fill(
            child: ColorFiltered(
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
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Viewfinder Outline
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0, left: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Laser Animation Line
          Align(
            alignment: Alignment.center,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                final offset = (value - 0.5).abs() * 2 * 110;
                return Stack(
                  children: [
                    Positioned(
                      top: 125 + offset,
                      left: MediaQuery.of(context).size.width / 2 - 110,
                      child: Container(
                        width: 220,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Header Bar Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () {
                    if (_isPopped) return;
                    _isPopped = true;
                    Navigator.pop(context);
                  },
                ),
                Text(
                  "Scan Barcode / QR Code",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    try {
                      controller?.toggleTorch();
                      setState(() {
                        isTorchOn = !isTorchOn;
                      });
                    } catch (e) {
                      debugPrint("Failed to toggle torch: $e");
                    }
                  },
                ),
              ],
            ),
          ),
          // Subtitle instruction
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 24,
            right: 24,
            child: Text(
              "Center the barcode inside the scan window.\nIt will scan and auto-populate details automatically.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
