import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:kit_contracts/kit_contracts.dart';

import 'package:app_template/core/di/injection.dart';
import 'package:app_template/resources/locale_keys.g.dart';
import 'package:app_template/ui/feedback/feedback_extension.dart';
import 'package:app_template/ui/widgets/inputs/signature_pad.dart';
import 'package:app_template/ui/widgets/layout/app_button.dart';

/// Write by hand, get text: a [SignaturePad] and a button that hands the ink
/// to `kit_ink` and passes the likeliest reading to [onText].
///
/// Draws nothing when `kit_ink` is not installed. The language's model is
/// fetched once, on the user's tap — the button says so before it happens,
/// because it is several megabytes from Google.
class HandwritingInput extends StatefulWidget {
  const HandwritingInput({super.key, required this.onText, this.languageCode});

  final ValueChanged<String> onText;

  /// The writing's language — the app's language when null.
  final String? languageCode;

  @override
  State<HandwritingInput> createState() => _HandwritingInputState();
}

class _HandwritingInputState extends State<HandwritingInput> {
  final _ink = InkController();
  bool? _hasModel;
  bool _busy = false;
  String? _checkedFor;

  String get _language => widget.languageCode ?? context.locale.languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (getIt.isRegistered<InkRecognizer>() && _checkedFor != _language) {
      _checkedFor = _language;
      getIt<InkRecognizer>().hasModel(_language).then((has) {
        if (mounted) setState(() => _hasModel = has);
      });
    }
  }

  @override
  void dispose() {
    _ink.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() => _busy = true);
    final ok = await getIt<InkRecognizer>().downloadModel(_language);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _hasModel = ok;
    });
    if (!ok) context.feedback.warning(LocaleKeys.inkDownloadFailed.tr());
  }

  Future<void> _recognize() async {
    if (_ink.isEmpty) return;
    setState(() => _busy = true);
    final candidates = await getIt<InkRecognizer>().recognize(
      _ink.strokes,
      languageCode: _language,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (candidates == null) {
      context.feedback.warning(LocaleKeys.inkFailed.tr());
    } else if (candidates.isEmpty || candidates.first.trim().isEmpty) {
      context.feedback.warning(LocaleKeys.inkNoMatch.tr());
    } else {
      widget.onText(candidates.first);
      _ink.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<InkRecognizer>()) return const SizedBox.shrink();
    // ignore: unnecessary_statements — EasyLocalization dependency for reactive .tr()
    context.locale;
    final hasModel = _hasModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SignaturePad(controller: _ink, hint: LocaleKeys.inkWriteHere.tr()),
        const SizedBox(height: 8),
        if (hasModel == false)
          AppButton(
            text: LocaleKeys.inkDownloadModel.tr(args: [_language]),
            variant: AppButtonVariant.outlined,
            leadingIcon: Icons.download_outlined,
            isLoading: _busy,
            onTap: _download,
          )
        else
          AppButton(
            text: LocaleKeys.inkRecognize.tr(),
            variant: AppButtonVariant.tonal,
            leadingIcon: Icons.text_fields,
            isLoading: _busy,
            isEnabled: hasModel == true,
            onTap: _recognize,
          ),
      ],
    );
  }
}
