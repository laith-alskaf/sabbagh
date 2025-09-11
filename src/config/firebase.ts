import * as admin from 'firebase-admin';
import { serviceAccount } from './service-account';

console.log('🔥 Firebase Debug - Initializing Firebase Admin SDK');
console.log('🔥 Firebase Debug - Project ID:', (serviceAccount as any).project_id);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

console.log('🔥 Firebase Debug - Firebase Admin SDK initialized successfully');

export const messaging = admin.messaging();