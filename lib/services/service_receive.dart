import "dart:io";
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ServiceReceive {
  Stream<List<File>> watchImages() {
    return ReceiveSharingIntent.instance
        .getMediaStream()
        .map(_imagesFromSharedMedia);
  }

  Future<List<File>> getInitialImages() async {
    final media = await ReceiveSharingIntent.instance.getInitialMedia();
    ReceiveSharingIntent.instance.reset();
    return _imagesFromSharedMedia(media);
  }



  List<File> _imagesFromSharedMedia(List<SharedMediaFile> media) {
    return media.where(_isImage).map((file) => _fileFromPath(file.path)).toList();
  }

  bool _isImage(SharedMediaFile file) {
    return file.type == SharedMediaType.image ||
        (file.mimeType?.startsWith("image/") ?? false);
  }

  File _fileFromPath(String path) {
    final uri = Uri.tryParse(path);

    if (uri != null && uri.scheme ==  "file") {
      return File.fromUri(uri);
    }
    return File(path);
  }
}