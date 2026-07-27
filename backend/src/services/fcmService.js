import fs from 'fs';
import path from 'path';

let admin = null;
let isFirebaseInitialized = false;

async function initFirebaseAdmin() {
  try {
    const firebaseAdminModule = await import('firebase-admin');
    admin = firebaseAdminModule.default || firebaseAdminModule;

    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || path.join(process.cwd(), 'serviceAccountKey.json');
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount)
        });
      }
      isFirebaseInitialized = true;
      console.log('✅ Firebase Admin SDK initialized successfully for Real-time FCM Push Notifications.');
    } else {
      console.log('⚠️ serviceAccountKey.json not found in backend root. FCM push notifications will be logged to console until configured.');
    }
  } catch (error) {
    console.log('⚠️ firebase-admin package or credentials status:', error.message);
  }
}

// Initializing in background
initFirebaseAdmin();

/**
 * Sends a real-time FCM Push Notification to a user's mobile device.
 * 
 * @param {string} fcmToken - The target user's FCM device token.
 * @param {string} title - The notification title.
 * @param {string} body - The notification message payload.
 * @param {Object} [dataPayload] - Optional key-value data payload.
 */
export const sendFcmNotification = async (fcmToken, title, body, dataPayload = {}) => {
  if (!fcmToken) return;

  if (isFirebaseInitialized && admin) {
    try {
      const message = {
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: {
          ...dataPayload,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'campus_swap_channel',
          },
        },
      };
      const response = await admin.messaging().send(message);
      console.log('🚀 FCM Push Notification sent successfully:', response);
    } catch (error) {
      console.error('❌ FCM Push Error:', error.message);
    }
  } else {
    console.log(`📱 [FCM Push Simulation] Target Token [${fcmToken.substring(0, 10)}...]: "${title}" - "${body}"`);
  }
};
