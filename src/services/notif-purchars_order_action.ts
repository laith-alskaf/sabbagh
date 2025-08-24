import { messaging } from "../config/firebase";
import { INotificationService, NotificationPayload } from "../utils/notification.service";
import * as fcmRepo from '../repositories/fcmTokenRepository';

export class PurchaseOrderNotifier implements INotificationService {
  // Batch tokens to avoid exceeding FCM limits and prune invalid tokens automatically
  private chunk<T>(arr: T[], size: number): T[][] {
    const out: T[][] = [];
    for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
    return out;
  }

  async sendToTokens(tokens: string[], payload: NotificationPayload): Promise<void> {
    if (!tokens.length) return;

    // FCM limit for tokens in multicast is 500
    const batches = this.chunk(Array.from(new Set(tokens)), 500);

    for (const batch of batches) {
      const message: any = {
        tokens: batch,
        notification: {
          title: payload.title,
          body: payload.body || undefined,
        },
        data: payload.data || undefined,
      };

      try {
        const resp = await messaging.sendEachForMulticast(message);
        // Collect invalid tokens and remove them
        const invalidTokens: string[] = [];
        resp.responses.forEach((r, idx) => {
          if (!r.success) {
            const code = (r.error as any)?.code as string | undefined;
            if (code && (
              code.includes('registration-token-not-registered') ||
              code.includes('invalid-argument') ||
              code.includes('invalid-registration-token')
            )) {
              invalidTokens.push(batch[idx]);
            }
          }
        });
        if (invalidTokens.length) {
          try { await fcmRepo.removeTokensByValues(invalidTokens); } catch {}
        }
      } catch (error) {
        console.error('Error sending FCM notification:', error);
      }
    }
  }
}