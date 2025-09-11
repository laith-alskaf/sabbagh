import { PurchaseOrderStatus } from '../types/models';
import { startOfMonth, subMonths, format } from 'date-fns';
import { ar, enUS } from 'date-fns/locale';
import * as repo from '../repositories/dashboardRepository';

/**
 * Get count of purchase orders grouped by status
 */
export const getPurchaseOrdersByStatus = async () => {
  return repo.countByStatus();
};

/**
 * Get total expenses for each month (last 12 months)
 * @param locale Language locale for month names (en or ar)
 */
export const getMonthlyExpenses = async (locale: string = 'en') => {
  const today = new Date();
  const months = [];
  
  // Generate array of the last 12 months
  for (let i = 0; i < 12; i++) {
    const date = subMonths(today, i);
    const startDate = startOfMonth(date);
    
    // Format month name based on locale
    const monthName = format(date, 'MMMM', { 
      locale: locale === 'ar' ? ar : enUS 
    });
    
    months.unshift({
      month: format(date, 'yyyy-MM'),
      monthName,
      startDate,
      endDate: i === 0 ? today : subMonths(startOfMonth(today), i - 1)
    });
  }
  
  const completedOrders = await repo.completedOrdersSince(months[0].startDate);

  const monthlyExpenses = months.map(month => {
    const ordersInMonth = completedOrders.filter(order => 
      order.updated_at >= month.startDate && 
      order.updated_at <= month.endDate
    );

    const totalExpense = ordersInMonth.reduce((total, order) => {
      const orderTotal = (order.items as any[]).reduce((sum, item: any) =>
        sum + ((item.price || 0) * (item.quantity || 0)), 0);
      return total + orderTotal;
    }, 0);

    return {
      month: month.month,
      monthName: month.monthName,
      totalExpense
    };
  });

  return monthlyExpenses;
};

/**
 * Get top suppliers by order count or total value
 * @param limit Number of suppliers to return
 * @param sortBy Field to sort by ('count' or 'value')
 */
export const getTopSuppliers = async (limit: number = 5, sortBy: 'count' | 'value' = 'count') => {
  const completedOrders = await repo.completedOrdersWithSupplier();

  const supplierMap = completedOrders.reduce((acc: Record<string, { id: string; name: string; orderCount: number; totalValue: number }>, order: any) => {
    const supplierId = order.supplier_id;
    const supplierName = order.supplier_name;
    if (!supplierId || !supplierName) return acc;

    if (!acc[supplierId]) {
      acc[supplierId] = {
        id: supplierId,
        name: supplierName,
        orderCount: 0,
        totalValue: 0,
      };
    }

    const orderValue = (order.items as any[]).reduce((sum, item: any) => sum + ((item.price || 0) * (item.quantity || 0)), 0);

    acc[supplierId].orderCount += 1;
    acc[supplierId].totalValue += orderValue;

    return acc;
  }, {});

  const suppliers = Object.values(supplierMap);
  if (sortBy === 'count') suppliers.sort((a, b) => b.orderCount - a.orderCount);
  else suppliers.sort((a, b) => b.totalValue - a.totalValue);

  return suppliers.slice(0, limit);
};

/**
 * Get quick statistics for the dashboard
 */
export const getQuickStats = async () => {
  const counts = await repo.quickCounts();

  // Get total value of completed orders by summing completed orders' item lines
  const completed = await repo.completedOrdersWithSupplier();
  const totalValue = completed.reduce((total, order: any) => {
    const orderTotal = (order.items as any[]).reduce((sum, item: any) => sum + ((item.price || 0) * (item.quantity || 0)), 0);
    return total + orderTotal;
  }, 0);

  return {
    totalOrders: counts.totalOrders,
    pendingOrders: counts.pendingOrders,
    inProgressOrders: counts.inProgressOrders,
    completedOrders: counts.completedOrders,
    totalValue,
    supplierCount: counts.supplierCount,
    itemCount: counts.itemCount,
  };
};

/**
 * Get recent purchase orders
 * @param limit Number of orders to return
 */
export const getRecentOrders = async (limit: number = 5) => {
  return repo.recentOrders(limit);
};