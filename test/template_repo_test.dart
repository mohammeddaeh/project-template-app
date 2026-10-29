import 'package:flutter_test/flutter_test.dart';

import '../scripts/src/template_repo.dart';

/// What `template_drift.dart` and `template_update.dart` treat as the
/// template's, and how a project copy is compared to the template's.
void main() {
  test('the template owns its infrastructure, not the project slices', () {
    expect(isTemplateOwned('lib/core/infra/env.dart'), isTrue);
    expect(isTemplateOwned('lib/ui/widgets/widgets.dart'), isTrue);
    expect(isTemplateOwned('scripts/gen_code.dart'), isTrue);
    expect(isTemplateOwned('CLAUDE.md'), isTrue);

    expect(isTemplateOwned('lib/features/orders/orders.dart'), isFalse);
    expect(isTemplateOwned('lib/main.dart'), isFalse);
    expect(isTemplateOwned('pubspec.yaml'), isFalse);
    expect(isTemplateOwned('docs/TEMPLATE_FEEDBACK.md'), isFalse);
  });

  test('generated files are never compared', () {
    expect(isTemplateOwned('lib/core/di/injection.config.dart'), isFalse);
    expect(isTemplateOwned('lib/ui/x.freezed.dart'), isFalse);
    expect(
      isTemplateOwned('lib/core/platform/features/app_features.dart'),
      isFalse,
    );
  });

  test('a renamed package and CRLF are not a change', () {
    const project = "import 'package:shop/core/x.dart';\r\nvoid f() {}\r\n";
    const template =
        "import 'package:app_template/core/x.dart';\nvoid f() {}\n";
    expect(normalizeFromProject(project, 'shop'), template);
    expect(
      toProject(template, 'shop'),
      "import 'package:shop/core/x.dart';\nvoid f() {}\n",
    );
    expect(toProject(template, templatePackage), template);
  });
}
