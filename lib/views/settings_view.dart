import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../services/backup_codec.dart';
import '../theme/app_theme.dart';
import '../widgets/erp_components.dart';

class SettingsView extends StatefulWidget {
  final Function(int)? onNavigate;
  final Function(int, int)? onNavigateWithTab;

  const SettingsView({
    super.key,
    this.onNavigate,
    this.onNavigateWithTab,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  DateTime? _lastBackupTime;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  late TextEditingController _sheetSizeCtrl;
  late TextEditingController _unitSizeCtrl;
  late TextEditingController _platePriceCtrl;
  late TextEditingController _marginCtrl;
  late TextEditingController _workHoursCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _companyNameCtrl;
  late TextEditingController _companyPhoneCtrl;
  late TextEditingController _companyAddressCtrl;
  late TextEditingController _taxNumberCtrl;
  late TextEditingController _quotationNotesCtrl;

  static const String developerName = 'محمد رعدان';
  static const String developerPhone = '775420410';

  @override
  void initState() {
    super.initState();
    final s = context.read<ErpProvider>().settings;
    _sheetSizeCtrl = TextEditingController(text: s.sheetSize);
    _unitSizeCtrl = TextEditingController(text: s.unitSize);
    _platePriceCtrl = TextEditingController(text: '${s.defaultPlatePrice.toInt()}');
    _marginCtrl = TextEditingController(text: '${s.defaultProfitMarginPct.toInt()}');
    _workHoursCtrl = TextEditingController(text: '${s.workHoursPerDay.toInt()}');
    _currencyCtrl = TextEditingController(text: s.currency);
    _taxCtrl = TextEditingController(text: '${s.taxPct.toInt()}');
    _companyNameCtrl = TextEditingController(text: s.companyName);
    _companyPhoneCtrl = TextEditingController(text: s.companyPhone);
    _companyAddressCtrl = TextEditingController(text: s.companyAddress);
    _taxNumberCtrl = TextEditingController(text: s.taxNumber);
    _quotationNotesCtrl = TextEditingController(text: s.quotationNotes);
  }

  @override
  void dispose() {
    _sheetSizeCtrl.dispose();
    _unitSizeCtrl.dispose();
    _platePriceCtrl.dispose();
    _marginCtrl.dispose();
    _workHoursCtrl.dispose();
    _currencyCtrl.dispose();
    _taxCtrl.dispose();
    _companyNameCtrl.dispose();
    _companyPhoneCtrl.dispose();
    _companyAddressCtrl.dispose();
    _taxNumberCtrl.dispose();
    _quotationNotesCtrl.dispose();
    super.dispose();
  }

  void _navigateTo(int viewIndex, [int subTab = 0]) {
    if (widget.onNavigateWithTab != null) {
      widget.onNavigateWithTab!(viewIndex, subTab);
    } else if (widget.onNavigate != null) {
      widget.onNavigate!(viewIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.watch<ErpProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط العنوان وأزرار الحفظ السريعة
          _buildHeader(erp),
          const SizedBox(height: 20),

          // مركز إدارة الأسعار والتكاليف والمواد
          _buildPricingControlCenterCard(erp),
          const SizedBox(height: 18),

          // كرت هوية وبيانات المطبعة والفواتير
          _buildCompanyCard(),
          const SizedBox(height: 18),

          // كرت الثوابت الهندسية ومقاسات الأفرخ
          _buildEngineeringConstantsCard(),
          const SizedBox(height: 18),

          // كرت العملة والضريبة المضافة
          _buildCurrencyAndTaxCard(),
          const SizedBox(height: 18),

          // كرت النسخ الاحتياطي واستعادة البيانات
          _buildBackupRestoreCard(erp),
          const SizedBox(height: 20),

          // تذييل خفيف للمطور
          _buildDeveloperCreditLight(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- عنوان موحد لإعدادات النظام ---
  Widget _buildHeader(ErpProvider erp) {
    return ErpPageHeader(
      title: 'إعدادات النظام والمنشأة',
      subtitle: 'ثوابت التسعير وبيانات المنشأة والعملة والنسخ الاحتياطي',
      icon: Icons.settings_suggest_outlined,
      actions: [
        OutlinedButton.icon(
          onPressed: () => _confirmResetData(erp),
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('استعادة الافتراضيات'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.danger,
            side: const BorderSide(color: AppTheme.danger),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _saveSettings(erp),
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('حفظ الإعدادات'),
        ),
      ],
    );
  }

  // --- كرت إدارة الأسعار والتكاليف والمواد الحية ---
  Widget _buildPricingControlCenterCard(ErpProvider erp) {
    final currency = erp.settings.currency;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.selectedSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Icon(Icons.price_change_rounded, color: AppTheme.primaryLight, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مركز التحكم في الأسعار والتكاليف والمواد',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'تعديل فوري لأسعار الورق والمخزون، ماكينات الطباعة، خامات التشطيب، والزنكات بمزامنة حية',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final width = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // 1. أسعار الورق والخامات
                  SizedBox(
                    width: width,
                    child: _buildPriceActionTile(
                      icon: Icons.layers_rounded,
                      iconColor: AppTheme.primaryLight,
                      title: 'أسعار ومقاسات الورق',
                      subtitle: '${erp.papers.length} صنف مسجل • تعديل أسعار الرزم والأفرخ ومقاسات المخزون',
                      primaryBtnLabel: 'تعديل أسعار الورق',
                      onPrimaryPressed: () => _navigateTo(11, 0),
                      secondaryBtnLabel: 'المخزون والكميات',
                      onSecondaryPressed: () => _navigateTo(4, 0),
                    ),
                  ),

                  // 2. تكاليف وماكينات الطباعة
                  SizedBox(
                    width: width,
                    child: _buildPriceActionTile(
                      icon: Icons.precision_manufacturing_rounded,
                      iconColor: AppTheme.primaryLight,
                      title: 'تكاليف وماكينات الطباعة',
                      subtitle: '${erp.machines.length} ماكينة • تعديل سعر ساعة التشغيل والتجهيز وسرعة السحب',
                      primaryBtnLabel: 'تعديل أسعار الماكينات',
                      onPrimaryPressed: () => _navigateTo(11, 1),
                      secondaryBtnLabel: 'بيانات الماكينات',
                      onSecondaryPressed: () => _navigateTo(8, 0),
                    ),
                  ),

                  // 3. خامات وخدمات التشطيب
                  SizedBox(
                    width: width,
                    child: _buildPriceActionTile(
                      icon: Icons.auto_fix_high_rounded,
                      iconColor: AppTheme.primaryLight,
                      title: 'خامات وخدمات التشطيب',
                      subtitle: '${erp.finishings.length} خدمة • سلوفان لامع/مط، غراء، سلك، تكسير وبصمة',
                      primaryBtnLabel: 'تعديل أسعار التشطيب',
                      onPrimaryPressed: () => _navigateTo(11, 2),
                    ),
                  ),

                  // 4. ثوابت الزنكات والأرباح
                  SizedBox(
                    width: width,
                    child: _buildPriceActionTile(
                      icon: Icons.tune_rounded,
                      iconColor: AppTheme.primaryLight,
                      title: 'الزنكات وهوامش الأرباح',
                      subtitle: 'سعر الزنك (${erp.settings.defaultPlatePrice.toInt()} $currency) • الربح (${erp.settings.defaultProfitMarginPct.toInt()}%) • الضريبة (${erp.settings.taxPct.toInt()}%)',
                      primaryBtnLabel: 'تعديل الثوابت والزنكات',
                      onPrimaryPressed: () => _navigateTo(11, 3),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _navigateTo(11, 0),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.selectedSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: AppTheme.primaryLight, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'فتح لوحة إدارة الأسعار والتكاليف الشاملة (جميع الأقسام والخامات)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String primaryBtnLabel,
    required VoidCallback onPrimaryPressed,
    String? secondaryBtnLabel,
    VoidCallback? onSecondaryPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ElevatedButton(
                onPressed: onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  elevation: 0,
                ),
                child: Text(primaryBtnLabel),
              ),
              if (secondaryBtnLabel != null && onSecondaryPressed != null)
                OutlinedButton(
                  onPressed: onSecondaryPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                    textStyle: const TextStyle(fontSize: 11.5),
                  ),
                  child: Text(secondaryBtnLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- كرت 1: بيانات وهوية المطبعة ---
  Widget _buildCompanyCard() {
    return _buildSectionCard(
      title: 'بيانات وهوية المطبعة (للفواتير وعروض الأسعار)',
      subtitle: 'تظهر هذه البيانات في ترويسة وتذييل عروض الأسعار والتقارير المطبوعة بصيغة PDF',
      icon: Icons.storefront_rounded,
      iconColor: AppTheme.primaryLight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final nameField = TextFormField(
            controller: _companyNameCtrl,
            decoration: const InputDecoration(
              labelText: 'اسم المطبعة / المنشأة',
              prefixIcon: Icon(Icons.business_rounded, size: 20),
            ),
          );

          final phoneField = TextFormField(
            controller: _companyPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'هاتف التواصل',
              prefixIcon: Icon(Icons.phone_rounded, size: 20),
            ),
          );

          final addressField = TextFormField(
            controller: _companyAddressCtrl,
            decoration: const InputDecoration(
              labelText: 'العنوان الكامل للمطبعة',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
          );

          final taxField = TextFormField(
            controller: _taxNumberCtrl,
            decoration: const InputDecoration(
              labelText: 'الرقم الضريبي (إن وجد)',
              prefixIcon: Icon(Icons.pin_rounded, size: 20),
            ),
          );

          final notesField = TextFormField(
            controller: _quotationNotesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'شروط وملاحظات عروض الأسعار الافتراضية (تظهر في الـ PDF)',
              prefixIcon: Icon(Icons.edit_note_rounded, size: 22),
            ),
          );

          if (isNarrow) {
            return Column(
              children: [
                nameField,
                const SizedBox(height: 12),
                phoneField,
                const SizedBox(height: 12),
                addressField,
                const SizedBox(height: 12),
                taxField,
                const SizedBox(height: 12),
                notesField,
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(flex: 2, child: nameField),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: phoneField),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(flex: 2, child: addressField),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: taxField),
                ],
              ),
              const SizedBox(height: 14),
              notesField,
            ],
          );
        },
      ),
    );
  }

  // --- كرت 2: الثوابت الهندسية والتسعيرية ---
  Widget _buildEngineeringConstantsCard() {
    return _buildSectionCard(
      title: 'الثوابت الهندسية والتشغيلية',
      subtitle: 'القيم الافتراضية المستخدمة في محرك التسعير الآلي لحساب الملازم والألواح وساعات التشغيل',
      icon: Icons.engineering_rounded,
      iconColor: AppTheme.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 650;
              if (isCompact) {
                return Column(
                  children: [
                    TextFormField(
                      controller: _sheetSizeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'مقاس الفرخ القياسي (سم)',
                        prefixIcon: Icon(Icons.aspect_ratio_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildQuickOptions(['100x70', '102x72', '88x66'], (val) {
                      setState(() => _sheetSizeCtrl.text = val);
                    }),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _unitSizeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'مقاس الملزمة القياسي (سم)',
                        prefixIcon: Icon(Icons.grid_view_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildQuickOptions(['50x35', '48x33', '35x25'], (val) {
                      setState(() => _unitSizeCtrl.text = val);
                    }),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _platePriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر البليت / الزنك الافتراضي',
                        prefixIcon: const Icon(Icons.layers_rounded, size: 20),
                        suffixText: _currencyCtrl.text,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _sheetSizeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'مقاس الفرخ القياسي (سم)',
                                prefixIcon: Icon(Icons.aspect_ratio_rounded, size: 20),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildQuickOptions(['100x70', '102x72', '88x66'], (val) {
                              setState(() => _sheetSizeCtrl.text = val);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _unitSizeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'مقاس الملزمة القياسي (سم)',
                                prefixIcon: Icon(Icons.grid_view_rounded, size: 20),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildQuickOptions(['50x35', '48x33', '35x25'], (val) {
                              setState(() => _unitSizeCtrl.text = val);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _platePriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'سعر البليت / الزنك الافتراضي',
                                prefixIcon: const Icon(Icons.layers_rounded, size: 20),
                                suffixText: _currencyCtrl.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildQuickOptions(['1000', '1250', '1500'], (val) {
                              setState(() => _platePriceCtrl.text = val);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _marginCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'هامش الربح الافتراضي %',
                        prefixIcon: Icon(Icons.trending_up_rounded, size: 20),
                        suffixText: '%',
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildQuickOptions(['20', '25', '30', '35', '40'], (val) {
                      setState(() => _marginCtrl.text = val);
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _workHoursCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ساعات العمل اليومية',
                        prefixIcon: Icon(Icons.schedule_rounded, size: 20),
                        suffixText: 'ساعة/يوم',
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildQuickOptions(['8', '10', '12'], (val) {
                      setState(() => _workHoursCtrl.text = val);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- كرت 3: العملة والضريبة ---
  Widget _buildCurrencyAndTaxCard() {
    return _buildSectionCard(
      title: 'العملة والضريبة المضافة (Currency & Tax)',
      subtitle: 'العملة الرئيسية المعتمدة لكافة التسعيرات وعروض الأسعار، ونسبة الضريبة المحتسبة',
      icon: Icons.currency_exchange_rounded,
      iconColor: AppTheme.accentGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _currencyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'عملة النظام المعتمدة',
                        prefixIcon: Icon(Icons.monetization_on_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildQuickOptions(['ريال', 'ريال يمني', 'ريال سعودي', 'دولار', '\$'], (val) {
                      setState(() => _currencyCtrl.text = val);
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _taxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'نسبة الضريبة (VAT)',
                        prefixIcon: Icon(Icons.percent_rounded, size: 20),
                        suffixText: '%',
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildQuickOptions(['0', '5', '15'], (val) {
                      setState(() => _taxCtrl.text = val);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- كرت 4: النسخ الاحتياطي على Google Drive ---
  Widget _buildBackupRestoreCard(ErpProvider erp) {
    return _buildSectionCard(
      title: 'النسخ الاحتياطي على Google Drive',
      subtitle: 'تصدير نسخة كاملة محميّة بكلمة مرور (PBKDF2 + تشفير تدفقي + HMAC) أو استيراد نسخة سابقة',
      icon: Icons.cloud_done_rounded,
      iconColor: AppTheme.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقة حالة النسخة الاحتياطية
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.infoSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Icon(Icons.drive_folder_upload_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Drive',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lastBackupTime != null
                            ? 'آخر نسخة: ${_formatDateTime(_lastBackupTime!)}'
                            : 'لم يتم عمل نسخة احتياطية بعد',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    '${erp.customers.length + erp.quotations.length + erp.papers.length} سجل',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // شرح آلية العمل
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'سيُصدَّر ملف erp_backup.json وتُفتح نافذة المشاركة → اختر Google Drive لرفعه مباشرةً.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // أزرار العمليات
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // زر الرفع على Drive
                  SizedBox(
                    width: isNarrow ? double.infinity : null,
                    child: ElevatedButton.icon(
                      onPressed: _isBackingUp ? null : () => _shareBackupToDrive(erp),
                      icon: _isBackingUp
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.drive_folder_upload_rounded, size: 18),
                      label: Text(_isBackingUp ? 'جارٍ التصدير...' : 'رفع نسخة على Drive'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.info,
                        foregroundColor: AppTheme.scaffoldBg,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),

                  // زر الاستيراد من ملف
                  SizedBox(
                    width: isNarrow ? double.infinity : null,
                    child: OutlinedButton.icon(
                      onPressed: _isRestoring ? null : () => _importBackupFromFile(erp),
                      icon: _isRestoring
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(_isRestoring ? 'جارٍ الاستيراد...' : 'استعادة من ملف'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.info,
                        side: const BorderSide(color: AppTheme.info),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),

                  // زر نسخ JSON للحافظة (بديل احتياطي)
                  TextButton.icon(
                    onPressed: () => _exportBackupDialog(erp),
                    icon: const Icon(Icons.copy_all_rounded, size: 16),
                    label: const Text('نسخ JSON للحافظة'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // تنبيه: هذه القاعدة ما زالت تحمل بيانات تجريبية
          if (erp.hasDemoRecords)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.36)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science_rounded, color: AppTheme.warning, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'هذه القاعدة مزروعة ببيانات تجريبية (عملاء وعروض وأوامر إنتاج ومدفوعات وهمية)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warning),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _confirmClearDemoRecords(erp),
                    icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                    label: const Text('تحويلها إلى تثبيت فعلي ببيانات نظيفة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warning,
                      side: BorderSide(color: AppTheme.warning),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // سجل التدقيق
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _showAuditLog(erp),
              icon: const Icon(Icons.history_toggle_off_rounded, size: 16),
              label: Text('سجل التدقيق (${erp.auditLog.length} حدث)'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// تأكيد مسح السجلات التجارية الوهمية قبل التحويل إلى تثبيت فعلي.
  void _confirmClearDemoRecords(ErpProvider erp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: AppTheme.warning),
            SizedBox(width: 8),
            Expanded(child: Text('تحويل إلى تثبيت فعلي')),
          ],
        ),
        content: const Text(
          'سيتم حذف العملاء وعروض الأسعار وأوامر الإنتاج وحركات المخزون والمدفوعات التجريبية.\n'
          'تبقى المرجعيات: أصناف الورق، الماكينات، قوالب المنتجات، التشطيبات، الأحبار، والإعدادات.\n\n'
          'لا يمكن التراجع؛ صدّر نسخة احتياطية أولاً إن كنت تحتاج هذه البيانات.',
          style: TextStyle(fontSize: 12.5, height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () async {
              await erp.recordAudit(
                action: 'demo_records_cleared',
                targetType: 'system',
                details: 'تحويل القاعدة من نسخة تجريبية إلى تثبيت فعلي ببيانات نظيفة',
                severity: AuditSeverity.warning,
              );
              await erp.clearDemoRecords();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('مسح البيانات التجريبية', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// يعرض سجل التدقيق: من فعل ماذا ومتى.
  void _showAuditLog(ErpProvider erp) {
    final entries = erp.auditLog;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.history_toggle_off_rounded, color: AppTheme.info),
            SizedBox(width: 8),
            Text('سجل التدقيق'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width < 550 ? double.maxFinite : 560,
          child: entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد أحداث مسجلة بعد.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 18),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    final color = switch (e.severity) {
                      AuditSeverity.critical => AppTheme.danger,
                      AuditSeverity.warning => AppTheme.warning,
                      AuditSeverity.info => AppTheme.textMuted,
                    };
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              e.success ? Icons.check_circle_outline : Icons.block,
                              size: 15,
                              color: e.success ? AppTheme.success : AppTheme.danger,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.action,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            Text(
                              _formatDateTime(e.timestamp),
                              style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${e.actorName} (${e.actorRole})'
                          '${e.targetId != null ? ' • ${e.targetId}' : ''}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        if (e.details.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(e.details, style: const TextStyle(fontSize: 11.5)),
                          ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  // --- تذييل خفيف للمطور في أسفل الإعدادات ---
  Widget _buildDeveloperCreditLight() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () => _copyDeveloperContact(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.code_rounded, size: 14, color: AppTheme.primaryLight),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'تطوير: م/محمد رعدان • $developerPhone',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 12, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- دوال مساعدة في التصميم ---
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkSlate),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOptions(List<String> options, Function(String) onSelect) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: options.map((opt) {
        return InkWell(
          onTap: () => onSelect(opt),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              opt,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkSlate),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _copyDeveloperContact(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: developerPhone));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('تم نسخ رقم المطور ($developerName - $developerPhone) إلى الحافظة بنجاح'),
            ],
          ),
          backgroundColor: AppTheme.sidebarBg,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _saveSettings(ErpProvider erp) async {
    final s = AppSettings(
      sheetSize: _sheetSizeCtrl.text.trim(),
      unitSize: _unitSizeCtrl.text.trim(),
      defaultPlatePrice: double.tryParse(_platePriceCtrl.text) ?? 1250,
      defaultProfitMarginPct: double.tryParse(_marginCtrl.text) ?? 30,
      workHoursPerDay: double.tryParse(_workHoursCtrl.text) ?? 8,
      currency: _currencyCtrl.text.trim(),
      taxPct: double.tryParse(_taxCtrl.text) ?? 0,
      companyName: _companyNameCtrl.text.trim(),
      companyPhone: _companyPhoneCtrl.text.trim(),
      companyAddress: _companyAddressCtrl.text.trim(),
      taxNumber: _taxNumberCtrl.text.trim(),
      quotationNotes: _quotationNotesCtrl.text.trim(),
    );
    await erp.updateSettings(s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ وتحديث إعدادات النظام بنجاح!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    final d = dt;
    final date = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  // ─────────────────────────────────────────────────────────
  // حماية النسخة الاحتياطية بكلمة مرور
  // ─────────────────────────────────────────────────────────

  /// يسأل المدير عن كلمة مرور (مع تأكيد) ويشفّر بها النسخة.
  ///
  /// يُرجع null إذا ألغى المستخدم. السماح بحقل فارغ يعني نسخة غير مشفّرة
  /// صراحةً، لأن بعض الاستخدامات تحتاج ملفاً يقرأه الدعم الفني.
  Future<String?> _askBackupPassword({
    required String title,
    required String message,
  }) async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var errorText = '';

    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppTheme.info),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 14),
              TextField(
                controller: passCtrl,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (errorText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  errorText,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'اترك الحقلين فارغين لإنشاء نسخة غير مشفّرة (غير مستحسن).',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final pass = passCtrl.text;
                final confirm = confirmCtrl.text;
                if (pass.isEmpty && confirm.isEmpty) {
                  Navigator.pop(ctx, true);
                  return;
                }
                if (pass.length < 6) {
                  setLocal(() => errorText = 'كلمة المرور يجب ألا تقل عن 6 أحرف');
                  return;
                }
                if (pass != confirm) {
                  setLocal(() => errorText = 'كلمتا المرور غير متطابقتين');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('متابعة'),
            ),
          ],
        ),
      ),
    );

    if (accepted != true) return null;
    return passCtrl.text;
  }

  /// ينتج نص النسخة الاحتياطية: مشفراً إن طُلبت كلمة مرور، وإلا نصاً صريحاً.
  Future<String?> _buildBackupPayload(ErpProvider erp) async {
    final raw = erp.exportDatabaseBackup();
    final password = await _askBackupPassword(
      title: 'حماية النسخة الاحتياطية',
      message:
          'النسخة تحتوي أسعار التكلفة والعملاء والذمم وحسابات المستخدمين. '
          'يُنصح بتشفيرها بكلمة مرور قبل حفظها أو رفعها.',
    );
    if (password == null) return null;
    if (password.isEmpty) return raw;
    return BackupCodec.encrypt(raw, password);
  }

  /// يفك تشفير ملف مستورد إن كان محمياً. يُرجع null عند الإلغاء.
  Future<String?> _resolveImportPayload(String raw) async {
    if (!BackupCodec.isEncrypted(raw)) return raw;

    final ctrl = TextEditingController();
    var errorText = '';
    while (true) {
      if (!mounted) return null;
      final password = await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: AppTheme.info),
                SizedBox(width: 10),
                Text('النسخة مشفّرة'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'هذه النسخة محمية بكلمة مرور. أدخل كلمة المرور لفتحها.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (errorText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorText,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('فتح النسخة'),
              ),
            ],
          ),
        ),
      );
      if (password == null) return null;
      try {
        return BackupCodec.decrypt(raw, password);
      } on BackupCryptoException catch (e) {
        errorText = e.message;
      }
    }
  }

  // --- رفع النسخة الاحتياطية إلى Google Drive عبر Share ---
  Future<void> _shareBackupToDrive(ErpProvider erp) async {
    setState(() => _isBackingUp = true);
    try {
      final backupJson = await _buildBackupPayload(erp);
      if (backupJson == null) {
        if (mounted) setState(() => _isBackingUp = false);
        return;
      }
      final encrypted = BackupCodec.isEncrypted(backupJson);
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName =
          'erp_backup_${encrypted ? 'encrypted_' : ''}$dateStr.json';

      // حفظ الملف في مجلد مؤقت
      final tmpDir = await getTemporaryDirectory();
      final file = File('${tmpDir.path}/$fileName');
      await file.writeAsString(backupJson, flush: true);

      // فتح نافذة المشاركة الأصلية
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'نسخة احتياطية ERP مطبعة – $dateStr',
        text: encrypted
            ? 'نسخة احتياطية مشفّرة بكلمة مرور من نظام ERP المطبعة. قم برفعه على Google Drive، واحفظ كلمة المرور بشكل منفصل في مكان آمن.'
            : 'نسخة احتياطية غير مشفّرة من نظام ERP المطبعة. تُقرأ أسعار التكلفة والعملاء كنص صريح؛ ارفعها على حساب موثوق فقط.',
      );

      if (mounted) {
        setState(() => _lastBackupTime = now);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('تم تصدير الملف بنجاح! اختر Google Drive من نافذة المشاركة')),
              ],
            ),
            backgroundColor: AppTheme.info,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تصدير النسخة الاحتياطية: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  // --- استيراد نسخة احتياطية (لصق JSON أو استيراد من ملف) ---
  Future<void> _importBackupFromFile(ErpProvider erp) async {
    final ctrl = TextEditingController();

    // محاولة لصق تلقائي من الحافظة
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text?.isNotEmpty == true) {
      ctrl.text = clipboardData!.text!;
    }

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.upload_file_rounded, color: AppTheme.info, size: 26),
            SizedBox(width: 10),
            Text('استعادة من نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width < 550 ? double.maxFinite : 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withValues(alpha: 0.36)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم استبدال كافة البيانات الحالية بالبيانات المستوردة.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('الصق كود JSON للنسخة الاحتياطية:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 7,
                decoration: InputDecoration(
                  hintText: 'الصق كود النسخة الاحتياطية هنا...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded),
                    tooltip: 'لصق من الحافظة',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) ctrl.text = data!.text!;
                    },
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.info,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('استعادة وتطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    final payload = await _resolveImportPayload(result);
    if (payload == null) return;

    setState(() => _isRestoring = true);
    try {
      final importResult = await erp.importDatabaseBackup(payload);
      final success = importResult.isSuccess;

      if (mounted) {
        if (success) {
          final s = erp.settings;
          _companyNameCtrl.text = s.companyName;
          _companyPhoneCtrl.text = s.companyPhone;
          _companyAddressCtrl.text = s.companyAddress;
          _taxNumberCtrl.text = s.taxNumber;
          _quotationNotesCtrl.text = s.quotationNotes;
          _sheetSizeCtrl.text = s.sheetSize;
          _unitSizeCtrl.text = s.unitSize;
          _platePriceCtrl.text = '${s.defaultPlatePrice.toInt()}';
          _marginCtrl.text = '${s.defaultProfitMarginPct.toInt()}';
          _workHoursCtrl.text = '${s.workHoursPerDay.toInt()}';
          _currencyCtrl.text = s.currency;
          _taxCtrl.text = '${s.taxPct.toInt()}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('تم استرجاع وتحديث كافة البيانات بنجاح!')),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'فشل الاستيراد: ${importResult.errorMessage ?? 'سبب غير محدد'}',
              ),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  // --- نسخ JSON للحافظة (احتياطي) ---
  Future<void> _exportBackupDialog(ErpProvider erp) async {
    final payload = await _buildBackupPayload(erp);
    if (payload == null || !mounted) return;
    final backupJson = payload;
    final ctrl = TextEditingController(text: backupJson);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.copy_all_rounded, color: AppTheme.primaryLight),
            SizedBox(width: 8),
            Text('نسخ JSON للحافظة'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width < 550 ? double.maxFinite : 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('كود النسخة الاحتياطية الكامل. انسخه واحفظه في مكان آمن:'),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 8,
                readOnly: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: backupJson));
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ بيانات النسخة الاحتياطية إلى الحافظة بنجاح')),
                );
                Navigator.pop(ctx);
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('نسخ إلى الحافظة'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _confirmResetData(ErpProvider erp, {bool clean = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger),
            SizedBox(width: 8),
            Text('استعادة بيانات الإكسل الأصلية'),
          ],
        ),
        content: Text(
          clean
              ? 'سيتم إعادة تعيين البيانات إلى مرجعيات ملف ERP_مطبعة_متكامل.xls (الورق، الماكينات، المنتجات، الأحبار) '
                  'بدون أي عملاء أو عروض أو أوامر إنتاج أو مدفوعات تجريبية.\n\nهذا هو الخيار الصحيح للتثبيت الفعلي.'
              : 'هل أنت متأكد من رغبتك في إعادة تعيين كافة البيانات إلى بيانات ملف ERP_مطبعة_متكامل.xls الأولية؟\n'
                  'سيتم استرجاع الورق، الماكينات، والمنتجات الأصلية مع السجلات التجريبية.',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          if (!clean)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _confirmResetData(erp, clean: true);
              },
              child: const Text('استعادة نظيفة بدلاً منها'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              await erp.recordAudit(
                action: clean ? 'data_reset_clean' : 'data_reset_demo',
                targetType: 'system',
                details: clean
                    ? 'إعادة تعيين البيانات إلى مرجعيات الإكسل بوضع نظيف'
                    : 'إعادة تعيين البيانات إلى مرجعيات الإكسل مع السجلات التجريبية',
                severity: AuditSeverity.critical,
              );
              await erp.resetToExcelDefaults(clean: clean);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                final s = erp.settings;
                _sheetSizeCtrl.text = s.sheetSize;
                _unitSizeCtrl.text = s.unitSize;
                _platePriceCtrl.text = '${s.defaultPlatePrice.toInt()}';
                _marginCtrl.text = '${s.defaultProfitMarginPct.toInt()}';
                _workHoursCtrl.text = '${s.workHoursPerDay.toInt()}';
                _currencyCtrl.text = s.currency;
                _taxCtrl.text = '${s.taxPct.toInt()}';
                _companyNameCtrl.text = s.companyName;
                _companyPhoneCtrl.text = s.companyPhone;
                _companyAddressCtrl.text = s.companyAddress;
                _taxNumberCtrl.text = s.taxNumber;
                _quotationNotesCtrl.text = s.quotationNotes;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم استرجاع بيانات الإكسل الأولية بنجاح!')),
                );
              }
            },
            child: const Text('تأكيد الاستعادة'),
          ),
        ],
      ),
    );
  }
}
