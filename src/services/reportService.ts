import Excel from 'exceljs';
import { format } from 'date-fns';
import { ar, enUS } from 'date-fns/locale';
import * as repo from '../repositories/reportRepository';

/**
 * Interface for expense report filters
 */
interface ExpenseReportFilters {
  startDate?: Date;
  endDate?: Date;
  supplierId?: string;
  department?: string;
  status?: string;
}

/**
 * Interface for purchase quantity report filters
 */
interface QuantityReportFilters {
  startDate?: Date;
  endDate?: Date;
  itemId?: string;
  department?: string;
}

/**
 * Interface for purchase order list filters
 */
interface PurchaseOrderListFilters {
  startDate?: Date;
  endDate?: Date;
  supplierId?: string;
  department?: string;
  status?: string;
}

/**
 * Interface for pagination options
 */
interface PaginationOptions {
  page: number;
  limit: number;
}

/**
 * Get expense report data
 * @param filters Filters for the report
 * @param pagination Pagination options
 */
export const getExpenseReport = async (
  filters: ExpenseReportFilters,
  pagination?: PaginationOptions
) => {
  const offset = pagination ? (pagination.page - 1) * pagination.limit : undefined;
  const limit = pagination ? pagination.limit : undefined;
  const { orders, totalCount } = await repo.expenseOrders(filters, offset, limit);

  const reportData = orders.map((order: any) => {
    const totalExpense = (order.items as any[]).reduce((sum, item: any) => sum + ((item.price || 0) * (item.quantity || 0)), 0);
    return {
      id: order.id,
      requestDate: order.request_date,
      completedDate: order.updated_at,
      department: order.department,
      supplierName: order.supplier_name || 'N/A',
      requesterName: order.creator_name || order.requester_name,
      currency: order.currency,
      totalExpense,
      items: (order.items as any[]).map((item: any) => ({
        name: item.item_name,
        quantity: item.quantity,
        unit: item.unit,
        price: item.price,
        lineTotal: (item.price || 0) * (item.quantity || 0),
      })),
    };
  });

  const grandTotal = reportData.reduce((sum, order) => sum + order.totalExpense, 0);

  return {
    data: reportData,
    pagination: pagination ? {
      page: pagination.page,
      limit: pagination.limit,
      totalCount,
      totalPages: Math.ceil(totalCount / pagination.limit)
    } : undefined,
    summary: {
      totalOrders: reportData.length,
      grandTotal
    }
  };
};

/**
 * Get purchase quantity report data
 * @param filters Filters for the report
 * @param pagination Pagination options
 */
export const getQuantityReport = async (
  filters: QuantityReportFilters,
  pagination?: PaginationOptions
) => {
  const rows = await repo.quantityItems(filters);

  const itemMap = new Map<string, {
    itemName: string;
    totalQuantity: number;
    totalValue: number;
    departments: Map<string, { quantity: number; value: number }>;
    currency: string;
  }>();

  rows.forEach((item: any) => {
    const key = item.item_name;
    const department = item.department;
    const lineTotal = (item.price || 0) * (item.quantity || 0);

    if (!itemMap.has(key)) {
      itemMap.set(key, {
        itemName: item.item_name,
        totalQuantity: 0,
        totalValue: 0,
        departments: new Map(),
        currency: item.currency,
      });
    }

    const itemData = itemMap.get(key)!;
    itemData.totalQuantity += item.quantity || 0;
    itemData.totalValue += lineTotal;

    if (!itemData.departments.has(department)) {
      itemData.departments.set(department, { quantity: 0, value: 0 });
    }

    const deptData = itemData.departments.get(department)!;
    deptData.quantity += item.quantity || 0;
    deptData.value += lineTotal;
  });

  let items = Array.from(itemMap.values()).map(item => ({
    itemName: item.itemName,
    totalQuantity: item.totalQuantity,
    totalValue: item.totalValue,
    currency: item.currency,
    departments: Array.from(item.departments.entries()).map(([dept, data]) => ({
      department: dept,
      quantity: data.quantity,
      value: data.value,
    })),
  }));

  items.sort((a, b) => b.totalQuantity - a.totalQuantity);

  let paginatedItems = items;
  if (pagination) {
    const startIndex = (pagination.page - 1) * pagination.limit;
    paginatedItems = items.slice(startIndex, startIndex + pagination.limit);
  }

  const grandTotalQuantity = items.reduce((sum, item) => sum + item.totalQuantity, 0);
  const grandTotalValue = items.reduce((sum, item) => sum + item.totalValue, 0);

  return {
    data: paginatedItems,
    pagination: pagination ? {
      page: pagination.page,
      limit: pagination.limit,
      totalCount: items.length,
      totalPages: Math.ceil(items.length / pagination.limit)
    } : undefined,
    summary: {
      totalItems: items.length,
      grandTotalQuantity,
      grandTotalValue,
    },
  };
};

/**
 * Get purchase order list data
 * @param filters Filters for the list
 * @param pagination Pagination options
 */
export const getPurchaseOrderList = async (
  filters: PurchaseOrderListFilters,
  pagination?: PaginationOptions
) => {
  const offset = pagination ? (pagination.page - 1) * pagination.limit : undefined;
  const limit = pagination ? pagination.limit : undefined;
  const { orders, totalCount } = await repo.purchaseOrderList(filters, offset, limit);

  const listData = orders.map((order: any) => {
    const totalValue = (order.items as any[]).reduce((sum, item: any) => sum + ((item.price || 0) * (item.quantity || 0)), 0);
    return {
      id: order.id,
      number:order.number,
      requestDate: order.request_date,
      department: order.department,
      status: order.status,
      supplierName: order.supplier_name || 'N/A',
      requesterName: order.requester_name,
      currency: order.currency,
      totalValue,
      itemCount: (order.items as any[]).length,
    };
  });

  return {
    data: listData,
    pagination: pagination ? {
      page: pagination.page,
      limit: pagination.limit,
      totalCount,
      totalPages: Math.ceil(totalCount / pagination.limit)
    } : undefined
  };
};

/**
 * Generate Excel file for expense report
 * @param filters Filters for the report
 * @param locale Locale for date formatting
 */
export const generateExpenseReportExcel = async (
  filters: ExpenseReportFilters,
  locale: string = 'en'
) => {
  // Get all data without pagination for export
  const reportData = await getExpenseReport(filters);
  
  // Create a new workbook
  const workbook = new Excel.Workbook();
  
  // Add a worksheet
  const worksheet = workbook.addWorksheet('Expense Report');
  
  // Add a title row
  worksheet.mergeCells('A1:I1');
  const titleCell = worksheet.getCell('A1');
  titleCell.value = 'Expense Report';
  titleCell.font = {
    size: 16,
    bold: true
  };
  titleCell.alignment = { horizontal: 'center' };
  
  // Add filters info
  let filterRow = 2;
  
  if (filters.startDate || filters.endDate) {
    worksheet.mergeCells(`A${filterRow}:I${filterRow}`);
    const dateRangeCell = worksheet.getCell(`A${filterRow}`);
    dateRangeCell.value = `Date Range: ${filters.startDate ? format(filters.startDate, 'yyyy-MM-dd') : 'Any'} to ${filters.endDate ? format(filters.endDate, 'yyyy-MM-dd') : 'Any'}`;
    dateRangeCell.font = { italic: true };
    filterRow++;
  }
  
  if (filters.supplierId) {
    worksheet.mergeCells(`A${filterRow}:I${filterRow}`);
    const supplierCell = worksheet.getCell(`A${filterRow}`);
    supplierCell.value = `Supplier ID: ${filters.supplierId}`;
    supplierCell.font = { italic: true };
    filterRow++;
  }
  
  if (filters.department) {
    worksheet.mergeCells(`A${filterRow}:I${filterRow}`);
    const deptCell = worksheet.getCell(`A${filterRow}`);
    deptCell.value = `Department: ${filters.department}`;
    deptCell.font = { italic: true };
    filterRow++;
  }
  
  if (filters.status) {
    worksheet.mergeCells(`A${filterRow}:I${filterRow}`);
    const statusCell = worksheet.getCell(`A${filterRow}`);
    statusCell.value = `Status: ${filters.status}`;
    statusCell.font = { italic: true };
    filterRow++;
  }
  
  // Add empty row
  filterRow++;
  
  // Define columns
  worksheet.columns = [
    { header: 'Order ID', key: 'id', width: 20 },
    { header: 'Request Date', key: 'requestDate', width: 15 },
    { header: 'Completed Date', key: 'completedDate', width: 15 },
    { header: 'Department', key: 'department', width: 15 },
    { header: 'Supplier', key: 'supplierName', width: 20 },
    { header: 'Requester', key: 'requesterName', width: 20 },
    { header: 'Items', key: 'itemCount', width: 10 },
    { header: 'Currency', key: 'currency', width: 10 },
    { header: 'Total Expense', key: 'totalExpense', width: 15 }
  ];
  
  // Style the header row
  worksheet.getRow(filterRow).font = { bold: true };
  worksheet.getRow(filterRow).alignment = { horizontal: 'center' };
  
  // Add data rows
  let dataRowStart = filterRow + 1;
  reportData.data.forEach((order, index) => {
    const row = worksheet.addRow({
      id: order.id,
      requestDate: format(new Date(order.requestDate), 'yyyy-MM-dd', { locale: locale === 'ar' ? ar : enUS }),
      completedDate: format(new Date(order.completedDate), 'yyyy-MM-dd', { locale: locale === 'ar' ? ar : enUS }),
      department: order.department,
      supplierName: order.supplierName,
      requesterName: order.requesterName,
      itemCount: order.items.length,
      currency: order.currency,
      totalExpense: order.totalExpense
    });
    
    // Style the expense column as currency
    const expenseCell = row.getCell('totalExpense');
    expenseCell.numFmt = '#,##0.00';
  });
  
  // Add a summary row
  const summaryRowIndex = dataRowStart + reportData.data.length + 1;
  const summaryRow = worksheet.addRow({
    id: 'TOTAL',
    totalExpense: reportData.summary.grandTotal
  });
  summaryRow.font = { bold: true };
  const totalExpenseCell = summaryRow.getCell('totalExpense');
  totalExpenseCell.numFmt = '#,##0.00';
  
  // Add items detail worksheet
  const itemsWorksheet = workbook.addWorksheet('Items Detail');
  
  // Define columns for items worksheet
  itemsWorksheet.columns = [
    { header: 'Order ID', key: 'orderId', width: 20 },
    { header: 'Item Name', key: 'itemName', width: 30 },
    { header: 'Quantity', key: 'quantity', width: 10 },
    { header: 'Unit', key: 'unit', width: 10 },
    { header: 'Price', key: 'price', width: 15 },
    { header: 'Line Total', key: 'lineTotal', width: 15 },
    { header: 'Currency', key: 'currency', width: 10 }
  ];
  
  // Style the header row
  itemsWorksheet.getRow(1).font = { bold: true };
  itemsWorksheet.getRow(1).alignment = { horizontal: 'center' };
  
  // Add items data
  reportData.data.forEach(order => {
    order.items.forEach(item => {
      const row = itemsWorksheet.addRow({
        orderId: order.id,
        itemName: item.name,
        quantity: item.quantity,
        unit: item.unit,
        price: item.price,
        lineTotal: item.lineTotal,
        currency: order.currency
      });
      
      // Style the price and line total columns as currency
      const priceCell = row.getCell('price');
      priceCell.numFmt = '#,##0.00';
      
      const lineTotalCell = row.getCell('lineTotal');
      lineTotalCell.numFmt = '#,##0.00';
    });
  });
  
  return workbook;
};

/**
 * Generate Excel file for quantity report
 * @param filters Filters for the report
 * @param locale Locale for date formatting
 */
export const generateQuantityReportExcel = async (
  filters: QuantityReportFilters,
  locale: string = 'en'
) => {
  // Get all data without pagination for export
  const reportData = await getQuantityReport(filters);
  
  // Create a new workbook
  const workbook = new Excel.Workbook();
  
  // Add a worksheet
  const worksheet = workbook.addWorksheet('Quantity Report');
  
  // Add a title row
  worksheet.mergeCells('A1:F1');
  const titleCell = worksheet.getCell('A1');
  titleCell.value = 'Purchase Quantity Report';
  titleCell.font = {
    size: 16,
    bold: true
  };
  titleCell.alignment = { horizontal: 'center' };
  
  // Add filters info
  let filterRow = 2;
  
  if (filters.startDate || filters.endDate) {
    worksheet.mergeCells(`A${filterRow}:F${filterRow}`);
    const dateRangeCell = worksheet.getCell(`A${filterRow}`);
    dateRangeCell.value = `Date Range: ${filters.startDate ? format(filters.startDate, 'yyyy-MM-dd') : 'Any'} to ${filters.endDate ? format(filters.endDate, 'yyyy-MM-dd') : 'Any'}`;
    dateRangeCell.font = { italic: true };
    filterRow++;
  }
  
  if (filters.itemId) {
    worksheet.mergeCells(`A${filterRow}:F${filterRow}`);
    const itemCell = worksheet.getCell(`A${filterRow}`);
    itemCell.value = `Item ID: ${filters.itemId}`;
    itemCell.font = { italic: true };
    filterRow++;
  }
  
  if (filters.department) {
    worksheet.mergeCells(`A${filterRow}:F${filterRow}`);
    const deptCell = worksheet.getCell(`A${filterRow}`);
    deptCell.value = `Department: ${filters.department}`;
    deptCell.font = { italic: true };
    filterRow++;
  }
  
  // Add empty row
  filterRow++;
  
  // Define columns
  worksheet.columns = [
    { header: 'Item Name', key: 'itemName', width: 30 },
    { header: 'Total Quantity', key: 'totalQuantity', width: 15 },
    { header: 'Total Value', key: 'totalValue', width: 15 },
    { header: 'Currency', key: 'currency', width: 10 },
    { header: 'Departments', key: 'departments', width: 30 }
  ];
  
  // Style the header row
  worksheet.getRow(filterRow).font = { bold: true };
  worksheet.getRow(filterRow).alignment = { horizontal: 'center' };
  
  // Add data rows
  let dataRowStart = filterRow + 1;
  reportData.data.forEach((item) => {
    const row = worksheet.addRow({
      itemName: item.itemName,
      totalQuantity: item.totalQuantity,
      totalValue: item.totalValue,
      currency: item.currency,
      departments: item.departments.map(d => `${d.department}: ${d.quantity}`).join(', ')
    });
    
    // Style the value column as currency
    const valueCell = row.getCell('totalValue');
    valueCell.numFmt = '#,##0.00';
  });
  
  // Add a summary row
  const summaryRowIndex = dataRowStart + reportData.data.length + 1;
  const summaryRow = worksheet.addRow({
    itemName: 'TOTAL',
    totalQuantity: reportData.summary.grandTotalQuantity,
    totalValue: reportData.summary.grandTotalValue
  });
  summaryRow.font = { bold: true };
  const totalValueCell = summaryRow.getCell('totalValue');
  totalValueCell.numFmt = '#,##0.00';
  
  // Add department detail worksheet
  const deptWorksheet = workbook.addWorksheet('Department Detail');
  
  // Define columns for department worksheet
  deptWorksheet.columns = [
    { header: 'Item Name', key: 'itemName', width: 30 },
    { header: 'Department', key: 'department', width: 20 },
    { header: 'Quantity', key: 'quantity', width: 15 },
    { header: 'Value', key: 'value', width: 15 },
    { header: 'Currency', key: 'currency', width: 10 }
  ];
  
  // Style the header row
  deptWorksheet.getRow(1).font = { bold: true };
  deptWorksheet.getRow(1).alignment = { horizontal: 'center' };
  
  // Add department data
  reportData.data.forEach(item => {
    item.departments.forEach(dept => {
      const row = deptWorksheet.addRow({
        itemName: item.itemName,
        department: dept.department,
        quantity: dept.quantity,
        value: dept.value,
        currency: item.currency
      });
      
      // Style the value column as currency
      const valueCell = row.getCell('value');
      valueCell.numFmt = '#,##0.00';
    });
  });
  
  return workbook;
};

/**
 * Generate Excel file for purchase order list
 * @param filters Filters for the list
 * @param locale Locale for date formatting
 */
export const generatePurchaseOrderListExcel = async (
  filters: PurchaseOrderListFilters,
  locale: string = 'en'
) => {
  // Get all data without pagination for export
  const listData = await getPurchaseOrderList(filters);
  
  // Create a new workbook
  const workbook = new Excel.Workbook();
  
  // Add a worksheet
  const worksheet = workbook.addWorksheet('Purchase Orders');
  
  // Add a title row
  worksheet.mergeCells('A1:I1');
  const titleCell = worksheet.getCell('A1');
  titleCell.value = 'Purchase Order List';
  titleCell.font = {
    size: 16,
    bold: true
  };
  titleCell.alignment = { horizontal: 'center' };
  
  // Add filters info
  let filterRow = 2;
  
  if (filters.startDate || filters.endDate) {
    worksheet.mergeCells(`A${filterRow}:I${filterRow}`);
    const dateRangeCell = worksheet.getCell(`A${filterRow}`);
    dateRangeCell.value = `Date Range: ${filters.startDate ? format(filters.startDate, 'yyyy-MM-dd') : 'Any'} to ${filters.endDate ? format(filters.endDate, 'yyyy-MM-dd') : 'Any'}`;
    dateRangeCell.font = { italic: true };
    filterRow++;
  }
  
  if (filters.supplierId) {
    worksheet.mergeCells(`A${filterRow}:I${filterRow}`);
    const supplierCell = worksheet.getCell(`A${filterRow}`);
    supplierCell.value = `Supplier ID: ${filters.supplierId}`;
    supplierCell.font = { italic: true };
    filterRow++;
  }
  
  if (filters.department) {
    worksheet.mergeCells(`A${filterRow}:I${filterRow}`);
    const deptCell = worksheet.getCell(`A${filterRow}`);
    deptCell.value = `Department: ${filters.department}`;
    deptCell.font = { italic: true };
    filterRow++;
  }
  
  if (filters.status) {
    worksheet.mergeCells(`A${filterRow}:I${filterRow}`);
    const statusCell = worksheet.getCell(`A${filterRow}`);
    statusCell.value = `Status: ${filters.status}`;
    statusCell.font = { italic: true };
    filterRow++;
  }
  
  // Add empty row
  filterRow++;
  
  // Define columns
  worksheet.columns = [
    { header: 'Order ID', key: 'id', width: 20 },
    { header: 'Request Date', key: 'requestDate', width: 15 },
    { header: 'Department', key: 'department', width: 15 },
    { header: 'Status', key: 'status', width: 20 },
    { header: 'Supplier', key: 'supplierName', width: 20 },
    { header: 'Requester', key: 'requesterName', width: 20 },
    { header: 'Items', key: 'itemCount', width: 10 },
    { header: 'Currency', key: 'currency', width: 10 },
    { header: 'Total Value', key: 'totalValue', width: 15 }
  ];
  
  // Style the header row
  worksheet.getRow(filterRow).font = { bold: true };
  worksheet.getRow(filterRow).alignment = { horizontal: 'center' };
  
  // Add data rows
  listData.data.forEach((order) => {
    const row = worksheet.addRow({
      id: order.id,
      requestDate: format(new Date(order.requestDate), 'yyyy-MM-dd', { locale: locale === 'ar' ? ar : enUS }),
      department: order.department,
      status: order.status,
      supplierName: order.supplierName,
      requesterName: order.requesterName,
      itemCount: order.itemCount,
      currency: order.currency,
      totalValue: order.totalValue
    });
    
    // Style the value column as currency
    const valueCell = row.getCell('totalValue');
    valueCell.numFmt = '#,##0.00';
  });
  
  return workbook;
};

/**
 * Get vendor report data
 * @param filters Filters for the report
 * @param pagination Pagination options
 */
export const getVendorReport = async (
  filters: { status?: string; include_performance?: boolean },
  pagination?: PaginationOptions
) => {
  const offset = pagination ? (pagination.page - 1) * pagination.limit : undefined;
  const limit = pagination ? pagination.limit : undefined;
  const { vendors, totalCount } = await repo.getVendorReportData(filters, offset, limit);

  return {
    data: vendors,
    pagination: pagination ? {
      page: pagination.page,
      limit: pagination.limit,
      totalCount,
      totalPages: Math.ceil(totalCount / pagination.limit)
    } : undefined
  };
};

/**
 * Get item report data
 * @param filters Filters for the report
 * @param pagination Pagination options
 */
export const getItemReport = async (
  filters: { status?: string; include_usage?: boolean },
  pagination?: PaginationOptions
) => {
  const offset = pagination ? (pagination.page - 1) * pagination.limit : undefined;
  const limit = pagination ? pagination.limit : undefined;
  const { items, totalCount } = await repo.getItemReportData(filters, offset, limit);

  return {
    data: items,
    pagination: pagination ? {
      page: pagination.page,
      limit: pagination.limit,
      totalCount,
      totalPages: Math.ceil(totalCount / pagination.limit)
    } : undefined
  };
};