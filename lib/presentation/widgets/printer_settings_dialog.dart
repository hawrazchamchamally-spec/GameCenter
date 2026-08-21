import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/thermal_printer_service.dart';
import '../../data/models/models.dart';
import '../../data/services/firestore_service.dart';

/// Modal dialog for Bluetooth Thermal Printer Discovery, Pairing, and Receipt Header Customization
class PrinterSettingsDialog extends StatefulWidget {
  const PrinterSettingsDialog({super.key});

  @override
  State<PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<PrinterSettingsDialog> with SingleTickerProviderStateMixin {
  final ThermalPrinterService _printerService = ThermalPrinterService();
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  final TextEditingController _centerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();

  bool _isTesting = false;
  bool _isSavingReceiptSettings = false;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReceiptSettings();
  }

  Future<void> _loadReceiptSettings() async {
    try {
      final settings = await _firestoreService.getReceiptSettings();
      _centerNameController.text = settings.centerName;
      _addressController.text = settings.address;
      _phoneController.text = settings.phoneNumber;
      _footerController.text = settings.footerNote;
      _printerService.updateReceiptSettings(settings);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
  }

  Future<void> _saveReceiptSettings() async {
    setState(() => _isSavingReceiptSettings = true);
    try {
      final newSettings = ReceiptSettingsModel(
        centerName: _centerNameController.text.trim().isNotEmpty
            ? _centerNameController.text.trim()
            : 'مركز الألعاب | GAME LOUNGE',
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        footerNote: _footerController.text.trim(),
      );

      await _firestoreService.saveReceiptSettings(newSettings);
      _printerService.updateReceiptSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.available,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('تم حفظ وتحديث إعدادات ترويسة الفاتورة بنجاح!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.occupied,
            content: Text('خطأ أثناء حفظ الإعدادات: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingReceiptSettings = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _centerNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _printerService,
      builder: (context, _) {
        final isConnected = _printerService.isConnected;
        final connectedPrinter = _printerService.connectedPrinter;
        final paperWidth = _printerService.paperWidthMm;

        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.print, color: AppColors.primaryLight, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إعدادات الطابعة والفواتير الحرارية',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'إدارة الاقتران بالبلوتوث وتخصيص معلومات وترويسة الوصل',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Tabs Bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.cyanAccent,
                  labelColor: AppColors.cyanAccent,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(icon: Icon(Icons.bluetooth, size: 18), text: 'الاتصال بالطابعة'),
                    Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'ترويسة ومعلومات الفاتورة'),
                  ],
                ),

                const SizedBox(height: 12),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: Bluetooth Printer Connection
                      _buildPrinterConnectionTab(isConnected, connectedPrinter, paperWidth),

                      // TAB 2: Receipt Info & Header Customization
                      _buildReceiptSettingsTab(),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Actions Bottom
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إغلاق'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isTesting
                            ? null
                            : () async {
                                setState(() => _isTesting = true);
                                await _printerService.printTestReceipt();
                                setState(() => _isTesting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.available,
                                      content: Text('تم إرسال أمر الطباعة التجريبية بنجاح!'),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('طباعة إيصال تجريبي'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrinterConnectionTab(
    bool isConnected,
    BluetoothPrinterDevice? connectedPrinter,
    int paperWidth,
  ) {
    return ListView(
      children: [
        // Connection Status Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isConnected
                ? AppColors.available.withAlpha(20)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isConnected ? AppColors.available : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: isConnected ? AppColors.available : AppColors.textMuted,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected
                          ? 'متصل بالطابعة: ${connectedPrinter?.name}'
                          : 'لا توجد طابعة متصلة حالياً',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isConnected ? AppColors.available : AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      isConnected
                          ? 'العنوان: ${connectedPrinter?.address} • جاهز للطباعة'
                          : 'يرجى تشغيل بلوتوث الطابعة واختيارها من القائمة',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                TextButton(
                  onPressed: () => _printerService.disconnectPrinter(),
                  child: const Text('قطع الاتصال', style: TextStyle(color: AppColors.occupied)),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Paper Width Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'عرض ورق الطباعة (Paper Width):',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('58 mm'),
                  selected: paperWidth == 58,
                  selectedColor: AppColors.cyanAccent.withAlpha(40),
                  backgroundColor: AppColors.surfaceLight,
                  onSelected: (_) => _printerService.setPaperWidth(58),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('80 mm'),
                  selected: paperWidth == 80,
                  selectedColor: AppColors.cyanAccent.withAlpha(40),
                  backgroundColor: AppColors.surfaceLight,
                  onSelected: (_) => _printerService.setPaperWidth(80),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Available Printers Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'الطابعات المكتشفة القريبة:',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            TextButton.icon(
              onPressed: _printerService.isScanning
                  ? null
                  : () => _printerService.scanPrinters(),
              icon: _printerService.isScanning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: const Text('إعادة البحث'),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Printers List
        ..._printerService.availablePrinters.map((printer) {
          final isCurrentConnected = connectedPrinter?.address == printer.address;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrentConnected
                  ? AppColors.primaryNeon.withAlpha(20)
                  : AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentConnected ? AppColors.primaryNeon : AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.print_outlined, color: AppColors.cyanAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        printer.address,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isCurrentConnected
                      ? null
                      : () async {
                          await _printerService.connectPrinter(printer);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.available,
                                content: Text('تم الاتصال بالطابعة "${printer.name}" بنجاح'),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentConnected
                        ? AppColors.available
                        : AppColors.primaryNeon,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  child: Text(isCurrentConnected ? 'متصل' : 'اتصال'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReceiptSettingsTab() {
    if (_isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryNeon.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryNeon.withAlpha(60)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'المعلومات المحددة هنا تظهر أعلى وأسفل الفاتورة المطبوعة تلقائياً للزبائن وتُحفظ في السحابة.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 1. Center Name
        const Text(
          'اسم الصالة / المركز:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _centerNameController,
          decoration: const InputDecoration(
            hintText: 'مثال: مركز الألعاب | GAME LOUNGE',
            prefixIcon: Icon(Icons.store, color: AppColors.cyanAccent),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),

        const SizedBox(height: 14),

        // 2. Address
        const Text(
          'العنوان / الموقع:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            hintText: 'مثال: بغداد - المنصور - شارع 14 رمضان',
            prefixIcon: Icon(Icons.location_on, color: AppColors.cyanAccent),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),

        const SizedBox(height: 14),

        // 3. Phone Number
        const Text(
          'أرقام الهاتف / التواصل:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            hintText: 'مثال: 07701234567 / 07801234567',
            prefixIcon: Icon(Icons.phone, color: AppColors.cyanAccent),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),

        const SizedBox(height: 14),

        // 4. Footer Note
        const Text(
          'ملاحظة ذيل الفاتورة (Footer Note):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _footerController,
          decoration: const InputDecoration(
            hintText: 'مثال: شكراً لزيارتكم! نتمنى لكم وقتاً ممتعاً',
            prefixIcon: Icon(Icons.message, color: AppColors.cyanAccent),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),

        const SizedBox(height: 20),

        // Save Button
        ElevatedButton.icon(
          onPressed: _isSavingReceiptSettings ? null : _saveReceiptSettings,
          icon: _isSavingReceiptSettings
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save, color: Colors.white),
          label: const Text('حفظ إعدادات الفاتورة في السحابة', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNeon,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}
