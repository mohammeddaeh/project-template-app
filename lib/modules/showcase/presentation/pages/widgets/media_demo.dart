import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_template/modules/showcase/presentation/demo_block.dart';
import 'package:app_template/modules/showcase/presentation/demo_playground.dart';
import 'package:app_template/modules/showcase/presentation/pages/widgets/playground_tokens.dart';
import 'package:app_template/resources/assets.gen.dart';
import 'package:app_template/resources/locale_keys.g.dart';
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

  static const _fits = <String, BoxFit>{
    'BoxFit.contain': BoxFit.contain,
    'BoxFit.cover': BoxFit.cover,
    'BoxFit.fill': BoxFit.fill,
    'BoxFit.scaleDown': BoxFit.scaleDown,
  };

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

  void _remove() => context.feedback.info(LocaleKeys.showcaseMediaRemoved.tr());

  void _tapped() => context.feedback.info(LocaleKeys.showcaseMediaTapped.tr());

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final photo = _photo;
    final png = Assets.images.brand.appLogoPng;
    final svg = Assets.images.brand.appLogoSvg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── AvatarWidget ────────────────────────────────────────────────────
        DemoPlayground(
          call: 'AvatarWidget',
          knobs: [
            TextKnob('initial', initial: LocaleKeys.showcaseName.tr()),
            // An empty url falls back to the initial — no request here.
            ChoiceKnob<String?>('imageUrl', const {
              'null': null,
              "''": '',
            }, apiDefaultCode: 'null'),
            const NumberKnob(
              'radius',
              initial: 24,
              min: 12,
              max: 56,
              integer: true,
              apiDefault: 24,
            ),
            colorKnob('backgroundColor', const ['bgBrand', 'primary']),
            colorKnob('foregroundColor', const ['onBrand', 'textOnPrimary']),
          ],
          builder: (context, k) => AvatarWidget(
            initial: k('initial'),
            imageUrl: k('imageUrl'),
            radius: k('radius'),
            backgroundColor: tokenColor(context, k('backgroundColor')),
            foregroundColor: tokenColor(context, k('foregroundColor')),
          ),
        ),
        // ── AppAssetImage ───────────────────────────────────────────────────
        DemoPlayground(
          call: 'AppAssetImage',
          knobs: [
            const NumberKnob(
              'width',
              initial: 160,
              min: 48,
              max: 240,
              integer: true,
            ),
            const NumberKnob(
              'height',
              initial: 80,
              min: 32,
              max: 160,
              integer: true,
            ),
            ChoiceKnob<BoxFit>('fit', _fits, apiDefaultCode: 'BoxFit.contain'),
            colorKnob('color', const ['primary', 'error']),
            ChoiceKnob<BlendMode>('colorBlendMode', const {
              'BlendMode.srcIn': BlendMode.srcIn,
              'BlendMode.modulate': BlendMode.modulate,
              'BlendMode.srcATop': BlendMode.srcATop,
              'BlendMode.multiply': BlendMode.multiply,
            }, apiDefaultCode: 'BlendMode.srcIn'),
          ],
          // A named argument may come before the positional path.
          trailingCode: const ['Assets.images.brand.appLogoPng'],
          builder: (context, k) => _Outlined(
            child: AppAssetImage(
              png,
              width: k('width'),
              height: k('height'),
              fit: k('fit'),
              color: tokenColor(context, k('color')),
              colorBlendMode: k('colorBlendMode'),
            ),
          ),
        ),
        // ── SvgImageWidget ──────────────────────────────────────────────────
        DemoPlayground(
          call: 'SvgImageWidget',
          knobs: [
            ChoiceKnob<String>('assetPath', {
              'Assets.images.brand.appLogoSvg': svg,
              'Assets.images.vectors.logoSvg': Assets.images.vectors.logoSvg,
            }, required: true),
            const NumberKnob(
              'width',
              initial: 160,
              min: 32,
              max: 240,
              integer: true,
            ),
            const NumberKnob(
              'height',
              initial: 64,
              min: 32,
              max: 160,
              integer: true,
            ),
            ChoiceKnob<BoxFit>('fit', _fits, apiDefaultCode: 'BoxFit.contain'),
            colorKnob('color', const ['primary', 'error'], initial: 'primary'),
          ],
          builder: (context, k) => _Outlined(
            child: SvgImageWidget(
              assetPath: k('assetPath'),
              width: k('width'),
              height: k('height'),
              fit: k('fit'),
              color: tokenColor(context, k('color')),
            ),
          ),
        ),
        DemoBlock(
          code:
              'AppAssetImage(svg) · SvgImageWidget.icon(path, size: …, '
              'color: …)',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppAssetImage(svg, width: 64, height: 64),
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
        DemoPlayground(
          call: 'ImagePlaceholderWidget',
          knobs: [
            ChoiceKnob<IconData>('icon', const {
              'Icons.image_outlined': Icons.image_outlined,
              'Icons.videocam_outlined': Icons.videocam_outlined,
              'Icons.description_outlined': Icons.description_outlined,
            }, apiDefaultCode: 'Icons.image_outlined'),
            const NumberKnob(
              'size',
              initial: 64,
              min: 32,
              max: 120,
              integer: true,
              apiDefault: 64,
            ),
          ],
          builder: (context, k) =>
              ImagePlaceholderWidget(icon: k('icon'), size: k('size')),
        ),
        // ── The captured-photo family ───────────────────────────────────────
        DemoBlock(
          code: 'CapturedPhotoImage(photo: CapturedPhoto(bytes: …))',
          child: photo == null
              ? const AppProgress.circular(centered: true)
              : SizedBox(
                  height: 120,
                  child: CapturedPhotoImage(photo: photo, fit: BoxFit.contain),
                ),
        ),
        if (photo == null)
          const DemoBlock(
            code: 'CapturedPhotoTile(photo: …)',
            child: AppProgress.circular(centered: true),
          )
        else
          DemoPlayground(
            call: 'CapturedPhotoTile',
            knobs: [
              callbackKnob('onRemove', code: '() => toast(…)'),
              // Without one, a tap opens AttachmentPreview by itself.
              callbackKnob('onTap', code: '() => toast(…)', initial: false),
              const NumberKnob(
                'height',
                initial: 160,
                min: 100,
                max: 240,
                integer: true,
              ),
              const BoolKnob('showMeta', initial: true, apiDefault: true),
            ],
            trailingCode: const ['photo: photo'],
            builder: (context, k) => SizedBox(
              width: 220,
              child: CapturedPhotoTile(
                photo: photo,
                onRemove: k('onRemove') ? _remove : null,
                onTap: k('onTap') ? _tapped : null,
                height: k('height'),
                showMeta: k('showMeta'),
              ),
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

/// A hairline around the image's box, so `fit` has an edge to be read against.
class _Outlined extends StatelessWidget {
  const _Outlined({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: context.colors.borderSubtle),
    ),
    child: child,
  );
}
