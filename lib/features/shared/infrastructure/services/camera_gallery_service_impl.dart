import 'package:image_picker/image_picker.dart';
import 'camera_gallery_service.dart';


class CameraGalleryServiceImpl extends CameraGalleryService {

  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> selectPhoto() async {
     final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      // En la demo las fotos se guardan en el navegador: se limita su tamaño.
      maxWidth: 1000,
      maxHeight: 1000,
    );

    if ( photo == null ) return null;

    return photo.path;
  }

  @override
  Future<String?> takePhoto() async {
    
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1000,
      maxHeight: 1000,
      preferredCameraDevice: CameraDevice.rear
    );

    if ( photo == null ) return null;

    return photo.path;
  }
}