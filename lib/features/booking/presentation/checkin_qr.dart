import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class CheckInQr extends StatelessWidget {
  const CheckInQr(this.value, {super.key, this.size = 180});
  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final qr = QrImage(
      QrCode.fromData(data: value, errorCorrectLevel: QrErrorCorrectLevel.M),
    );
    return Semantics(
      label: 'Mã QR nhận phòng',
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        child: CustomPaint(painter: _QrPainter(qr)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter(this.qr);
  final QrImage qr;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width / qr.moduleCount;
    final height = size.height / qr.moduleCount;
    final paint = Paint()..color = Colors.black;
    for (var row = 0; row < qr.moduleCount; row++) {
      for (var column = 0; column < qr.moduleCount; column++) {
        if (qr.isDark(row, column)) {
          canvas.drawRect(
            Rect.fromLTWH(
              column * width,
              row * height,
              width + 0.2,
              height + 0.2,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => oldDelegate.qr != qr;
}
