import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:centrex/core/extensions/sizer.dart';
import '../../../core/resources/app_colors.dart';

class FullScreenImageViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(
      initialPage: initialIndex,
    );
    final ValueNotifier<int> currentIndex = ValueNotifier<int>(initialIndex);

    return Scaffold(
      backgroundColor: AppColor.appDarkColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: pageController,
              itemCount: images.length,
              onPageChanged: (index) => currentIndex.value = index,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Center(
                        child: CupertinoActivityIndicator(
                          radius: 12,
                          color: AppColor.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            color: AppColor.white.withValues(alpha: 0.5),
                            size: 15.w,
                          ),
                          2.height,
                          Text(
                            "Image not available",
                            style: TextStyle(
                              color: AppColor.white,
                              fontSize: 3.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top Header (Close Button & Indicator)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 1.h,
                left: 4.w,
                right: 4.w,
                bottom: 2.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 6.w,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: currentIndex,
                    builder: (context, index, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 0.8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${index + 1} / ${images.length}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 3.2.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 40), // Balance for centering logic
                ],
              ),
            ),
          ),

          // Bottom Hint
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 2.h,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Pinch to zoom • Swipe to navigate",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 2.5.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
