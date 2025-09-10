import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart' as mat;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';

/// Professional Excel export service
class ExcelExportService {
  static const String _companyName = 'شركة الصباغ للمواد الغذائية';
  static const String _companyNameEn = 'Al-Sabbagh Food Materials Company';

  /// Export vendors report to Excel
  static Future<String> exportVendorsReport({
    required Map<String, dynamic> reportData,
    required String startDate,
    required String endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير الموردين'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Set RTL direction for Arabic
    sheet.isRTL = true;

    // Company header
    _addCompanyHeader(sheet, 'تقرير الموردين', 'Vendors Report');

    // Date range
    _addDateRange(sheet, startDate, endDate, 4);

    // Summary section
    final vendors = List<dynamic>.from(reportData['data'] ?? []);
    final totalVendors = vendors.length;
    final totalOrders = vendors.fold<int>(
      0,
      (sum, vendor) => sum + ((vendor['orders_count'] ?? 0) as int),
    );
    final totalAmount = vendors.fold<double>(
      0.0,
      (sum, vendor) => sum + ((vendor['total_amount'] ?? 0.0) as double),
    );

    _addSummarySection(sheet, [
      {
        'title': 'إجمالي الموردين',
        'titleEn': 'Total Vendors',
        'value': '$totalVendors مورد',
      },
      {
        'title': 'إجمالي الطلبات',
        'titleEn': 'Total Orders',
        'value': '$totalOrders طلب',
      },
      {
        'title': 'إجمالي المبلغ',
        'titleEn': 'Total Amount',
        'value': '${totalAmount.toStringAsFixed(2)} SYR',
      },
    ], 7);

    // Data table (adjusted row number due to timestamp addition)
    _addVendorsDataTable(sheet, vendors, 11);

    // Auto-fit columns with enhanced settings
    _autoFitColumns(sheet, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']);

    // Save file
    return await _saveExcelFile(
      excel,
      'vendors_report_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Export items report to Excel
  static Future<String> exportItemsReport({
    required Map<String, dynamic> reportData,
    required String startDate,
    required String endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير الأصناف'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Set RTL direction for Arabic
    sheet.isRTL = true;

    // Company header
    _addCompanyHeader(sheet, 'تقرير الأصناف', 'Items Report');

    // Date range
    _addDateRange(sheet, startDate, endDate, 4);

    // Summary section
    final items = List<dynamic>.from(reportData['data'] ?? []);
    final totalItems = items.length;
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + ((item['total_quantity'] ?? 0) as int),
    );
    final totalAmount = items.fold<double>(
      0.0,
      (sum, item) => sum + ((item['total_amount'] ?? 0.0) as double),
    );

    _addSummarySection(sheet, [
      {
        'title': 'إجمالي الأصناف',
        'titleEn': 'Total Items',
        'value': '$totalItems صنف',
      },
      {
        'title': 'إجمالي الكمية',
        'titleEn': 'Total Quantity',
        'value': '$totalQuantity وحدة',
      },
      {
        'title': 'إجمالي المبلغ',
        'titleEn': 'Total Amount',
        'value': '${totalAmount.toStringAsFixed(2)} SYR',
      },
    ], 7);

    // Data table (adjusted row number due to timestamp addition)
    _addItemsDataTable(sheet, items, 11);

    // Auto-fit columns with enhanced settings
    _autoFitColumns(sheet, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']);

    // Save file
    return await _saveExcelFile(
      excel,
      'items_report_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Export expenses report to Excel
  static Future<String> exportExpensesReport({
    required Map<String, dynamic> reportData,
    required String startDate,
    required String endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير المصروفات'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Set RTL direction for Arabic
    sheet.isRTL = true;

    // Company header
    _addCompanyHeader(sheet, 'تقرير المصروفات', 'Expenses Report');

    // Date range
    _addDateRange(sheet, startDate, endDate, 4);

    // Summary section based on backend schema
    final data = Map<String, dynamic>.from(reportData);
    final expenses = List<dynamic>.from(data['data'] ?? []);
    final summary = Map<String, dynamic>.from(data['summary'] ?? {});
    final int totalTransactions = expenses.length;
    final double grandTotal = _toDouble(summary['grandTotal']);
    final String currency = (expenses.isNotEmpty
            ? (expenses.first['currency'] ?? 'SAR')
            : (summary['currency'] ?? 'SAR'))
        .toString();

    _addSummarySection(sheet, [
      {
        'title': 'إجمالي المصروفات',
        'titleEn': 'Total Expenses',
        'value': '$totalTransactions عملية',
      },
      {
        'title': 'إجمالي المبلغ',
        'titleEn': 'Total Amount',
        'value': '${grandTotal.toStringAsFixed(2)} $currency',
      },
      {
        'title': 'متوسط العملية',
        'titleEn': 'Average Expense',
        'value': '${(totalTransactions > 0 ? (grandTotal / totalTransactions) : 0).toStringAsFixed(2)} $currency',
      },
    ], 7);

    // Data table (adjusted row number due to timestamp addition)
    _addExpensesDataTable(sheet, expenses, 11);

    // Auto-fit columns with enhanced settings
    _autoFitColumns(sheet, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']);

    // Save file
    return await _saveExcelFile(
      excel,
      'expenses_report_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // Helpers for safe casting
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  /// Export purchase orders report to Excel
  static Future<String> exportPurchaseOrdersReport({
    required Map<String, dynamic> reportData,
    required String startDate,
    required String endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير أوامر الشراء'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Set RTL direction for Arabic
    sheet.isRTL = true;

    // Company header with wider merge for better layout
    _addEnhancedCompanyHeader(
      sheet,
      'تقرير أوامر الشراء',
      'Purchase Orders Report',
    );

    // Date range
    _addEnhancedDateRange(sheet, startDate, endDate, 4);

    // Summary section with enhanced calculations
    final orders = List<dynamic>.from(reportData['data'] ?? []);
    final totalOrders = orders.length;
    final totalAmount = orders.fold<double>(
      0.0,
      (sum, order) => sum + (_safeDouble(order['totalValue'])),
    );
    final completedOrders =
        orders.where((order) => order['status'] == 'completed').length;
    final pendingOrders = orders.length - completedOrders;
    final totalItems = orders.fold<int>(
      0,
      (sum, order) => sum + (_safeInt(order['itemCount'])),
    );

    _addEnhancedSummarySection(sheet, [
      {
        'title': 'إجمالي الطلبات',
        'titleEn': 'Total Orders',
        'value': '$totalOrders طلب',
        'icon': '📋',
      },
      {
        'title': 'الطلبات المكتملة',
        'titleEn': 'Completed Orders',
        'value': '$completedOrders طلب',
        'icon': '✅',
      },
      {
        'title': 'الطلبات المعلقة',
        'titleEn': 'Pending Orders',
        'value': '$pendingOrders طلب',
        'icon': '⏳',
      },
      {
        'title': 'إجمالي العناصر',
        'titleEn': 'Total Items',
        'value': '$totalItems عنصر',
        'icon': '📦',
      },
      {
        'title': 'إجمالي المبلغ',
        'titleEn': 'Total Amount',
        'value':
            '${totalAmount.toStringAsFixed(2)} ${orders.isNotEmpty ? (_safeString(orders[0]['currency'], 'SYR')) : 'SYR'}',
        'icon': '💰',
      },
    ], 7);

    // Enhanced data table with better spacing
    _addEnhancedPurchaseOrdersDataTable(sheet, orders, 13);

    // Auto-fit columns with enhanced settings for wider layout
    _autoFitColumns(sheet, [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
    ]);

    // Save file
    return await _saveExcelFile(
      excel,
      'purchase_orders_report_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Add company header with professional styling
  static void _addCompanyHeader(Sheet sheet, String titleAr, String titleEn) {
    // Company name in Arabic with enhanced styling
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      _companyName,
    );
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      fontSize: 18,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#1F4E79'),
      backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('J1'));

    // Company name in English with enhanced styling
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      _companyNameEn,
    );
    sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
      fontSize: 14,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#1F4E79'),
      backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('J2'));

    // Report title in Arabic with enhanced styling
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(titleAr);
    sheet.cell(CellIndex.indexByString('A3')).cellStyle = CellStyle(
      fontSize: 16,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#0D7377'),
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E8'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('J3'));
  }

  /// Add enhanced company header with wider layout for purchase orders
  static void _addEnhancedCompanyHeader(
    Sheet sheet,
    String titleAr,
    String titleEn,
  ) {
    // Company name in Arabic with enhanced styling and wider merge
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      '🏢 $_companyName',
    );
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      fontSize: 20,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#1F4E79'),
      backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('R1'));

    // Company name in English with enhanced styling and wider merge
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      '🏢 $_companyNameEn',
    );
    sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
      fontSize: 16,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#1F4E79'),
      backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('R2'));

    // Report title in Arabic with enhanced styling and wider merge
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      '📋 $titleAr',
    );
    sheet.cell(CellIndex.indexByString('A3')).cellStyle = CellStyle(
      fontSize: 18,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#0D7377'),
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E8'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('R3'));
  }

  /// Add date range with enhanced styling
  static void _addDateRange(
    Sheet sheet,
    String startDate,
    String endDate,
    int row,
  ) {
    // Add date range with proper handling of empty dates
    final displayStartDate = startDate.isEmpty ? 'غير محدد' : startDate;
    final displayEndDate = endDate.isEmpty ? 'غير محدد' : endDate;
    final dateRange =
        'الفترة الزمنية: من $displayStartDate إلى $displayEndDate';

    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(
      dateRange,
    );
    sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(
      fontSize: 12,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#666666'),
      backgroundColorHex: ExcelColor.fromHexString('#E7F3FF'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$row'),
      CellIndex.indexByString('J$row'),
    );

    // Add generation timestamp
    final nextRow = row + 1;
    final timestamp =
        'تاريخ إنشاء التقرير: ${DateTime.now().toString().substring(0, 19)}';
    sheet.cell(CellIndex.indexByString('A$nextRow')).value = TextCellValue(
      timestamp,
    );
    sheet.cell(CellIndex.indexByString('A$nextRow')).cellStyle = CellStyle(
      fontSize: 10,
      italic: true,
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#888888'),
      backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$nextRow'),
      CellIndex.indexByString('J$nextRow'),
    );
  }

  /// Add enhanced date range with wider layout for purchase orders
  static void _addEnhancedDateRange(
    Sheet sheet,
    String startDate,
    String endDate,
    int row,
  ) {
    // Add date range with proper handling of empty dates and enhanced styling
    final displayStartDate = startDate.isEmpty ? 'غير محدد' : startDate;
    final displayEndDate = endDate.isEmpty ? 'غير محدد' : endDate;
    final dateRange =
        '📅 الفترة الزمنية: من $displayStartDate إلى $displayEndDate';

    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(
      dateRange,
    );
    sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(
      fontSize: 14,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#495057'),
      backgroundColorHex: ExcelColor.fromHexString('#E7F3FF'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$row'),
      CellIndex.indexByString('R$row'),
    );

    // Add generation timestamp with enhanced styling
    final nextRow = row + 1;
    final now = DateTime.now();
    final timestamp =
        '🕒 تاريخ إنشاء التقرير: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    sheet.cell(CellIndex.indexByString('A$nextRow')).value = TextCellValue(
      timestamp,
    );
    sheet.cell(CellIndex.indexByString('A$nextRow')).cellStyle = CellStyle(
      fontSize: 11,
      italic: true,
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#6C757D'),
      backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
      topBorder: Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$nextRow'),
      CellIndex.indexByString('R$nextRow'),
    );
  }

  /// Add summary section with enhanced styling
  static void _addSummarySection(
    Sheet sheet,
    List<Map<String, String>> summaryData,
    int startRow,
  ) {
    // Add summary header with professional styling
    sheet.cell(CellIndex.indexByString('A$startRow')).value = TextCellValue(
      '📊 ملخص التقرير',
    );
    sheet.cell(CellIndex.indexByString('A$startRow')).cellStyle = CellStyle(
      fontSize: 14,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#0D7377'),
      fontColorHex: ExcelColor.white,
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$startRow'),
      CellIndex.indexByString('J$startRow'),
    );

    int currentRow = startRow + 1;
    for (int i = 0; i < summaryData.length; i++) {
      final item = summaryData[i];
      final isEvenRow = i % 2 == 0;

      // Arabic title
      sheet.cell(CellIndex.indexByString('A$currentRow')).value = TextCellValue(
        item['title']!,
      );
      sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(
        fontSize: 12,
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex:
            isEvenRow
                ? ExcelColor.fromHexString('#F8F9FA')
                : ExcelColor.fromHexString('#E8F5E8'),
        fontColorHex: ExcelColor.fromHexString('#1F4E79'),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('A$currentRow'),
        CellIndex.indexByString('D$currentRow'),
      );

      // English title
      sheet.cell(CellIndex.indexByString('E$currentRow')).value = TextCellValue(
        item['titleEn']!,
      );
      sheet.cell(CellIndex.indexByString('E$currentRow')).cellStyle = CellStyle(
        fontSize: 11,
        italic: true,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex:
            isEvenRow
                ? ExcelColor.fromHexString('#F8F9FA')
                : ExcelColor.fromHexString('#E8F5E8'),
        fontColorHex: ExcelColor.fromHexString('#666666'),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('E$currentRow'),
        CellIndex.indexByString('H$currentRow'),
      );

      // Value with emphasis
      sheet.cell(CellIndex.indexByString('I$currentRow')).value = TextCellValue(
        item['value']!,
      );
      sheet.cell(CellIndex.indexByString('I$currentRow')).cellStyle = CellStyle(
        fontSize: 13,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#E8F5E8'),
        fontColorHex: ExcelColor.fromHexString('#0D7377'),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('I$currentRow'),
        CellIndex.indexByString('J$currentRow'),
      );

      currentRow++;
    }

    // Add bottom border to summary section
    final lastSummaryRow = currentRow - 1;
    for (String col in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J']) {
      final cell = sheet.cell(CellIndex.indexByString('$col$lastSummaryRow'));
      final currentStyle = cell.cellStyle ?? CellStyle();
      cell.cellStyle = currentStyle.copyWith(
        bottomBorderVal: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
      );
    }
  }

  /// Add enhanced summary section with icons and better layout for purchase orders
  static void _addEnhancedSummarySection(
    Sheet sheet,
    List<Map<String, String>> summaryData,
    int startRow,
  ) {
    // Add summary header with professional styling and wider merge
    sheet.cell(CellIndex.indexByString('A$startRow')).value = TextCellValue(
      '📊 ملخص التقرير - Report Summary',
    );
    sheet.cell(CellIndex.indexByString('A$startRow')).cellStyle = CellStyle(
      fontSize: 16,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#0D7377'),
      fontColorHex: ExcelColor.white,
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#0D7377'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$startRow'),
      CellIndex.indexByString('R$startRow'),
    );

    int currentRow = startRow + 1;

    // Create a grid layout for better organization (3 columns)
    final itemsPerRow = 3;
    for (int i = 0; i < summaryData.length; i++) {
      final item = summaryData[i];
      final rowIndex = i ~/ itemsPerRow;
      final colIndex = i % itemsPerRow;
      final actualRow = currentRow + rowIndex;

      // Calculate column positions (each item takes 6 columns)
      final startCol = 1 + (colIndex * 6); // A=1, G=7, M=13
      final endCol = startCol + 5; // F=6, L=12, R=18

      final startColLetter = String.fromCharCode(64 + startCol);
      final endColLetter = String.fromCharCode(64 + endCol);

      // Create card-like appearance for each summary item
      final cardContent = '${item['icon']} ${item['title']}\n${item['value']}';

      sheet
          .cell(CellIndex.indexByString('$startColLetter$actualRow'))
          .value = TextCellValue(cardContent);
      sheet
          .cell(CellIndex.indexByString('$startColLetter$actualRow'))
          .cellStyle = CellStyle(
        fontSize: 12,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: _getSummaryCardColor(i),
        fontColorHex: ExcelColor.white,
        topBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('$startColLetter$actualRow'),
        CellIndex.indexByString('$endColLetter$actualRow'),
      );
    }

    // Calculate the number of rows used
    final totalRows = (summaryData.length / itemsPerRow).ceil();

    // Add spacing after summary
    final spacingRow = currentRow + totalRows;
    sheet.cell(CellIndex.indexByString('A$spacingRow')).value = TextCellValue(
      '',
    );
    sheet.cell(CellIndex.indexByString('A$spacingRow')).cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
    );
    sheet.merge(
      CellIndex.indexByString('A$spacingRow'),
      CellIndex.indexByString('R$spacingRow'),
    );
  }

  /// Get summary card color based on index
  static ExcelColor _getSummaryCardColor(int index) {
    final colors = [
      '#1F4E79', // Blue
      '#28A745', // Green
      '#FFC107', // Yellow
      '#17A2B8', // Cyan
      '#DC3545', // Red
    ];
    return ExcelColor.fromHexString(colors[index % colors.length]);
  }

  /// Add vendors data table with enhanced styling
  static void _addVendorsDataTable(
    Sheet sheet,
    List<dynamic> vendors,
    int startRow,
  ) {
    // Add table header with spacing
    final tableHeaderRow = startRow;
    sheet
        .cell(CellIndex.indexByString('A$tableHeaderRow'))
        .value = TextCellValue('📋 بيانات الموردين التفصيلية');
    sheet
        .cell(CellIndex.indexByString('A$tableHeaderRow'))
        .cellStyle = CellStyle(
      fontSize: 13,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1F4E79'),
      fontColorHex: ExcelColor.white,
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$tableHeaderRow'),
      CellIndex.indexByString('J$tableHeaderRow'),
    );

    // Column headers with enhanced styling
    final headerRow = startRow + 1;
    final headers = [
      'اسم المورد',
      'الشخص المسؤول',
      'رقم الهاتف',
      'عدد الطلبات',
      'إجمالي المبلغ (SYR)',
    ];

    for (int i = 0; i < headers.length; i++) {
      final colStart = String.fromCharCode(65 + (i * 2));
      final colEnd = String.fromCharCode(65 + (i * 2) + 1);
      final cellRef = '$colStart$headerRow';

      sheet.cell(CellIndex.indexByString(cellRef)).value = TextCellValue(
        headers[i],
      );
      sheet.cell(CellIndex.indexByString(cellRef)).cellStyle = CellStyle(
        fontSize: 12,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#0D7377'),
        fontColorHex: ExcelColor.white,
        topBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#0D7377'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('$colStart$headerRow'),
        CellIndex.indexByString('$colEnd$headerRow'),
      );
    }

    // Data rows with enhanced styling and null handling
    for (int i = 0; i < vendors.length; i++) {
      final vendor = vendors[i];
      final rowIndex = headerRow + 1 + i;
      final isEvenRow = i % 2 == 0;
      final backgroundColor =
          isEvenRow ? ExcelColor.fromHexString('#F8F9FA') : ExcelColor.white;

      final rowData = [
        vendor['name']?.toString().isEmpty == true
            ? 'غير محدد'
            : (vendor['name'] ?? 'غير محدد'),
        vendor['contact_person']?.toString().isEmpty == true
            ? 'غير محدد'
            : (vendor['contact_person'] ?? 'غير محدد'),
        vendor['phone']?.toString().isEmpty == true
            ? 'غير محدد'
            : (vendor['phone'] ?? 'غير محدد'),
        (vendor['orders_count'] ?? 0).toString(),
        '${(vendor['total_amount'] ?? 0.0).toStringAsFixed(2)}',
      ];

      for (int j = 0; j < rowData.length; j++) {
        final colStart = String.fromCharCode(65 + (j * 2));
        final colEnd = String.fromCharCode(65 + (j * 2) + 1);
        final cellRef = '$colStart$rowIndex';

        sheet.cell(CellIndex.indexByString(cellRef)).value = TextCellValue(
          rowData[j],
        );
        sheet.cell(CellIndex.indexByString(cellRef)).cellStyle = CellStyle(
          fontSize: 11,
          bold: j == 4, // Bold for amount column
          horizontalAlign:
              j == 4 ? HorizontalAlign.Center : HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: backgroundColor,
          fontColorHex:
              j == 4
                  ? ExcelColor.fromHexString('#0D7377')
                  : ExcelColor.fromHexString('#333333'),
          topBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          bottomBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          leftBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          rightBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
        );
        sheet.merge(
          CellIndex.indexByString('$colStart$rowIndex'),
          CellIndex.indexByString('$colEnd$rowIndex'),
        );
      }
    }

    // Add bottom border to table
    if (vendors.isNotEmpty) {
      final lastDataRow = headerRow + vendors.length;
      for (int j = 0; j < 10; j++) {
        final col = String.fromCharCode(65 + j);
        final cell = sheet.cell(CellIndex.indexByString('$col$lastDataRow'));
        final currentStyle = cell.cellStyle ?? CellStyle();
        cell.cellStyle = currentStyle.copyWith(
          bottomBorderVal: Border(
            borderStyle: BorderStyle.Thick,
            borderColorHex: ExcelColor.fromHexString('#0D7377'),
          ),
        );
      }
    }
  }

  /// Add items data table with enhanced styling
  static void _addItemsDataTable(
    Sheet sheet,
    List<dynamic> items,
    int startRow,
  ) {
    // Add table header with spacing
    final tableHeaderRow = startRow;
    sheet
        .cell(CellIndex.indexByString('A$tableHeaderRow'))
        .value = TextCellValue('📦 بيانات الأصناف التفصيلية');
    sheet
        .cell(CellIndex.indexByString('A$tableHeaderRow'))
        .cellStyle = CellStyle(
      fontSize: 13,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1F4E79'),
      fontColorHex: ExcelColor.white,
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$tableHeaderRow'),
      CellIndex.indexByString('J$tableHeaderRow'),
    );

    // Column headers with enhanced styling
    final headerRow = startRow + 1;
    final headers = [
      'اسم الصنف',
      'الفئة',
      'الكمية الإجمالية',
      'إجمالي المبلغ (SYR)',
    ];

    for (int i = 0; i < headers.length; i++) {
      final colStart = String.fromCharCode(65 + (i * 2));
      final colEnd = String.fromCharCode(65 + (i * 2) + 1);
      final cellRef = '$colStart$headerRow';

      sheet.cell(CellIndex.indexByString(cellRef)).value = TextCellValue(
        headers[i],
      );
      sheet.cell(CellIndex.indexByString(cellRef)).cellStyle = CellStyle(
        fontSize: 12,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#2E86AB'),
        fontColorHex: ExcelColor.white,
        topBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#2E86AB'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#2E86AB'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#2E86AB'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#2E86AB'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('$colStart$headerRow'),
        CellIndex.indexByString('$colEnd$headerRow'),
      );
    }

    // Add remaining columns for better spacing
    for (int i = 8; i < 10; i++) {
      final col = String.fromCharCode(65 + i);
      sheet
          .cell(CellIndex.indexByString('$col$headerRow'))
          .cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#2E86AB'),
        topBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#2E86AB'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#2E86AB'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#2E86AB'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#2E86AB'),
        ),
      );
    }

    // Data rows with enhanced styling and null handling
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final rowIndex = headerRow + 1 + i;
      final isEvenRow = i % 2 == 0;
      final backgroundColor =
          isEvenRow ? ExcelColor.fromHexString('#F0F8FF') : ExcelColor.white;

      final rowData = [
        item['name']?.toString().isEmpty == true
            ? 'غير محدد'
            : (item['name'] ?? 'غير محدد'),
        item['category']?.toString().isEmpty == true
            ? 'غير محدد'
            : (item['category'] ?? 'غير محدد'),
        (item['total_quantity'] ?? 0).toString(),
        '${(item['total_amount'] ?? 0.0).toStringAsFixed(2)}',
      ];

      for (int j = 0; j < rowData.length; j++) {
        final colStart = String.fromCharCode(65 + (j * 2));
        final colEnd = String.fromCharCode(65 + (j * 2) + 1);
        final cellRef = '$colStart$rowIndex';

        sheet.cell(CellIndex.indexByString(cellRef)).value = TextCellValue(
          rowData[j],
        );
        sheet.cell(CellIndex.indexByString(cellRef)).cellStyle = CellStyle(
          fontSize: 11,
          bold: j >= 2, // Bold for quantity and amount columns
          horizontalAlign:
              j >= 2 ? HorizontalAlign.Center : HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: backgroundColor,
          fontColorHex:
              j == 3
                  ? ExcelColor.fromHexString('#2E86AB')
                  : ExcelColor.fromHexString('#333333'),
          topBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          bottomBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          leftBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          rightBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
        );
        sheet.merge(
          CellIndex.indexByString('$colStart$rowIndex'),
          CellIndex.indexByString('$colEnd$rowIndex'),
        );
      }

      // Style remaining columns for consistency
      for (int j = 8; j < 10; j++) {
        final col = String.fromCharCode(65 + j);
        sheet
            .cell(CellIndex.indexByString('$col$rowIndex'))
            .cellStyle = CellStyle(
          backgroundColorHex: backgroundColor,
          topBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          bottomBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          leftBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          rightBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
        );
      }
    }

    // Add bottom border to table
    if (items.isNotEmpty) {
      final lastDataRow = headerRow + items.length;
      for (int j = 0; j < 10; j++) {
        final col = String.fromCharCode(65 + j);
        final cell = sheet.cell(CellIndex.indexByString('$col$lastDataRow'));
        final currentStyle = cell.cellStyle ?? CellStyle();
        cell.cellStyle = currentStyle.copyWith(
          bottomBorderVal: Border(
            borderStyle: BorderStyle.Thick,
            borderColorHex: ExcelColor.fromHexString('#2E86AB'),
          ),
        );
      }
    }
  }

  /// Add expenses data table with enhanced styling
  static void _addExpensesDataTable(
    Sheet sheet,
    List<dynamic> expenses,
    int startRow,
  ) {
    // Add table header with spacing
    final tableHeaderRow = startRow;
    sheet
        .cell(CellIndex.indexByString('A$tableHeaderRow'))
        .value = TextCellValue('💰 بيانات المصروفات التفصيلية');
    sheet
        .cell(CellIndex.indexByString('A$tableHeaderRow'))
        .cellStyle = CellStyle(
      fontSize: 13,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1F4E79'),
      fontColorHex: ExcelColor.white,
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$tableHeaderRow'),
      CellIndex.indexByString('J$tableHeaderRow'),
    );

    // Column headers with enhanced styling
    final headerRow = startRow + 1;
    final headers = ['Order ID', 'Supplier', 'Amount', 'Request Date'];

    for (int i = 0; i < headers.length; i++) {
      final colStart = String.fromCharCode(65 + (i * 2));
      final colEnd = String.fromCharCode(65 + (i * 2) + 1);
      final cellRef = '$colStart$headerRow';

      sheet.cell(CellIndex.indexByString(cellRef)).value = TextCellValue(
        headers[i],
      );
      sheet.cell(CellIndex.indexByString(cellRef)).cellStyle = CellStyle(
        fontSize: 12,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#DC3545'),
        fontColorHex: ExcelColor.white,
        topBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#DC3545'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#DC3545'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#DC3545'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#DC3545'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('$colStart$headerRow'),
        CellIndex.indexByString('$colEnd$headerRow'),
      );
    }

    // Add remaining columns for better spacing
    for (int i = 8; i < 10; i++) {
      final col = String.fromCharCode(65 + i);
      sheet
          .cell(CellIndex.indexByString('$col$headerRow'))
          .cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#DC3545'),
        topBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#DC3545'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#DC3545'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#DC3545'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#DC3545'),
        ),
      );
    }

    // Data rows with enhanced styling and null handling
    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      final rowIndex = headerRow + 1 + i;
      final isEvenRow = i % 2 == 0;
      final backgroundColor =
          isEvenRow ? ExcelColor.fromHexString('#FFF5F5') : ExcelColor.white;

      final String id = (expense['id'] ?? '').toString();
      final String supplierName = (expense['supplierName'] ?? 'N/A').toString();
      final String requestDate = (expense['requestDate'] ?? 'N/A').toString();
      final String currency = (expense['currency'] ?? 'SAR').toString();
      final double amount = _toDouble(expense['totalExpense']);

      final rowData = [
        id.isEmpty ? 'N/A' : id,
        supplierName.isEmpty ? 'N/A' : supplierName,
        '${amount.toStringAsFixed(2)} $currency',
        requestDate.isEmpty ? 'N/A' : requestDate,
      ];

      for (int j = 0; j < rowData.length; j++) {
        final colStart = String.fromCharCode(65 + (j * 2));
        final colEnd = String.fromCharCode(65 + (j * 2) + 1);
        final cellRef = '$colStart$rowIndex';

        sheet.cell(CellIndex.indexByString(cellRef)).value = TextCellValue(
          rowData[j],
        );
        sheet.cell(CellIndex.indexByString(cellRef)).cellStyle = CellStyle(
          fontSize: 11,
          bold: j == 2, // Bold for amount column
          horizontalAlign:
              j == 2 ? HorizontalAlign.Center : HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: backgroundColor,
          fontColorHex:
              j == 2
                  ? ExcelColor.fromHexString('#DC3545')
                  : ExcelColor.fromHexString('#333333'),
          topBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          bottomBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          leftBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          rightBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
        );
        sheet.merge(
          CellIndex.indexByString('$colStart$rowIndex'),
          CellIndex.indexByString('$colEnd$rowIndex'),
        );
      }

      // Style remaining columns for consistency
      for (int j = 8; j < 10; j++) {
        final col = String.fromCharCode(65 + j);
        sheet
            .cell(CellIndex.indexByString('$col$rowIndex'))
            .cellStyle = CellStyle(
          backgroundColorHex: backgroundColor,
          topBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          bottomBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          leftBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          rightBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
        );
      }
    }

    // Add bottom border to table
    if (expenses.isNotEmpty) {
      final lastDataRow = headerRow + expenses.length;
      for (int j = 0; j < 10; j++) {
        final col = String.fromCharCode(65 + j);
        final cell = sheet.cell(CellIndex.indexByString('$col$lastDataRow'));
        final currentStyle = cell.cellStyle ?? CellStyle();
        cell.cellStyle = currentStyle.copyWith(
          bottomBorderVal: Border(
            borderStyle: BorderStyle.Thick,
            borderColorHex: ExcelColor.fromHexString('#DC3545'),
          ),
        );
      }
    }
  }

  /// Add purchase orders data table with enhanced styling and detailed items
  /// Enhanced purchase orders data table with professional design
  static void _addEnhancedPurchaseOrdersDataTable(
    Sheet sheet,
    List<dynamic> orders,
    int startRow,
  ) {
    if (orders.isEmpty) {
      _addEnhancedEmptyDataMessage(
        sheet,
        startRow,
        'لا توجد طلبات شراء في هذه الفترة',
      );
      return;
    }

    // Add main table header with enhanced styling and wider merge
    final tableHeaderRow = startRow;
    sheet
        .cell(CellIndex.indexByString('A$tableHeaderRow'))
        .value = TextCellValue(
      '🛒 تقرير أوامر الشراء التفصيلي - Detailed Purchase Orders Report',
    );
    sheet
        .cell(CellIndex.indexByString('A$tableHeaderRow'))
        .cellStyle = CellStyle(
      fontSize: 18,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1F4E79'),
      fontColorHex: ExcelColor.white,
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$tableHeaderRow'),
      CellIndex.indexByString('R$tableHeaderRow'),
    );

    int currentRow = startRow + 2;

    // Process each purchase order with enhanced design
    for (int orderIndex = 0; orderIndex < orders.length; orderIndex++) {
      final order = orders[orderIndex];
      final items = List<dynamic>.from(order['items'] ?? []);

      // Add elegant separator between orders (except for first order)
      if (orderIndex > 0) {
        currentRow += 1;
        _addElegantOrderSeparator(sheet, currentRow);
        currentRow += 2;
      }

      // Add enhanced purchase order header
      currentRow = _addEnhancedPurchaseOrderHeader(
        sheet,
        order,
        currentRow,
        orderIndex + 1,
      );

      // Add enhanced items table if items exist
      if (items.isNotEmpty) {
        currentRow = _addEnhancedItemsTable(sheet, items, currentRow, order);
      } else {
        currentRow = _addEnhancedNoItemsMessage(sheet, currentRow);
      }

      currentRow += 2; // More space after each order for better separation
    }

    // Add enhanced summary footer
    _addEnhancedOrdersSummaryFooter(sheet, orders, currentRow + 1);
  }

  /// Enhanced empty data message spanning full width (A..R)
  static void _addEnhancedEmptyDataMessage(
    Sheet sheet,
    int startRow,
    String message,
  ) {
    sheet.cell(CellIndex.indexByString('A$startRow')).value = TextCellValue(
      '📭 $message',
    );
    sheet.cell(CellIndex.indexByString('A$startRow')).cellStyle = CellStyle(
      fontSize: 14,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#F8D7DA'),
      fontColorHex: ExcelColor.fromHexString('#721C24'),
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#DC3545'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#DC3545'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#DC3545'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#DC3545'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$startRow'),
      CellIndex.indexByString('R$startRow'),
    );
  }

  /// Elegant visual separator between orders (A..R)
  static void _addElegantOrderSeparator(Sheet sheet, int row) {
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('');
    sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E9ECEF'),
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#6C757D'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#6C757D'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$row'),
      CellIndex.indexByString('R$row'),
    );
  }

  /// Enhanced purchase order header with wide layout and better spacing
  static int _addEnhancedPurchaseOrderHeader(
    Sheet sheet,
    Map<String, dynamic> order,
    int startRow,
    int orderNumber,
  ) {
    // Header bar
    final headerRow = startRow;
    sheet.cell(CellIndex.indexByString('A$headerRow')).value = TextCellValue(
      '📋 طلب شراء رقم $orderNumber',
    );
    sheet.cell(CellIndex.indexByString('A$headerRow')).cellStyle = CellStyle(
      fontSize: 14,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#28A745'),
      fontColorHex: ExcelColor.white,
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$headerRow'),
      CellIndex.indexByString('R$headerRow'),
    );

    // Details grid (4 columns x 2 rows) => 8 fields
    final detailsRow = startRow + 1;
    final details = [
      ['رقم الطلب:', _safeString(order['number'])],
      ['تاريخ الطلب:', _formatDate(order['requestDate'])],
      ['القسم:', _safeString(order['department'])],
      ['الحالة:', _getStatusInArabic(_safeString(order['status'], ''))],
      ['المورد:', _safeString(order['supplierName'], 'غير محدد')],
      ['مقدم الطلب:', _safeString(order['requesterName'])],
      [
        'إجمالي المبلغ:',
        '${_safeDouble(order['totalValue']).toStringAsFixed(2)} ${_safeString(order['currency'], 'SYR')}',
      ],
      ['عدد العناصر:', '${_safeInt(order['itemCount'])} عنصر'],
    ];

    // Use 18 columns (A..R). Each label/value pair gets 4 columns (2+2)
    for (int i = 0; i < details.length; i++) {
      final row = detailsRow + (i ~/ 4);
      final block = i % 4; // 0..3
      final startIndex = 1 + (block * 4); // A=1
      final labelStart = String.fromCharCode(64 + startIndex);
      final labelEnd = String.fromCharCode(64 + startIndex + 1);
      final valueStart = String.fromCharCode(64 + startIndex + 2);
      final valueEnd = String.fromCharCode(64 + startIndex + 3);

      // Label
      sheet
          .cell(CellIndex.indexByString('$labelStart$row'))
          .value = TextCellValue(details[i][0]);
      sheet
          .cell(CellIndex.indexByString('$labelStart$row'))
          .cellStyle = CellStyle(
        fontSize: 11,
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#E8F5E8'),
        fontColorHex: ExcelColor.fromHexString('#2D5A2D'),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('$labelStart$row'),
        CellIndex.indexByString('$labelEnd$row'),
      );

      // Value
      final valueText = details[i][1];
      final statusIdx = 3; // index of الحالة
      sheet
          .cell(CellIndex.indexByString('$valueStart$row'))
          .value = TextCellValue(valueText);
      sheet
          .cell(CellIndex.indexByString('$valueStart$row'))
          .cellStyle = CellStyle(
        fontSize: 11,
        bold: i == 6, // total amount emphasized
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.white,
        fontColorHex:
            (i == statusIdx)
                ? _getStatusColor(_safeString(order['status'], ''))
                : (i == 6
                    ? ExcelColor.fromHexString('#28A745')
                    : ExcelColor.fromHexString('#333333')),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('$valueStart$row'),
        CellIndex.indexByString('$valueEnd$row'),
      );
    }

    return detailsRow + 2; // next row after grid
  }

  /// Enhanced items table with subtotal and better colors
  static int _addEnhancedItemsTable(
    Sheet sheet,
    List<dynamic> items,
    int startRow,
    Map<String, dynamic> order,
  ) {
    // Section header (A..R)
    final itemsHeaderRow = startRow;
    sheet
        .cell(CellIndex.indexByString('A$itemsHeaderRow'))
        .value = TextCellValue('📦 عناصر الطلب');
    sheet
        .cell(CellIndex.indexByString('A$itemsHeaderRow'))
        .cellStyle = CellStyle(
      fontSize: 12,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#FFC107'),
      fontColorHex: ExcelColor.fromHexString('#333333'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$itemsHeaderRow'),
      CellIndex.indexByString('R$itemsHeaderRow'),
    );

    // Table headers (use A..N pair-merged to avoid overlap and keep readable widths)
    final headerRow = startRow + 1;
    final headers = [
      'كود العنصر',
      'اسم العنصر',
      'الكمية',
      'الوحدة',
      'السعر',
      'العملة',
      'الإجمالي',
    ];
    for (int i = 0; i < headers.length; i++) {
      final colStart = String.fromCharCode(65 + (i * 2));
      final colEnd = String.fromCharCode(65 + (i * 2) + 1);
      sheet
          .cell(CellIndex.indexByString('$colStart$headerRow'))
          .value = TextCellValue(headers[i]);
      sheet
          .cell(CellIndex.indexByString('$colStart$headerRow'))
          .cellStyle = CellStyle(
        fontSize: 11,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#17A2B8'),
        fontColorHex: ExcelColor.white,
        topBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('$colStart$headerRow'),
        CellIndex.indexByString('$colEnd$headerRow'),
      );
    }

    // Data rows
    int currentRow = headerRow + 1;
    double subtotal = 0.0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isEven = i % 2 == 0;
      final bg =
          isEven ? ExcelColor.fromHexString('#F8F9FA') : ExcelColor.white;

      final quantity = _safeDouble(item['quantity']);
      final price = _safeDouble(item['price']);
      final lineTotal = (quantity * price);
      subtotal += lineTotal;

      final rowData = [
        _safeString(item['item_code'], 'غير محدد'),
        _safeString(item['item_name'], 'غير محدد'),
        quantity.toString(),
        _safeString(item['unit'], 'قطعة'),
        price.toStringAsFixed(2),
        _safeString(item['currency'], _safeString(order['currency'], 'SYR')),
        lineTotal.toStringAsFixed(2),
      ];

      for (int j = 0; j < rowData.length; j++) {
        final colStart = String.fromCharCode(65 + (j * 2));
        final colEnd = String.fromCharCode(65 + (j * 2) + 1);
        sheet
            .cell(CellIndex.indexByString('$colStart$currentRow'))
            .value = TextCellValue(rowData[j]);
        sheet
            .cell(CellIndex.indexByString('$colStart$currentRow'))
            .cellStyle = CellStyle(
          fontSize: 10,
          bold: j == 6,
          horizontalAlign:
              (j >= 2 && j <= 6)
                  ? HorizontalAlign.Center
                  : HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: bg,
          fontColorHex:
              (j == 4 || j == 6)
                  ? ExcelColor.fromHexString('#28A745')
                  : ExcelColor.fromHexString('#333333'),
          topBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          bottomBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          leftBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          rightBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
        );
        sheet.merge(
          CellIndex.indexByString('$colStart$currentRow'),
          CellIndex.indexByString('$colEnd$currentRow'),
        );
      }
      currentRow++;
    }

    // Subtotal row
    sheet.cell(CellIndex.indexByString('A$currentRow')).value = TextCellValue(
      'الإجمالي الفرعي',
    );
    sheet.cell(CellIndex.indexByString('A$currentRow')).cellStyle = CellStyle(
      fontSize: 11,
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E2F0D9'),
      fontColorHex: ExcelColor.fromHexString('#2D5A2D'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$currentRow'),
      CellIndex.indexByString('J$currentRow'),
    );

    sheet.cell(CellIndex.indexByString('K$currentRow')).value = TextCellValue(
      subtotal.toStringAsFixed(2),
    );
    sheet.cell(CellIndex.indexByString('K$currentRow')).cellStyle = CellStyle(
      fontSize: 12,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E2F0D9'),
      fontColorHex: ExcelColor.fromHexString('#28A745'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('K$currentRow'),
      CellIndex.indexByString('N$currentRow'),
    );

    // Bottom border across table width
    for (int j = 0; j < 14; j++) {
      final col = String.fromCharCode(65 + j);
      final cell = sheet.cell(CellIndex.indexByString('$col$currentRow'));
      final cur = cell.cellStyle ?? CellStyle();
      cell.cellStyle = cur.copyWith(
        bottomBorderVal: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
      );
    }

    return currentRow + 1;
  }

  /// Enhanced message when no items in order
  static int _addEnhancedNoItemsMessage(Sheet sheet, int startRow) {
    sheet.cell(CellIndex.indexByString('A$startRow')).value = TextCellValue(
      '⚠️ لا توجد عناصر في هذا الطلب',
    );
    sheet.cell(CellIndex.indexByString('A$startRow')).cellStyle = CellStyle(
      fontSize: 11,
      italic: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#FFF3CD'),
      fontColorHex: ExcelColor.fromHexString('#856404'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$startRow'),
      CellIndex.indexByString('R$startRow'),
    );
    return startRow + 1;
  }

  /// Footer summarizing all orders
  static void _addEnhancedOrdersSummaryFooter(
    Sheet sheet,
    List<dynamic> orders,
    int startRow,
  ) {
    final totalOrders = orders.length;
    final totalItems = orders.fold<int>(
      0,
      (sum, o) => sum + _safeInt(o['itemCount']),
    );
    final totalAmount = orders.fold<double>(
      0.0,
      (sum, o) => sum + _safeDouble(o['totalValue']),
    );

    sheet.cell(CellIndex.indexByString('A$startRow')).value = TextCellValue(
      'الإجماليات: الطلبات = $totalOrders | العناصر = $totalItems | المبلغ = ${totalAmount.toStringAsFixed(2)}',
    );
    sheet.cell(CellIndex.indexByString('A$startRow')).cellStyle = CellStyle(
      fontSize: 13,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1F4E79'),
      fontColorHex: ExcelColor.white,
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#1F4E79'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$startRow'),
      CellIndex.indexByString('R$startRow'),
    );
  }

  /// Legacy function for backward compatibility
  static void _addPurchaseOrdersDataTable(
    Sheet sheet,
    List<dynamic> orders,
    int startRow,
  ) {
    // Redirect to enhanced version
    _addEnhancedPurchaseOrdersDataTable(sheet, orders, startRow);
  }

  /// Add purchase order header with main information
  static int _addPurchaseOrderHeader(
    Sheet sheet,
    Map<String, dynamic> order,
    int startRow,
    int orderNumber,
  ) {
    // Order header background
    final headerRow = startRow;
    sheet.cell(CellIndex.indexByString('A$headerRow')).value = TextCellValue(
      '📋 طلب شراء رقم $orderNumber',
    );
    sheet.cell(CellIndex.indexByString('A$headerRow')).cellStyle = CellStyle(
      fontSize: 12,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#28A745'),
      fontColorHex: ExcelColor.white,
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#28A745'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$headerRow'),
      CellIndex.indexByString('N$headerRow'),
    );

    // Order details
    final detailsRow = startRow + 1;
    final orderDetails = [
      ['رقم الطلب:', _safeString(order['number'])],
      ['تاريخ الطلب:', _formatDate(order['requestDate'])],
      ['القسم:', _safeString(order['department'])],
      ['الحالة:', _getStatusInArabic(order['status'] ?? '')],
      ['المورد:', _safeString(order['supplierName'], 'غير محدد')],
      ['مقدم الطلب:', _safeString(order['requesterName'])],
      [
        'إجمالي المبلغ:',
        '${_safeDouble(order['totalValue']).toStringAsFixed(2)} ${_safeString(order['currency'], 'SYR')}',
      ],
      ['عدد العناصر:', '${_safeInt(order['itemCount'])} عنصر'],
    ];

    // Display details in a 4x2 grid
    for (int i = 0; i < orderDetails.length; i++) {
      final row = detailsRow + (i ~/ 4);
      final colOffset = (i % 4) * 3;
      final labelCol = String.fromCharCode(65 + colOffset);
      final valueCol = String.fromCharCode(65 + colOffset + 1);

      // Label cell
      sheet
          .cell(CellIndex.indexByString('$labelCol$row'))
          .value = TextCellValue(orderDetails[i][0]);
      sheet
          .cell(CellIndex.indexByString('$labelCol$row'))
          .cellStyle = CellStyle(
        fontSize: 10,
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#E8F5E8'),
        fontColorHex: ExcelColor.fromHexString('#2D5A2D'),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
      );

      // Value cell
      sheet
          .cell(CellIndex.indexByString('$valueCol$row'))
          .value = TextCellValue(orderDetails[i][1]);
      sheet
          .cell(CellIndex.indexByString('$valueCol$row'))
          .cellStyle = CellStyle(
        fontSize: 10,
        bold: i == 6, // Bold for total amount
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.white,
        fontColorHex:
            i == 3
                ? _getStatusColor(order['status'] ?? '')
                : i == 6
                ? ExcelColor.fromHexString('#28A745')
                : ExcelColor.fromHexString('#333333'),
        topBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#CCCCCC'),
        ),
      );

      // Merge value cell with next column for better spacing
      final nextValueCol = String.fromCharCode(65 + colOffset + 2);
      sheet.merge(
        CellIndex.indexByString('$valueCol$row'),
        CellIndex.indexByString('$nextValueCol$row'),
      );
    }

    return detailsRow + 2; // Return next available row
  }

  /// Add items table for a purchase order
  static int _addItemsTable(Sheet sheet, List<dynamic> items, int startRow) {
    // Items header
    final itemsHeaderRow = startRow;
    sheet
        .cell(CellIndex.indexByString('A$itemsHeaderRow'))
        .value = TextCellValue('📦 عناصر الطلب');
    sheet
        .cell(CellIndex.indexByString('A$itemsHeaderRow'))
        .cellStyle = CellStyle(
      fontSize: 11,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#FFC107'),
      fontColorHex: ExcelColor.fromHexString('#333333'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$itemsHeaderRow'),
      CellIndex.indexByString('N$itemsHeaderRow'),
    );

    // Items table headers
    final itemHeaderRow = startRow + 1;
    final itemHeaders = [
      'كود العنصر',
      'اسم العنصر',
      'الكمية',
      'الوحدة',
      'السعر',
      'العملة',
      'الإجمالي',
    ];

    for (int i = 0; i < itemHeaders.length; i++) {
      final colStart = String.fromCharCode(65 + (i * 2));
      final colEnd = String.fromCharCode(65 + (i * 2) + 1);

      sheet
          .cell(CellIndex.indexByString('$colStart$itemHeaderRow'))
          .value = TextCellValue(itemHeaders[i]);
      sheet
          .cell(CellIndex.indexByString('$colStart$itemHeaderRow'))
          .cellStyle = CellStyle(
        fontSize: 10,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#17A2B8'),
        fontColorHex: ExcelColor.white,
        topBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
        bottomBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
        leftBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
      );
      sheet.merge(
        CellIndex.indexByString('$colStart$itemHeaderRow'),
        CellIndex.indexByString('$colEnd$itemHeaderRow'),
      );
    }

    // Items data
    int currentRow = itemHeaderRow + 1;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isEvenRow = i % 2 == 0;
      final backgroundColor =
          isEvenRow ? ExcelColor.fromHexString('#F8F9FA') : ExcelColor.white;

      final quantity = _safeDouble(item['quantity']);
      final price = _safeDouble(item['price']);
      final lineTotal = quantity * price;

      final itemData = [
        _safeString(item['item_code'], 'غير محدد'),
        _safeString(item['item_name'], 'غير محدد'),
        quantity.toString(),
        _safeString(item['unit'], 'قطعة'),
        price.toStringAsFixed(2),
        _safeString(item['currency'], 'SYR'),
        lineTotal.toStringAsFixed(2),
      ];

      for (int j = 0; j < itemData.length; j++) {
        final colStart = String.fromCharCode(65 + (j * 2));
        final colEnd = String.fromCharCode(65 + (j * 2) + 1);

        sheet
            .cell(CellIndex.indexByString('$colStart$currentRow'))
            .value = TextCellValue(itemData[j]);
        sheet
            .cell(CellIndex.indexByString('$colStart$currentRow'))
            .cellStyle = CellStyle(
          fontSize: 9,
          bold: j == 6, // Bold for total column
          horizontalAlign:
              (j >= 2 && j <= 6)
                  ? HorizontalAlign.Center
                  : HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
          backgroundColorHex: backgroundColor,
          fontColorHex:
              (j == 4 || j == 6)
                  ? ExcelColor.fromHexString('#28A745')
                  : ExcelColor.fromHexString('#333333'),
          topBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          bottomBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          leftBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
          rightBorder: Border(
            borderStyle: BorderStyle.Thin,
            borderColorHex: ExcelColor.fromHexString('#DDDDDD'),
          ),
        );
        sheet.merge(
          CellIndex.indexByString('$colStart$currentRow'),
          CellIndex.indexByString('$colEnd$currentRow'),
        );
      }
      currentRow++;
    }

    // Add bottom border to items table
    for (int j = 0; j < 14; j++) {
      final col = String.fromCharCode(65 + j);
      final cell = sheet.cell(CellIndex.indexByString('$col$currentRow'));
      cell.cellStyle = CellStyle(
        bottomBorder: Border(
          borderStyle: BorderStyle.Thick,
          borderColorHex: ExcelColor.fromHexString('#17A2B8'),
        ),
      );
    }

    return currentRow + 1;
  }

  /// Add message when no items exist
  static int _addNoItemsMessage(Sheet sheet, int startRow) {
    sheet.cell(CellIndex.indexByString('A$startRow')).value = TextCellValue(
      '⚠️ لا توجد عناصر في هذا الطلب',
    );
    sheet.cell(CellIndex.indexByString('A$startRow')).cellStyle = CellStyle(
      fontSize: 11,
      italic: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#FFF3CD'),
      fontColorHex: ExcelColor.fromHexString('#856404'),
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFC107'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$startRow'),
      CellIndex.indexByString('N$startRow'),
    );
    return startRow + 1;
  }

  /// Add separator between orders
  static void _addOrderSeparator(Sheet sheet, int row) {
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('');
    sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E9ECEF'),
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#6C757D'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#6C757D'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$row'),
      CellIndex.indexByString('N$row'),
    );
  }

  /// Add empty data message
  static void _addEmptyDataMessage(Sheet sheet, int startRow, String message) {
    sheet.cell(CellIndex.indexByString('A$startRow')).value = TextCellValue(
      '📭 $message',
    );
    sheet.cell(CellIndex.indexByString('A$startRow')).cellStyle = CellStyle(
      fontSize: 14,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#F8D7DA'),
      fontColorHex: ExcelColor.fromHexString('#721C24'),
      topBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#DC3545'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#DC3545'),
      ),
      leftBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#DC3545'),
      ),
      rightBorder: Border(
        borderStyle: BorderStyle.Thick,
        borderColorHex: ExcelColor.fromHexString('#DC3545'),
      ),
    );
    sheet.merge(
      CellIndex.indexByString('A$startRow'),
      CellIndex.indexByString('N$startRow'),
    );
  }

  /// Safe string extraction with default value
  static String _safeString(dynamic value, [String defaultValue = 'غير محدد']) {
    if (value == null) return defaultValue;
    final str = value.toString().trim();
    return str.isEmpty ? defaultValue : str;
  }

  /// Safe double extraction
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Safe int extraction
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// Format date string
  static String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateValue.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return _safeString(dateValue);
    }
  }

  /// Get status in Arabic with enhanced mapping
  static String _getStatusInArabic(String status) {
    if (status.isEmpty) return 'غير محدد';

    switch (status.toLowerCase()) {
      case 'draft':
        return '📝 مسودة';
      case 'under_assistant_review':
        return '👀 تحت مراجعة المساعد';
      case 'under_manager_review':
        return '👔 تحت مراجعة المدير';
      case 'rejected_by_manager':
        return '❌ مرفوض من قبل المدير';
      case 'rejected_by_assistant':
        return "❌ مرفوض من قبل المساعد";
      case 'in_progress':
        return '⚙️ قيد التنفيذ';
      case 'completed':
        return '✅ مكتمل';
      case 'cancelled':
        return '❌ ملغي';
      case 'pending':
        return '⏳ في الانتظار';
      case 'approved':
        return '✅ موافق عليه';
      case 'rejected':
        return '❌ مرفوض';
      default:
        return status;
    }
  }

  /// Get status color based on status value
  static ExcelColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return ExcelColor.fromHexString('#6C757D'); // Gray
      case 'under_assistant_review':
      case 'under_manager_review':
        return ExcelColor.fromHexString('#FFC107'); // Yellow
      case 'in_progress':
        return ExcelColor.fromHexString('#17A2B8'); // Blue
      case 'completed':
      case 'approved':
        return ExcelColor.fromHexString('#28A745'); // Green
      case 'cancelled':
      case 'rejected':
        return ExcelColor.fromHexString('#DC3545'); // Red
      case 'pending':
        return ExcelColor.fromHexString('#FD7E14'); // Orange
      default:
        return ExcelColor.fromHexString('#333333'); // Default dark
    }
  }

  /// Auto-fit columns with enhanced width settings
  static void _autoFitColumns(Sheet sheet, List<String> columns) {
    for (String col in columns) {
      final int index = _colLetterToIndex(col);
      try {
        // Set a reasonable width for all columns
        sheet.setColumnWidth(index, 20);
      } catch (e) {
        // If setting width fails, continue with next column
        continue;
      }
    }
  }

  /// Convert Excel column letters (e.g., A, B, AA) to zero-based index
  static int _colLetterToIndex(String col) {
    int index = 0;
    final upper = col.trim().toUpperCase();
    for (int i = 0; i < upper.length; i++) {
      index = index * 26 + (upper.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1);
    }
    return index - 1; // zero-based
  }

  /// Save Excel file with enhanced error handling and user feedback
  static Future<String> _saveExcelFile(Excel excel, String fileName) async {
    try {
      // Show loading indicator
      Get.snackbar(
        'جاري التصدير...',
        'يتم إنشاء وحفظ ملف Excel',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryGreen.withOpacity(0.9),
        colorText: mat.Colors.white,
        icon: const mat.Icon(
          mat.Icons.hourglass_empty,
          color: mat.Colors.white,
        ),
      );

      // Request storage permission with better handling
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try requesting manage external storage permission for Android 11+
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            throw Exception(
              'تم رفض إذن الوصول للتخزين. يرجى السماح بالوصول للملفات من إعدادات التطبيق.',
            );
          }
        }
      }

      // Get the appropriate directory with better fallback options
      Directory? directory;
      if (Platform.isWindows) {
        directory = await getDownloadsDirectory();
        directory ??= await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        // Try multiple directory options
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = Directory('/storage/emulated/0/Documents');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
            if (directory != null) {
              directory = Directory('${directory.path}/Download');
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }
            }
          }
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('لا يمكن الوصول إلى مجلد التخزين');
      }

      // Create unique file name to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${fileName}_$timestamp';
      final filePath = '${directory.path}/$uniqueFileName.xlsx';

      // Save file with better error handling
      final fileBytes = excel.save();
      if (fileBytes != null && fileBytes.isNotEmpty) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Verify file was created successfully
        if (await file.exists()) {
          final fileSize = await file.length();

          // Show enhanced success message
          Get.snackbar(
            '✅ نجح التصدير',
            'تم حفظ الملف بنجاح\nالمسار: $filePath\nحجم الملف: ${(fileSize / 1024).toStringAsFixed(1)} KB',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 8),
            backgroundColor: AppColors.success.withOpacity(0.95),
            colorText: mat.Colors.white,
            icon: const mat.Icon(
              mat.Icons.download_done,
              color: mat.Colors.white,
            ),
            mainButton: mat.TextButton(
              onPressed: () {
                Get.back();
                // Could add functionality to open file or share
              },
              child: const mat.Text(
                'إغلاق',
                style: mat.TextStyle(color: mat.Colors.white),
              ),
            ),
          );

          return filePath;
        } else {
          throw Exception('فشل في التحقق من إنشاء الملف');
        }
      } else {
        throw Exception('فشل في إنشاء بيانات ملف Excel');
      }
    } catch (e) {
      // Enhanced error handling with specific error messages
      String errorMessage = 'فشل في حفظ الملف';
      String errorDetails = e.toString();

      if (e.toString().contains('permission')) {
        errorMessage = 'خطأ في الصلاحيات';
        errorDetails = 'يرجى السماح للتطبيق بالوصول للتخزين من الإعدادات';
      } else if (e.toString().contains('storage') ||
          e.toString().contains('directory')) {
        errorMessage = 'خطأ في التخزين';
        errorDetails = 'لا يمكن الوصول إلى مجلد التخزين';
      } else if (e.toString().contains('space')) {
        errorMessage = 'مساحة غير كافية';
        errorDetails = 'لا توجد مساحة كافية في التخزين';
      }

      Get.snackbar(
        '❌ $errorMessage',
        errorDetails,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
        backgroundColor: AppColors.error.withOpacity(0.95),
        colorText: mat.Colors.white,
        icon: const mat.Icon(mat.Icons.error_outline, color: mat.Colors.white),
        mainButton: mat.TextButton(
          onPressed: () => Get.back(),
          child: mat.Text(
            'إغلاق',
            style: mat.TextStyle(color: mat.Colors.white),
          ),
        ),
      );
      rethrow;
    }
  }
}
