import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/cdn_utils.dart';

/// Disk-cached network image with CDN proxy resolution for web.
class AppCachedNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const AppCachedNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = CdnUtils.resolve(url);
    if (resolved.isEmpty) {
      return errorWidget ??
          SizedBox(
            width: width,
            height: height,
            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
          );
    }

    Widget image = CachedNetworkImage(
      imageUrl: resolved,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) =>
          placeholder ??
          SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      errorWidget: (_, __, ___) =>
          errorWidget ??
          SizedBox(
            width: width,
            height: height,
            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

/// Cached [ImageProvider] for CircleAvatar / PhotoView / DecorationImage.
ImageProvider? appCachedNetworkImageProvider(String? url) {
  final resolved = CdnUtils.resolve(url);
  if (resolved.isEmpty) return null;
  return CachedNetworkImageProvider(resolved);
}
