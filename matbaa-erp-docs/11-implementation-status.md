# حالة التنفيذ: ما نُفِّذ من تقريري 09 و 10 وما بقي

**التاريخ:** 2026-10-06
**الفرع:** `arena/1e662821-erp-printer`

---

## 0. ما تم التحقق منه فعلياً وما لم يتم

| الفحص | الحالة | التفصيل |
|---|---|---|
| خوارزمية تشفير النسخة الاحتياطية | ✅ **مُتحقق** | نُفِّذت ترجمة سطرية للخوارزمية في Python وقورنت بـ `hashlib.pbkdf2_hmac` و`hmac` من المكتبة القياسية: تطابق في `salt` و`iv` و`ct` و`mac`، وفك التشفير يعيد النص، وتبديل بايت واحد في `ct` يُرفض |
| متجه اختبار PBKDF2 المضمَّن في `test/backup_and_security_test.dart` | ✅ **مُتحقق** | `hashlib.pbkdf2_hmac('sha256', b'1234', b'0123456789abcdef', 1000, 32)` = `lthrw4diKhMqjsP6Pb8Ut8JakDM53i2wZ0MKCGR8gn4=` — نفس القيمة المضمَّنة |
| أعداد البيانات المرجعية المستخدمة في الاختبارات | ✅ **مُتحقق** | عدّ فعلي في `storage_service.dart`: ورق 18، ماكينات 3، منتجات 4، تشطيبات 12، أحبار 5، عملاء 3، عروض 2، أوامر إنتاج 2، مدفوعات 2، حركات 2 |
| توازن الأقواس في الملفات المعدَّلة | ✅ **مُتحقق** | فحص آلي بعد تجريد السلاسل والتعليقات على 9 ملفات |
| `flutter analyze` | ❌ **لم يُشغَّل** | لا يوجد Flutter/Dart في البيئة ولا شبكة للتنزيل (`curl pub.dev → (35) SSL_ERROR_SYSCALL`) |
| `flutter test` | ❌ **لم يُشغَّل** | السبب نفسه |
| بناء APK / تشغيل التطبيق | ❌ **لم يُجرَّب** | السبب نفسه |

**الخلاصة الصريحة:** التغييرات مكتوبة ومنطق التشفير مُثبت خارج Dart، لكن **لا يوجد
تأكيد بعد بأنها تُصرَّف (compile)**. أول أمر يجب تشغيله على جهاز تطوير:

```bash
flutter pub get
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

`pubspec.lock` لم يُحدَّث (تعذّر `pub get`)، وقد حُذفت حزمتان من `pubspec.yaml`،
فأول `flutter pub get` سيعيد حل الاعتماديات ويحدّث القفل.

---

## 1. ما نُفِّذ في هذه الجولة

### 1.1 النسخة الاحتياطية (تقرير 10 — P0-1…P0-4)

| البند | التنفيذ | الملف |
|---|---|---|
| تشفير بكلمة مرور | `BackupCodec`: PBKDF2-HMAC-SHA256 (60,000 دورة) → مفتاح تشفير + مفتاح وسم مستقلان، تشفير تدفقي بنمط العدّاد HMAC-SHA256، و Encrypt-then-MAC بمقارنة بزمن ثابت | `lib/services/backup_codec.dart` (جديد) |
| النسخة تشمل المستخدمين وسجل التدقيق | `exportBackupJson()` صارت تمر على `_backupKeys` (15 حقلاً) وتكتب `version: 1.2` و`firstRunMode` | `storage_service.dart:345-395` |
| فحص إصدار الصيغة | `supportedBackupVersions = ['1.0','1.1','1.2']`؛ أي إصدار آخر يُرفض برسالة بدل استيراد ناقص صامت | `storage_service.dart:412-430` |
| لقطة أمان قبل الاستيراد | تُكتب في `erp_last_import_safety_backup` قبل أي كتابة، و`restoreSafetySnapshot()` يعيد القاعدة لما قبل الاستيراد | `storage_service.dart:433-490` |
| نتيجة مفصلة بدل `bool` | `BackupImportResult` (نجاح/فشل + سبب + هل شملت المستخدمين + هل أُخذت لقطة) | نهاية `storage_service.dart` |
| واجهة كلمة المرور | حوار «حماية النسخة الاحتياطية» قبل التصدير، وحوار «النسخة مشفّرة» قبل الاستيراد مع إعادة المحاولة عند الخطأ | `settings_view.dart:1230-1470` |
| اسم الملف يميّز الحالة | `erp_backup_encrypted_YYYY-MM-DD.json` مقابل `erp_backup_YYYY-MM-DD.json`، ونص المشاركة يصرّح بحالة التشفير | `settings_view.dart` في `_shareBackupToDrive` |
| خيار نسخة بلا حسابات | `exportBackupJson(includeUsers: false)` لمشاركة ملف مع دعم فني | `storage_service.dart` |

### 1.2 سجل التدقيق (تقرير 10 — P0-6)

- كيان `AuditLogEntry` + `AuditSeverity` في `lib/models/app_models.dart`.
- تخزين بسعة 2000 سطر (الأقدم يُستبعد) في `StorageService` (`loadAuditLog` / `saveAuditLog` / `recordAudit`).
- بصمة الجلسة تُختم تلقائياً عبر `getAuditActor()` / `setAuditActor()` — طبقة التخزين لا تحمل مرجعاً لخدمة المصادقة.
- الأحداث المسجَّلة: `login_success`، `login_failed`، `login_locked`، `login_blocked`، `logout`، `permission_denied`، `user_created`، `user_deleted`، `user_deleted` المرفوض (`user_delete_blocked`)، `role_changed`، `role_change_blocked`، `user_activated`/`user_deactivated`، `pin_changed_self`، `pin_changed_by_admin`، `pin_upgraded`، `demo_records_cleared`، `data_reset_clean`/`data_reset_demo`.
- عارض السجل في `الإعدادات ← سجل التدقيق (N حدث)`.
- السجل يُصدَّر داخل النسخة الاحتياطية.

### 1.3 الصلاحيات وحماية المدير (تقرير 10 — P0-7، P0-8)

- `AuthService.hasPermission` كانت **صفر استدعاء**؛ أُضيفت الآن بوابات فعلية: `guardRole` و`requireAdmin` تُستدعى داخل `createUser` و`updateUserPin` و`changeUserRole` و`toggleUserStatus` و`deleteUser`، وكل رفض يُسجَّل كحدث `permission_denied` بمستوى حرج.
- حماية آخر مدير نشط: منع الحذف، منع التعطيل، منع تخفيض الصلاحية.
- منع حذف الحساب الجاري استخدامه.
- `AuthProvider` يمرر رسائل الرفض للواجهة (`_runGuarded`)، و`user_management_view` صارت تعرضها في SnackBar بدل تجاهلها.

### 1.4 تقوية PIN (تقرير 10 — P1-1، P1-2)

- تجزئة PBKDF2-HMAC-SHA256 (20,000 دورة) + Salt مستقل لكل حساب (`UserAccount.pinSalt`).
- الحسابات القديمة (SHA-256 بلا Salt) تُتحقق كما هي ثم **تُرقّى تلقائياً** عند أول دخول ناجح، مع تسجيل `pin_upgraded`.
- القفل المتصاعد: 5 محاولات ثم 1 ← 5 ← 30 دقيقة (`lockoutMinutesFor`).
- مقارنة التجزئة بزمن ثابت.

### 1.5 البيانات التجريبية (تقرير 10 — P0-10)

- `StorageService.init(firstRunMode: 'demo'|'clean')`، والوضع يُسجَّل في `erp_first_run_mode`.
- `clean` يزرع المرجعيات فقط: 18 ورق + 3 ماكينات + 4 منتجات + 12 تشطيب + 5 أحبار، **بلا** عملاء ولا عروض ولا أوامر إنتاج ولا مدفوعات ولا حركات.
- زر «تحويلها إلى تثبيت فعلي ببيانات نظيفة» في الإعدادات (`clearDemoRecords`) مع تنبيه واضح عند وجود بيانات تجريبية.
- «استعادة الافتراضيات» صار يقدم خيار «استعادة نظيفة بدلاً منها».

### 1.6 إصدار Android (تقرير 10 — P0-9، P1-3)

- `android/app/build.gradle.kts`: `signingConfigs.release` يُبنى من `android/key.properties` أو متغيرات البيئة، ويسقط إلى debug عند غيابها (بدل TODO).
- `android/key.properties.example` + أوامر `keytool`.
- `.gitignore`: `android/key.properties`، `*.jks`، `*.keystore`.
- `AndroidManifest.xml`: إضافة `ACTION_SEND` و`ACTION_SEND_MULTIPLE` إلى `<queries>` — لازم لـ `share_plus` على Android 11+.
- **بقي:** تغيير `applicationId` من `com.example.erp_printer` (قرار اسم الحزمة النهائي لصاحب المشروع).

### 1.7 تنظيف (تقرير 10 — D-1، D-2)

- حُذفت `fl_chart` و`cupertino_icons` من `pubspec.yaml` (كانتا **صفر استيراد** في `lib/`).
- **لم يُحذف بعد:** `assets/icon/` (1.4 MB) و`ERP_مطبعة_متكامل.xls` (871 KB) و`ios/` — تحتاج قراراً من صاحب المشروع (انظر §3).

### 1.8 الجودة والتوثيق

- `matbaa-erp-docs/ci/ci.yml`: `flutter pub get` + `flutter analyze --fatal-infos --fatal-warnings` + `flutter test`. **غير مفعّل**: نقله إلى `.github/workflows/ci.yml` رفضه GitHub لأن رمز Arena لا يملك صلاحية `workflows`؛ أوامر التفعيل مكتوبة في رأس الملف وفي `README.md`.
- `test/backup_and_security_test.dart`: 33 اختباراً للتشفير، PIN، القفل، الصلاحيات، حماية المدير، النسخ الاحتياطي، أوضاع أول التشغيل، وسجل التدقيق.
- `README.md` استُبدل بقالب Flutter الافتراضي بدليل حقيقي (تشغيل، بنية، أمان، إصدار، قيود).
- `SYSTEM_SUMMARY.md`: صُحِّحت أربع عبارات كانت تخالف الكود (التشفير، الفواتير/الباركود/QR، الإصدار 2.5.0، وحالة التخزين).

---

## 2. ما لم يُنفَّذ ويبقى مفتوحاً

| البند | الأولوية | سبب التأجيل |
|---|---|---|
| تضمين خط Cairo محلياً بدل `PdfGoogleFonts` | P0 | يحتاج تنزيل ملفَّي `.ttf` — **لا شبكة في بيئة العمل**. الخطوات جاهزة في `README.md` §القيود (2) |
| `flutter analyze` + `flutter test` فعلياً | P0 | لا Flutter/Dart ولا شبكة |
| SQLite/Drift بدل `SharedPreferences` | P0/P1 | يحتاج حزم جديدة (`sqflite`/`drift`) + ترحيل بيانات + اختبارات؛ حجم عمل مستقل |
| LAN وتعدد المستخدمين | P1 | يعتمد على ما قبله |
| فاتورة PDF مستقلة، سند قبض مطبوع، أمر تشغيل للمصنع | P1 | يحتاج قرار شكل المستند وحقوله القانونية (رقم ضريبي؟) |
| ربط استهلاك الأحبار بأوامر الإنتاج عبر `materialType: 'ink'` | P1 | يحتاج قواعد الهالك لكل ماكينة ولون |
| موردون / مشتريات / جرد / تنبيهات | P2 | وحدات عمل جديدة |
| `locale: ar` + `flutter_localizations` | P2 | يغيّر `pubspec.yaml` و`pubspec.lock`؛ أُجِّل حتى أول `pub get` حقيقي |
| تغيير `applicationId` وتوقيع الإنتاج | P1 قبل النشر | قرار اسم الحزمة + إنشاء keystore بيد صاحب المشروع |
| حذف `assets/icon/` و`ios/` وملف الإكسل من المستودع | P3 | قرار صاحب المشروع |
| تقسيم الملفات العملاقة (`pricing_calculator_view.dart` = 2451 سطر وغيرها) | P2 | إعادة هيكلة مستقلة |

---

## 3. قرارات مطلوبة من صاحب المشروع قبل الجولة القادمة

1. **اسم الحزمة النهائي** لـ Android (مثلاً `com.mohammedradan.matbaa_erp`).
2. هل **iOS** ضمن الخطة؟ إن لا، يُحذف مجلد `ios/` (≈27 ملفاً).
3. هل يُبقى `ERP_مطبعة_متكامل.xls` (871 KB) في المستودع كمصدر توثيقي أم يُنقل خارجاً؟
4. هل كلمة مرور النسخة الاحتياطية **إلزامية** في الاستخدام الفعلي؟ (الحالي: اختيارية مع تحذير).
5. شكل **الفاتورة** و**سند القبض**: هل يلزم رقم ضريبي وضريبة قيمة مضافة وحقول قانونية يمنية؟
6. هل يُسمح بصرف استثنائي بعجز للمدير (البند ما زال ممنوعاً كلياً)؟
