import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/resources/assets.gen.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/extensions/app_padding_extension.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/theme/theme_extensions.dart';
import 'package:app_template/ui/widgets/widgets.dart';

/// Avatars, local and network images, and the captured-photo family — the
/// photo here is the brand logo read from the bundle, so nothing leaves the
/// device.
class MediaDemo extends StatefulWidget {
  const MediaDemo({super.key});

  @override
  State<MediaDemo> createState() => _MediaDemoState();
}

class _MediaDemoState extends State<MediaDemo> {
  CapturedPhoto? _photo;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  /// A photo as a camera would hand it over: bytes plus where and when.
  Future<void> _loadPhoto() async {
    final data = await rootBundle.load(Assets.images.brand.appLogoPng);
    if (!mounted) return;
    setState(
      () => _photo = CapturedPhoto(
        bytes: data.buffer.asUint8List(),
        label: 'app_logo.png',
        mimeType: 'image/png',
        capturedAt: DateTime(2026, 3, 15, 10, 30),
        latitude: 24.7136,
        longitude: 46.6753,
        accuracyMeters: 8,
        capturedBy: LocaleKeys.showcaseName.tr(),
      ),
    );
  }

  void _remove() {
    setState(() => _removed = true);
    context.feedback.info(LocaleKeys.showcaseMediaRemoved.tr());
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final photo = _photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          code: 'AvatarWidget(initial: … | imageUrl: …, radius: …)',
          child: Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AvatarWidget(initial: LocaleKeys.showcaseName.tr(), radius: 16),
              AvatarWidget(initial: LocaleKeys.showcaseItem.tr()),
              AvatarWidget(
                initial: LocaleKeys.showcaseName.tr(),
                radius: 32,
                backgroundColor: context.colors.bgBrand,
                foregroundColor: context.colors.onBrand,
              ),
              // An empty url falls back to the initial.
              const AvatarWidget(imageUrl: '', radius: 32),
            ],
          ),
        ),
        DemoBlock(
          code: 'AppAssetImage(path) · SvgImageWidget(assetPath: …)',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppAssetImage(
                Assets.images.brand.appLogoPng,
                width: 64,
                height: 64,
              ),
              AppAssetImage(
                Assets.images.brand.appLogoSvg,
                width: 64,
                height: 64,
              ),
              SvgImageWidget(
                assetPath: Assets.images.brand.appLogoSvg,
                width: 64,
                height: 64,
              ),
              SvgImageWidget.icon(
                Assets.images.vectors.logoSvg,
                size: 32,
                color: context.colors.primary,
              ),
            ],
          ),
        ),
        DemoBlock(
          code:
              "NetworkImageWidget(imageUrl: '') · "
              "CachedImageWidget(imageUrl: '') — the error state",
          child: const Row(
            children: [
              NetworkImageWidget(imageUrl: '', width: 96, height: 72),
              SizedBox(width: 16),
              CachedImageWidget(imageUrl: '', width: 96, height: 72),
            ],
          ),
        ),
        const DemoBlock(
          code: 'ImagePlaceholderWidget(icon: …, size: …)',
          child: Wrap(
            spacing: 16,
            children: [
              ImagePlaceholderWidget(size: 48),
              ImagePlaceholderWidget(),
              ImagePlaceholderWidget(icon: Icons.videocam_outlined, size: 80),
            ],
          ),
        ),
        DemoBlock(
          code: 'CapturedPhotoImage(photo: CapturedPhoto(bytes: …))',
          child: photo == null
              ? const AppProgress.circular(centered: true)
              : SizedBox(
                  height: 120,
                  child: CapturedPhotoImage(photo: photo, fit: BoxFit.contain),
                ),
        ),
        DemoBlock(
          code: 'CapturedPhotoTile(photo: …, onRemove: …, showMeta: …)',
          child: photo == null
              ? const AppProgress.circular(centered: true)
              : _removed
              ? Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _removed = false),
                    icon: const Icon(Icons.undo),
                    label: Text(LocaleKeys.showcaseReplay.tr()),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: CapturedPhotoTile(
                        photo: photo,
                        height: 160,
                        onRemove: _remove,
                      ),
                    ),
                    12.widthBox,
                    Expanded(
                      child: CapturedPhotoTile(
                        photo: photo,
                        height: 160,
                        showMeta: false,
                      ),
                    ),
                  ],
                ),
        ),
        DemoBlock(
          code:
              'CapturedPhotoViewer.show(context, photo: …) · '
              'AttachmentPreview.open(context, photo: …)',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                text: LocaleKeys.showcaseMediaOpenViewer.tr(),
                variant: AppButtonVariant.outlined,
                isEnabled: photo != null,
                onTap: () => CapturedPhotoViewer.show(
                  context,
                  photo: photo!,
                  onDelete: _remove,
                ),
              ),
              AppButton(
                text: LocaleKeys.showcaseMediaPreview.tr(),
                variant: AppButtonVariant.outlined,
                isEnabled: photo != null && AttachmentPreview.canPreview(photo),
                onTap: () => AttachmentPreview.open(context, photo: photo!),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
