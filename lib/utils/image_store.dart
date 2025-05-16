import 'dart:collection';
import 'dart:typed_data';

class StoredImage {
  final Uint8List bytes;
  final DateTime timestamp;
  StoredImage(this.bytes, this.timestamp);
}
class ImageStore {
  static final ImageStore _instance = ImageStore._internal();
  factory ImageStore() => _instance;
  ImageStore._internal();

  final Queue<StoredImage> _images = Queue<StoredImage>();
  static const int maxImages = 3;

  void addImage(Uint8List bytes, DateTime timestamp) {
    if (_images.length >= maxImages) {
      _images.removeFirst();
    }
    _images.addLast(StoredImage(bytes, timestamp));
  }

  List<StoredImage> getImages() => _images.toList();
  void clear() => _images.clear();
}