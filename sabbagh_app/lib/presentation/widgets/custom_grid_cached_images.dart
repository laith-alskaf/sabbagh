import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/presentation/modules/purchase_orders/controller.dart';

class CachedImagesGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double childAspectRatio;
  final double? spacing;

  const CachedImagesGrid({
    Key? key,
    required this.imageUrls,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.spacing,
  }) : super(key: key);

  void _openImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.all(0),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.1,
              maxScale: 3.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final double spacingValue = spacing ?? 8.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 8,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 10,
              child: GestureDetector(
                onTap: () => _openImagePreview(context, imageUrls[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.fill,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[300],
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                          ),
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            Expanded(
              flex: 1,
              child: FutureBuilder<String?>(
                future: Get.find<PurchaseOrderController>().resolveUploaderName(
                  imageUrls[index],
                ),
                builder: (context, snapshot) {
                  final uploader = snapshot.data;
                  if (uploader == null || uploader.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    textAlign: TextAlign.center,
                    uploader,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
