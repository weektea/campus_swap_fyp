import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DismissIntent extends Intent {
  const DismissIntent();
}

class PreviousImageIntent extends Intent {
  const PreviousImageIntent();
}

class NextImageIntent extends Intent {
  const NextImageIntent();
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_not_supported, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                'No images available',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousImageIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextImageIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) => Navigator.of(context).pop(),
          ),
          PreviousImageIntent: CallbackAction<PreviousImageIntent>(
            onInvoke: (intent) {
              if (_currentIndex > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              return null;
            },
          ),
          NextImageIntent: CallbackAction<NextImageIntent>(
            onInvoke: (intent) {
              if (_currentIndex < widget.imageUrls.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Main PageView of Zoomable Images
                PageView.builder(
                  controller: _pageController,
                  physics: _isZoomed 
                      ? const NeverScrollableScrollPhysics() 
                      : const BouncingScrollPhysics(),
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Semantics(
                      label: 'Product image ${index + 1} of ${widget.imageUrls.length}',
                      image: true,
                      child: ZoomableImage(
                        imageUrl: widget.imageUrls[index],
                        isCurrentPage: index == _currentIndex,
                        onZoomChanged: (zoomed) {
                          if (_isZoomed != zoomed) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _isZoomed = zoomed;
                                });
                              }
                            });
                          }
                        },
                      ),
                    );
                  },
                ),

                // Top Controls Layer
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back/Close Button
                            CircleAvatar(
                              backgroundColor: Colors.black45,
                              child: IconButton(
                                tooltip: 'Back to product details',
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            
                            // Page Counter Indicator
                            if (widget.imageUrls.length > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Semantics(
                                  label: 'Image page indicator',
                                  child: Text(
                                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Spacer to align counter center/right
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZoomableImage extends StatefulWidget {
  final String imageUrl;
  final bool isCurrentPage;
  final ValueChanged<bool> onZoomChanged;

  const ZoomableImage({
    super.key,
    required this.imageUrl,
    required this.isCurrentPage,
    required this.onZoomChanged,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  late TapDownDetails _doubleTapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void didUpdateWidget(covariant ZoomableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset zoom when the page loses focus
    if (oldWidget.isCurrentPage && !widget.isCurrentPage) {
      _resetZoom();
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    // Use a small margin to handle floating point errors
    widget.onZoomChanged(scale > 1.01);
  }

  void _resetZoom() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
      widget.onZoomChanged(false);
    }
  }

  void _handleDoubleTap() {
    if (_animationController.isAnimating) return;

    if (_transformationController.value != Matrix4.identity()) {
      // Zoom out to normal scale
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.identity(),
      ).animate(
        CurveTween(curve: Curves.easeInOut).animate(_animationController),
      );
      _animationController.forward(from: 0.0);
    } else {
      // Zoom in to tapped area
      final position = _doubleTapDetails.localPosition;
      const double scale = 3.0;

      final double x = -position.dx * (scale - 1.0);
      final double y = -position.dy * (scale - 1.0);

      final Matrix4 zoomed = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);

      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: zoomed,
      ).animate(
        CurveTween(curve: Curves.easeInOut).animate(_animationController),
      );
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.error,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
