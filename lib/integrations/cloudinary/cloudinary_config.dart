/// Public Cloudinary delivery configuration.
///
/// Cloud names and public IDs are safe to ship in the app. Never put an API
/// key, API secret, upload preset, or signed delivery secret here.
class CloudinaryConfig {
  const CloudinaryConfig._();

  static const cloudName = 'ea91sdts';

  static String videoUrl(String publicIdOrUrl) {
    if (publicIdOrUrl.startsWith('https://')) return publicIdOrUrl;
    return 'https://res.cloudinary.com/$cloudName/video/upload/q_auto,f_auto/$publicIdOrUrl.mp4';
  }

  static String posterUrl(String publicIdOrUrl) {
    final publicId = publicIdOrUrl.startsWith('https://')
        ? publicIdOrUrl.split('/').last.split('.').first
        : publicIdOrUrl;
    return 'https://res.cloudinary.com/$cloudName/video/upload/so_3,w_1280,h_720,c_fill,q_auto,f_auto/$publicId.jpg';
  }
}
