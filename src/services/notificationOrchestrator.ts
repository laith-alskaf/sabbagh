import { PurchaseOrderResponse } from '../types/purchaseOrder';
import { PurchaseOrderStatus, UserRole } from '../types/models';
import * as notifRepo from '../repositories/notificationRepository';
import * as userRepo from '../repositories/userRepository';
import * as fcmRepo from '../repositories/fcmTokenRepository';
import { buildPONotificationData, INotificationService } from '../utils/notification.service';
import { tl } from '../utils/i18n';

export class NotificationOrchestrator {
  constructor(private notifier: INotificationService) { }

  private async sendAndPersist(toUserIds: string[], payload: { type: string; title: string; body?: string; data: Record<string, string> }, po: PurchaseOrderResponse) {
    console.log(`🔔 Notification Debug - toUserIds: ${JSON.stringify(toUserIds)}`);
    console.log(`🔔 Notification Debug - payload: ${JSON.stringify(payload)}`);

    // Persist per-user notification
    await Promise.all(
      toUserIds.map((uid) => notifRepo.insert(uid, payload.type, payload.title, payload.body ?? null, { po }))
    );

    // Collect FCM tokens and send (ensure 'type' exists in data for client routing)
    const tokens = await fcmRepo.getTokensByUserIds(toUserIds);
    console.log(`🔔 Notification Debug - FCM tokens found: ${tokens.length}`);
    console.log(`🔔 Notification Debug - FCM tokens: ${JSON.stringify(tokens)}`);

    const dataWithType: Record<string, string> = { type: payload.type, ...payload.data };
    await this.notifier.sendToTokens(tokens, { type: payload.type, title: payload.title, body: payload.body, data: dataWithType });
  }

  async onPurchaseOrderCreated(po: PurchaseOrderResponse, language: string = 'ar'): Promise<void> {
    // Notify assistant and manager roles
    const roleIds = await userRepo.getUserIdsByRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]);
    const data = buildPONotificationData(po);
    await this.sendAndPersist(roleIds, {
      type: 'po_created',
      title: tl(language, 'notifications.purchaseOrder.newOrder', { number: po.number }),
      body: tl(language, 'notifications.purchaseOrder.newOrderBody', {
        requester: po.requester_name,
        department: po.department
      }),
      data,
    }, po);
  }

  async onStatusChanged(po: PurchaseOrderResponse, previous: PurchaseOrderStatus, next: PurchaseOrderStatus, language: string = 'ar'): Promise<void> {
    // Notify creator on any status change, with friendly messages
    const toUserIds = [po.created_by];
    const data = buildPONotificationData(po);

    let type = 'po_status_changed';
    let title = tl(language, 'notifications.purchaseOrder.statusChanged', { number: po.number });
    let body = `${previous} → ${next}`;

    switch (next) {
      case PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW:
        title = tl(language, 'notifications.purchaseOrder.sentToAssistant', { number: po.number });
        break;
      case PurchaseOrderStatus.UNDER_MANAGER_REVIEW:
        title = tl(language, 'notifications.purchaseOrder.sentToManager', { number: po.number });
        // Also notify managers about new order for review
        const roleIds = await userRepo.getUserIdsByRoles([UserRole.MANAGER]);
        await this.sendAndPersist(roleIds, {
          type: 'po_created',
          title: tl(language, 'notifications.purchaseOrder.newOrder', { number: po.number }),
          body: tl(language, 'notifications.purchaseOrder.newOrderBody', {
            requester: po.requester_name,
            department: po.department
          }),
          data,
        }, po);
        break;

      case PurchaseOrderStatus.UNDER_FINANCE_REVIEW: {
        title = tl(language, 'notifications.purchaseOrder.sentToFinance', { number: po.number });
        const financeIds = await userRepo.getUserIdsByRoles([UserRole.FINANCE_MANAGER]);
        await this.sendAndPersist(financeIds, { type: 'po_created', title, body: '', data }, po);
        break;
      }
      case PurchaseOrderStatus.UNDER_GENERAL_MANAGER_REVIEW: {
        title = tl(language, 'notifications.purchaseOrder.sentToGeneralManager', { number: po.number });
        const gmIds = await userRepo.getUserIdsByRoles([UserRole.GENERAL_MANAGER]);
        await this.sendAndPersist(gmIds, { type: 'po_created', title, body: '', data }, po);
        break;
      }
      case PurchaseOrderStatus.PENDING_PROCUREMENT: {
        title = tl(language, 'notifications.purchaseOrder.sentToProcurement', { number: po.number });
        const procIds = await userRepo.getUserIdsByRoles([UserRole.PROCUREMENT_OFFICER]);
        await this.sendAndPersist(procIds, { type: 'po_created', title, body: '', data }, po);
        break;
      }
      case PurchaseOrderStatus.RETURNED_TO_MANAGER_REVIEW: {
        title = tl(language, 'notifications.purchaseOrder.returnedToManager', { number: po.number });
        const mgrIds = await userRepo.getUserIdsByRoles([UserRole.MANAGER]);
        await this.sendAndPersist(mgrIds, { type: 'po_status_changed', title, body: '', data }, po);
        break;
      }

      case PurchaseOrderStatus.IN_PROGRESS:
        type = 'po_approved';
        title = tl(language, 'notifications.purchaseOrder.approved', { number: po.number });
        body = tl(language, 'notifications.purchaseOrder.approvedBody');
        break;
      case PurchaseOrderStatus.REJECTED_BY_ASSISTANT:
        type = 'po_rejected';
        title = tl(language, 'notifications.purchaseOrder.rejectedByAssistant', { number: po.number });
        body = '';
        break;
      case PurchaseOrderStatus.REJECTED_BY_MANAGER:
        type = 'po_rejected';
        title = tl(language, 'notifications.purchaseOrder.rejectedByManager', { number: po.number });
        body = '';
        break;
      case PurchaseOrderStatus.REJECTED_BY_FINANCE:
        type = 'po_rejected';
        title = tl(language, 'notifications.purchaseOrder.rejectedByFinance', { number: po.number });
        body = '';
        break;
      case PurchaseOrderStatus.REJECTED_BY_GENERAL_MANAGER:
        type = 'po_rejected';
        title = tl(language, 'notifications.purchaseOrder.rejectedByGeneralManager', { number: po.number });
        body = '';
        break;
      case PurchaseOrderStatus.COMPLETED:
        type = 'po_completed';
        title = tl(language, 'notifications.purchaseOrder.completed', { number: po.number });
        body = '';
        break;
      default:
        break;
    }

    await this.sendAndPersist(toUserIds, { type, title, body, data }, po);
  }
}