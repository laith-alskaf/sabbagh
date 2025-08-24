import { PurchaseOrderResponse } from '../types/purchaseOrder';
import { PurchaseOrderStatus, UserRole } from '../types/models';
import * as notifRepo from '../repositories/notificationRepository';
import * as userRepo from '../repositories/userRepository';
import * as fcmRepo from '../repositories/fcmTokenRepository';
import { buildPONotificationData, INotificationService } from '../utils/notification.service';

export class NotificationOrchestrator {
  constructor(private notifier: INotificationService) {}

  private async sendAndPersist(toUserIds: string[], payload: { type: string; title: string; body?: string; data: Record<string, string> }, po: PurchaseOrderResponse) {
    // Persist per-user notification
    await Promise.all(
      toUserIds.map((uid) => notifRepo.insert(uid, payload.type, payload.title, payload.body ?? null, { po }))
    );
    // Collect FCM tokens and send
    const tokens = await fcmRepo.getTokensByUserIds(toUserIds);
    await this.notifier.sendToTokens(tokens, { type: payload.type, title: payload.title, body: payload.body, data: payload.data });
  }

  async onPurchaseOrderCreated(po: PurchaseOrderResponse): Promise<void> {
    // Notify assistant and manager roles
    const roleIds = await userRepo.getUserIdsByRoles([UserRole.ASSISTANT_MANAGER, UserRole.MANAGER]);
    const data = buildPONotificationData(po) as unknown as Record<string, string>;
    await this.sendAndPersist(roleIds, {
      type: 'po_created',
      title: `طلب شراء جديد ${po.number}`,
      body: `${po.requester_name} (${po.department})` ,
      data,
    }, po);
  }

  async onStatusChanged(po: PurchaseOrderResponse, previous: PurchaseOrderStatus): Promise<void> {
    // Notify creator on any status change, with friendly Arabic messages
    const toUserIds = [po.created_by];
    const data = buildPONotificationData(po) as unknown as Record<string, string>;

    let type = 'po_status_changed';
    let title = `تغيير حالة الطلب ${po.number}`;
    let body = `${previous} → ${po.status}`;

    switch (po.status) {
      case PurchaseOrderStatus.UNDER_ASSISTANT_REVIEW:
        title = `تم إرسال الطلب ${po.number} للمساعد للمراجعة`;
        break;
      case PurchaseOrderStatus.UNDER_MANAGER_REVIEW:
        title = `تم إرسال الطلب ${po.number} للمدير للمراجعة`;
        break;
      case PurchaseOrderStatus.IN_PROGRESS:
        type = 'po_approved';
        title = `تمت الموافقة على الطلب ${po.number}`;
        body = `يباشر التنفيذ`;
        break;
      case PurchaseOrderStatus.REJECTED_BY_ASSISTANT:
        type = 'po_rejected';
        title = `تم رفض الطلب ${po.number} من المساعد`;
        body = '';
        break;
      case PurchaseOrderStatus.REJECTED_BY_MANAGER:
        type = 'po_rejected';
        title = `تم رفض الطلب ${po.number} من المدير`;
        body = '';
        break;
      case PurchaseOrderStatus.COMPLETED:
        type = 'po_completed';
        title = `اكتمل تنفيذ الطلب ${po.number}`;
        body = '';
        break;
      default:
        break;
    }

    await this.sendAndPersist(toUserIds, { type, title, body, data }, po);
  }
}