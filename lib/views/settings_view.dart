import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/erp_provider.dart';
import '../theme/app_theme.dart';

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

  // --- شريط العنوان الرئيسي ---
  Widget _buildHeader(ErpProvider erp) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'إعدادات النظام والمنشأة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'تخصيص ثوابت التسعير، بيانات الفواتير، العملات، وإدارة النسخ الاحتياطي',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _confirmResetData(erp),
              icon: const Icon(Icons.restart_alt_rounded, color: Colors.red, size: 18),
              label: const Text('استعادة الافتراضيات', style: TextStyle(color: Colors.red, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _saveSettings(erp),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('حفظ الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 2,
              ),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleSection,
              const SizedBox(height: 12),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleSection),
            actionButtons,
          ],
        );
      },
    );
  }

  // --- كرت إدارة الأسعار والتكاليف والمواد الحية ---
  Widget _buildPricingControlCenterCard(ErpProvider erp) {
    final currency = erp.settings.currency;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
            AppTheme.primaryGreen.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.price_change_rounded, color: Colors.amberAccent, size: 26),
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
                      style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
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
                      iconColor: Colors.amberAccent,
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
                      iconColor: Colors.cyanAccent,
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
                      iconColor: Colors.pinkAccent,
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
                      iconColor: Colors.lightGreenAccent,
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
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 18),
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
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
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
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
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
      iconColor: AppTheme.primaryGreen,
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
      iconColor: const Color(0xFF0284C7),
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

  // --- كرت 4: النسخ الاحتياطي واستعادة البيانات ---
  Widget _buildBackupRestoreCard(ErpProvider erp) {
    return _buildSectionCard(
      title: 'النسخ الاحتياطي واستعادة البيانات (Backup & Restore)',
      subtitle: 'تصدير نسخة كاملة من قاعدة بيانات النظام بصيغة JSON أو استيرادها على أي جهاز آخر بأمان',
      icon: Icons.cloud_sync_rounded,
      iconColor: const Color(0xFF10B981),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'النسخة الاحتياطية تشمل جميع الأسعار، المخزون، سجل الحركات، العملاء، عروض الأسعار، وأوامر الإنتاج.',
                    style: TextStyle(fontSize: 12, color: AppTheme.darkSlate),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => _exportBackupDialog(erp),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('تصدير نسخة احتياطية (JSON)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _importBackupDialog(erp),
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: const Text('استيراد نسخة احتياطية'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.darkSlate,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
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
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.code_rounded, size: 14, color: AppTheme.primaryGreen),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'تطوير: م/محمد رعدان • $developerPhone',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF94A3B8)),
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
              color: const Color(0xFFF1F5F9),
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
          backgroundColor: Color(0xFF0F172A),
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

  void _exportBackupDialog(ErpProvider erp) {
    final backupJson = erp.exportDatabaseBackup();
    final ctrl = TextEditingController(text: backupJson);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.download_done_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('تصدير نسخة احتياطية'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width < 550 ? double.maxFinite : 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تم تجهيز كود النسخة الاحتياطية. يمكنك نسخه وحفظه بأمان:'),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 8,
                readOnly: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
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

  void _importBackupDialog(ErpProvider erp) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.upload_file_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('استيراد نسخة احتياطية'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width < 550 ? double.maxFinite : 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تحذير: استيراد نسخة احتياطية سيقوم باستبدال البيانات الحالية بالبيانات المستوردة.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'الصق كود النسخة الاحتياطية (JSON) هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final success = await erp.importDatabaseBackup(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                if (success) {
                  final s = erp.settings;
                  _companyNameCtrl.text = s.companyName;
                  _companyPhoneCtrl.text = s.companyPhone;
                  _companyAddressCtrl.text = s.companyAddress;
                  _taxNumberCtrl.text = s.taxNumber;
                  _quotationNotesCtrl.text = s.quotationNotes;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم استرجاع وتحديث كافة البيانات بنجاح!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('فشل استيراد النسخة الاحتياطية. يرجى التحقق من صحة الكود.')),
                  );
                }
              }
            },
            child: const Text('استعادة وتطبيق'),
          ),
        ],
      ),
    );
  }

  void _confirmResetData(ErpProvider erp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('استعادة بيانات الإكسل الأصلية'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في إعادة تعيين كافة البيانات إلى بيانات ملف ERP_مطبعة_متكامل.xls الأولية؟\nسيتم استرجاع الورق، الماكينات، والمنتجات الأصلية.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await erp.resetToExcelDefaults();
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
