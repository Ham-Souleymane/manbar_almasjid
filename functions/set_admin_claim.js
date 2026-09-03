/**
 * Sets admin: true custom claim on a Firebase Auth user by email.
 * Uses firebase-admin with a service account key file.
 *
 * Usage:
 *   node set_admin_claim.js
 */

const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const email = 'guerchouhr@gmail.com';

admin.auth().getUserByEmail(email)
  .then((userRecord) => {
    const uid = userRecord.uid;
    console.log(`Found user: ${userRecord.email} (UID: ${uid})`);
    return admin.auth().setCustomUserClaims(uid, { admin: true });
  })
  .then(() => {
    console.log(`✅ Admin claim set successfully for: ${email}`);
    console.log('Have the user sign out and sign back in to pick up the new claim.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('❌ Failed to set claim:', err.message);
    process.exit(1);
  });
