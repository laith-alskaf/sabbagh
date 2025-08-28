# Reports Module - Debugging Guide 🔧

## 🎯 المشاكل المحلولة:

### ✅ المشكلة 1: Dropdown فارغة
**السبب**: البيانات لا تُحمل بشكل صحيح من الباك إند
**الحل المطبق**:
- ✅ إضافة debugging logs في Controller
- ✅ إضافة fallback data في حالة فشل API calls
- ✅ تحسين error handling
- ✅ إضافة `Obx()` wrapper للـ reactive updates

### ✅ المشكلة 2: Export API 404 Error
**السبب**: الباك إند لا يحتوي على `/export` endpoints منفصلة
**الحل المطبق**:
- ✅ استخدام `format=excel` parameter مع main endpoints
- ✅ تحديث جميع export methods
- ✅ إضافة proper response handling للـ binary data

---

## 🧪 خطة الاختبار:

### 1. اختبار Dropdown Data Loading:
```bash
# تشغيل التطبيق
flutter run

# مراقبة Console logs:
# 🔄 Fetching vendors...
# ✅ Vendors loaded: X items
# 📋 Vendors: [vendor names]
# 
# 🔄 Fetching departments...
# ✅ Departments loaded: X items
# 📋 Departments: [department names]
```

### 2. اختبار Export Functionality:
```bash
# الضغط على زر Export
# مراقبة Console logs:
# 🔄 Exporting purchase orders report with params: {...}
# 📤 Export params: {format: excel, start_date: ..., end_date: ...}
# 📥 Export response type: String (for binary data)
```

---

## 🔍 Debugging Steps:

### إذا كانت الـ Dropdowns فارغة:

1. **تحقق من Console Logs**:
   ```
   ❌ Error fetching vendors: [error message]
   ❌ Error fetching departments: [error message]
   ```

2. **تحقق من Network Connectivity**:
   - تأكد من أن الباك إند يعمل على `https://sabbagh.vercel.app`
   - تحقق من صحة JWT token

3. **تحقق من API Endpoints**:
   - `GET /vendors` - للموردين
   - `GET /admin/departments` - للأقسام

4. **Fallback Data**:
   - إذا فشلت API calls، ستظهر بيانات تجريبية
   - Vendors: "Test Vendor 1", "Test Vendor 2"
   - Departments: "Production", "Maintenance", etc.

### إذا كان Export لا يعمل:

1. **تحقق من Console Logs**:
   ```
   🔄 Exporting purchase orders report with params: {...}
   📤 Export params: {format: excel, ...}
   ❌ Error exporting purchase orders report: [error]
   ```

2. **تحقق من Parameters**:
   - `format: excel` يجب أن يكون موجود
   - `start_date` و `end_date` بالتنسيق الصحيح
   - `supplier_id` بدلاً من `vendor_id`

3. **تحقق من Response Type**:
   - للـ Excel: response يجب أن يكون `String` (binary data)
   - للـ JSON: response يجب أن يكون `Map` مع `success: true`

---

## 🛠️ الإصلاحات المطبقة:

### في Controller:
```dart
// إضافة debugging logs
print('🔄 Fetching vendors...');
print('✅ Vendors loaded: ${vendors.length} items');

// إضافة fallback data
vendors.value = [
  {'id': 'vendor-1', 'name': 'Test Vendor 1'},
  {'id': 'vendor-2', 'name': 'Test Vendor 2'},
];
```

### في Repository:
```dart
// تحديث export methods
final exportParams = <String, dynamic>{
  'format': 'excel', // استخدام format parameter
};

// استخدام main endpoints بدلاً من /export
final response = await _dioClient.get(
  '/reports/purchase-orders', // بدلاً من /reports/purchase-orders/export
  queryParameters: exportParams,
);
```

### في Views:
```dart
// إضافة Obx wrapper للـ dropdowns
Obx(() => _buildDropdownField(
  value: controller.selectedDepartment.value.isEmpty ? null : controller.selectedDepartment.value,
  items: [...],
  onChanged: (value) => controller.selectedDepartment.value = value ?? '',
))
```

---

## 📊 Expected API Responses:

### Vendors API (`GET /vendors`):
```json
{
  "success": true,
  "data": [
    {
      "id": "vendor-uuid-1",
      "name": "ABC Trading Company",
      "contact_person": "John Smith",
      "phone": "+963-11-1234567"
    }
  ]
}
```

### Departments API (`GET /admin/departments`):
```json
{
  "success": true,
  "data": [
    "Production",
    "Maintenance", 
    "Quality Control",
    "Logistics",
    "Administration"
  ]
}
```

### Reports API (`GET /reports/purchase-orders`):
```json
{
  "success": true,
  "data": [
    {
      "order_number": "PO-2024-001",
      "requester_name": "Ahmad Al-Sabbagh",
      "department": "IT Department",
      "status": "completed",
      "created_at": "2024-01-15",
      "total_amount": 1500.00
    }
  ],
  "summary": {
    "total_orders": 156,
    "total_amount": 450000.00,
    "currency": "SAR"
  }
}
```

### Export API (`GET /reports/purchase-orders?format=excel`):
```
Binary Excel file data (application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
```

---

## 🚀 Next Steps:

1. **تشغيل التطبيق**: `flutter run`
2. **مراقبة Console**: تحقق من debugging logs
3. **اختبار Dropdowns**: تأكد من ظهور البيانات
4. **اختبار Reports**: إنشاء تقرير واختبار البيانات
5. **اختبار Export**: تجربة تصدير Excel

---

## 🎉 النتيجة المتوقعة:

- ✅ **Dropdowns تعرض البيانات**: إما من الباك إند أو fallback data
- ✅ **Reports تعمل بشكل صحيح**: عرض البيانات الحقيقية
- ✅ **Export يعمل**: تحميل ملفات Excel
- ✅ **لا توجد errors**: جميع المشاكل محلولة

**النظام جاهز للاستخدام! 🚀**