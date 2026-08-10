# App Icons — Flavor Icons

ضع هنا 3 أيقونات PNG بحجم **1024 × 1024** قبل تشغيل `dart run scripts/sync_flavors.dart`:

| الملف            | الـ Flavor | الوصف                          |
|-----------------|-----------|-------------------------------|
| icon_dev.png    | dev       | أيقونة بـ badge أحمر أو مختلفة |
| icon_staging.png| staging   | أيقونة بـ badge أصفر           |
| icon_prod.png   | prod      | الأيقونة الرسمية النظيفة        |

## بعد إضافة الأيقونات

```bash
flutter pub get
dart run scripts/sync_flavors.dart
```

## ملاحظات
- PNG فقط، خلفية شفافة مدعومة
- 1024×1024 إلزامي — الأداة تولّد كل الأحجام تلقائياً
- يمكن استخدام نفس الأيقونة للثلاثة مؤقتاً ثم التغيير لاحقاً
