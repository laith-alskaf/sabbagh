import * as admin from 'firebase-admin';
import { serviceAccount } from './service-account';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export const messaging = admin.messaging();