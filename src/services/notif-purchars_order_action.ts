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
    console.log(`🚀 FCM Debug - Attempting to send to ${tokens.length} tokens`);
    console.log(`🚀 FCM Debug - Payload: ${JSON.stringify(payload)}`);
    
    if (!tokens.length) {
      console.log('🚀 FCM Debug - No tokens provided, skipping');
      return;
    }

    // FCM limit for tokens in multicast is 500
    const batches = this.chunk(Array.from(new Set(tokens)), 500);
    console.log(`🚀 FCM Debug - Split into ${batches.length} batches`);

    for (const batch of batches) {
      const message: any = {
        tokens: batch,
        notification: {
          title: payload.title,
          body: payload.body || undefined,
        },
        data: payload.data || undefined,
      };

      console.log(`🚀 FCM Debug - Sending batch with ${batch.length} tokens`);
      console.log(`🚀 FCM Debug - Message: ${JSON.stringify(message)}`);

      try {
        const resp = await messaging.sendEachForMulticast(message);
        console.log(`🚀 FCM Debug - Response: successCount=${resp.successCount}, failureCount=${resp.failureCount}`);
        
        // Collect invalid tokens and remove them
        const invalidTokens: string[] = [];
        resp.responses.forEach((r, idx) => {
          if (!r.success) {
            console.log(`🚀 FCM Debug - Failed token ${batch[idx]}: ${r.error?.message}`);
            const code = (r.error as any)?.code as string | undefined;
            if (code && (
              code.includes('registration-token-not-registered') ||
              code.includes('invalid-argument') ||
              code.includes('invalid-registration-token')
            )) {
              invalidTokens.push(batch[idx]);
            }
          } else {
            console.log(`🚀 FCM Debug - Success for token ${batch[idx]}`);
          }
        });
        if (invalidTokens.length) {
          console.log(`🚀 FCM Debug - Removing ${invalidTokens.length} invalid tokens`);
          try { await fcmRepo.removeTokensByValues(invalidTokens); } catch {}
        }
      } catch (error) {
        console.error('🚀 FCM Debug - Error sending FCM notification:', error);
      }
    }
  }
}