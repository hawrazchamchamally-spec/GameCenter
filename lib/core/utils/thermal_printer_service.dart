import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import 'formatters.dart';
import 'session_timer_service.dart';

/// Represents a Bluetooth thermal printer device
class BluetoothPrinterDevice {
  final String name;
  final String address;
  final bool isConnected;

  const BluetoothPrinterDevice({
    required this.name,
    required this.address,
    this.isConnected = false,
  });

  BluetoothPrinterDevice copyWith({bool? isConnected}) {
    return BluetoothPrinterDevice(
      name: name,
      address: address,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Service for generating ESC/POS thermal receipts and managing Bluetooth printer connections
class ThermalPrinterService extends ChangeNotifier {
  static final ThermalPrinterService _instance = ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  BluetoothPrinterDevice? _connectedPrinter;
  bool _isScanning = false;
  int _paperWidthMm = 58; // 58mm or 80mm
  ReceiptSettingsModel _receiptSettings = const ReceiptSettingsModel();

  final List<BluetoothPrinterDevice> _availablePrinters = [
    const BluetoothPrinterDevice(name: 'POS-58 Bluetooth Printer', address: '00:11:22:33:44:55'),
    const BluetoothPrinterDevice(name: 'Thermal-80 Portable Printer', address: 'AA:BB:CC:DD:EE:FF'),
    const BluetoothPrinterDevice(name: 'Xprinter XP-58IIH', address: '12:34:56:78:90:AB'),
  ];

  BluetoothPrinterDevice? get connectedPrinter => _connectedPrinter;
  bool get isConnected => _connectedPrinter?.isConnected ?? false;
  bool get isScanning => _isScanning;
  int get paperWidthMm => _paperWidthMm;
  ReceiptSettingsModel get receiptSettings => _receiptSettings;
  List<BluetoothPrinterDevice> get availablePrinters => _availablePrinters;

  void setPaperWidth(int widthMm) {
    _paperWidthMm = widthMm;
    notifyListeners();
  }

  void updateReceiptSettings(ReceiptSettingsModel settings) {
    _receiptSettings = settings;
    notifyListeners();
  }

  /// Scan for nearby Bluetooth printers
  Future<List<BluetoothPrinterDevice>> scanPrinters() async {
    _isScanning = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _isScanning = false;
    notifyListeners();
    return _availablePrinters;
  }

  /// Connect to a Bluetooth printer
  Future<bool> connectPrinter(BluetoothPrinterDevice printer) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _connectedPrinter = printer.copyWith(isConnected: true);
    notifyListeners();
    return true;
  }

  /// Disconnect current printer
  Future<void> disconnectPrinter() async {
    _connectedPrinter = null;
    notifyListeners();
  }

  /// Generate formatted plain-text receipt for thermal printing
  String generateReceiptText({
    required GameSessionModel session,
    required String staffName,
    DateTime? printTime,
    ReceiptSettingsModel? receiptSettings,
  }) {
    final settings = receiptSettings ?? _receiptSettings;
    final now = printTime ?? DateTime.now();
    final calculation = SessionTimerService.calculateSession(session: session, atTime: now);
    final totalDuration = session.getElapsedDuration();
    final cols = _paperWidthMm == 80 ? 48 : 32;

    final StringBuffer buffer = StringBuffer();

    // Helper functions
    String center(String text) {
      if (text.length >= cols) return text;
      final pad = (cols - text.length) ~/ 2;
      return ' ' * pad + text;
    }

    String divider([String char = '-']) => char * cols;

    String row(String left, String right) {
      final space = cols - left.length - right.length;
      if (space <= 0) return '$left $right';
      return left + (' ' * space) + right;
    }

    // 1. Header
    buffer.writeln(center('*** ${settings.centerName} ***'));
    if (settings.address.isNotEmpty) {
      buffer.writeln(center(settings.address));
    }
    if (settings.phoneNumber.isNotEmpty) {
      buffer.writeln(center('هاتف: ${settings.phoneNumber}'));
    }
    buffer.writeln(divider('='));

    // 2. Receipt metadata
    buffer.writeln(row('فاتورة جلسة رقم:', '#${session.sessionId.substring(0, session.sessionId.length >= 8 ? 8 : session.sessionId.length)}'));
    buffer.writeln(row('التاريخ والوقت:', AppFormatters.formatDateTime(now)));
    buffer.writeln(row('الموظف المسؤول:', staffName));
    buffer.writeln(row('رقم الشاشة:', 'شاشة ${session.screenNumber}'));
    buffer.writeln(row('عدد اللاعبين:', '${session.playerCount} لاعبين'));
    buffer.writeln(divider());

    // 3. Time & Gaming Breakdown
    buffer.writeln(row('وقت البدء:', AppFormatters.formatTimeOnly(session.startTime)));
    buffer.writeln(row('وقت الانتهاء:', AppFormatters.formatTimeOnly(now)));
    buffer.writeln(row('مدة اللعب الإجمالية:', AppFormatters.formatDuration(totalDuration)));
    buffer.writeln(row('تكلفة اللعب:', AppFormatters.formatCurrency(calculation.totalGamingCost)));
    buffer.writeln(divider());

    // 4. Market Orders (if any)
    if (session.orders.isNotEmpty) {
      buffer.writeln(center('-- طلبات الماركيت --'));
      for (final order in session.orders) {
        final itemLine = '${order.productName} (x${order.quantity})';
        final priceLine = AppFormatters.formatCurrency(order.totalPrice);
        buffer.writeln(row(itemLine, priceLine));
      }
      buffer.writeln(divider());
      buffer.writeln(row('إجمالي الماركيت:', AppFormatters.formatCurrency(calculation.totalMarketCost)));
      buffer.writeln(divider('='));
    }

    // 5. Grand Total
    buffer.writeln(row('المبلغ الإجمالي المطلوب:', AppFormatters.formatCurrency(session.totalAmount > 0 ? session.totalAmount : calculation.grandTotal)));
    buffer.writeln(divider('='));

    // 6. Footer
    if (settings.footerNote.isNotEmpty) {
      buffer.writeln(center(settings.footerNote));
    }
    buffer.writeln(center('يرجى الاحتفاظ بالوصل'));
    buffer.writeln('\n\n'); // Feed lines for paper tear

    return buffer.toString();
  }

  /// Execute thermal print job
  Future<bool> printSessionReceipt({
    required GameSessionModel session,
    required String staffName,
    ReceiptSettingsModel? receiptSettings,
  }) async {
    // Generate text
    final receiptText = generateReceiptText(
      session: session,
      staffName: staffName,
      receiptSettings: receiptSettings,
    );
    debugPrint('Thermal Print Job Output:\n$receiptText');

    // Simulate printing latency
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Print a test diagnostic receipt
  Future<bool> printTestReceipt() async {
    final cols = _paperWidthMm == 80 ? 48 : 32;
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('=' * cols);
    buffer.writeln('  TEST RECEIPT - طابعة الفواتير الحرارية  ');
    buffer.writeln('  عرض الورق: ${_paperWidthMm}mm  ');
    buffer.writeln('  حالة الاتصال: متصل بنجاح  ');
    buffer.writeln('=' * cols);
    buffer.writeln('\n\n');

    debugPrint('Test Print:\n$buffer');
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
