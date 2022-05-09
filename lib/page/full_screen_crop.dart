import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crop_your_image/crop_your_image.dart';
import 'package:cropyourimage_gallery/provider/image_data_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FullScreenCrop extends StatefulWidget {
  const FullScreenCrop();

  @override
  _FullScreenCropState createState() => _FullScreenCropState();
}

class _FullScreenCropState extends State<FullScreenCrop> {
  final _controller = CropController();
  List<Rect> rects = [];
  late Rect rect;

  var _isProcessing = false;
  set isProcessing(bool value) {
    setState(() {
      _isProcessing = value;
    });
  }

  Uint8List? _croppedData;
  set croppedData(Uint8List? value) {
    setState(() {
      _croppedData = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageData = context.watch<ImageDataNotifier>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Full Screen Crop',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          if (_croppedData == null)
            IconButton(
              icon: Icon(Icons.cut),
              onPressed: () {
                isProcessing = true;
                _controller.crop();
              },
            ),
          if (_croppedData != null)
            IconButton(
              icon: Icon(Icons.redo),
              onPressed: () => croppedData = null,
            ),
          IconButton(
            icon: Icon(Icons.fitbit_sharp),
            onPressed: () => croppedData = null,
          ),
        ],
        iconTheme: IconThemeData(
          color: Colors.black87,
        ),
      ),
      body: Visibility(
        visible: imageData.loadData.length > 1 && !_isProcessing,
        child: imageData.loadData.length > 1
            ? Visibility(
                visible: _croppedData == null,
                child: Crop(
                  onMoved: (value) => rect = value,
                  controller: _controller,
                  image: imageData.loadData[1],
                  onCropped: (cropped) {
                    croppedData = cropped;
                    isProcessing = false;
                  },
                ),
                replacement: _croppedData != null
                    ? FutureBuilder<ui.Image>(
                        future: _loadUiImgFromBytes(imageData.loadData[1]),
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasError) {
                            final error = snapshot.error;
                            return Center(child: Text("$error"));
                          } else if (snapshot.hasData) {
                            return Center(
                              child: FittedBox(
                                child: SizedBox(
                                  width: snapshot.data.width.toDouble(),
                                  height: snapshot.data.height.toDouble(),
                                  child: CustomPaint(
                                    painter: RectPainterOnImg(
                                        rect: rect, img: snapshot.data),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Center(child: Text("waiting"));
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              )
            : const SizedBox.shrink(),
        replacement: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class RectPainterOnImg extends CustomPainter {
  Rect rect;
  ui.Image img;

  RectPainterOnImg({required this.img, required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(img, Offset.zero, Paint());
    var paintRec = Paint()
      ..color = ui.Color.fromARGB(255, 255, 0, 0)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paintRec);
  }

  @override
  bool shouldRepaint(RectPainterOnImg oldDelegate) =>
      this.img != oldDelegate.img;
}

Future<ui.Image> _loadUiImgFromBytes(Uint8List img) async {
  return await decodeImageFromList(img);
}
