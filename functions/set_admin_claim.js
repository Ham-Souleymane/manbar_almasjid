/**
 * Sets admin: true custom claim on a Firebase Auth user.
 * Uses firebase-admin with a service account key file.
 *
 * Usage:
 *   1. Download your service account key from Firebase Console:
 *      Project Settings → Service Accounts → Generate new private key
 *      Save it as serviceAccountKey.json in this (functions/) directory.
 *   2. node set_admin_claim.js
 */

const path = require('path');
const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const uid = '720O4oueb6apcxzRflOaBohKJWi2';

admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log(`\u2705 Admin claim set successfully for UID: ${uid}`);
    console.log('Have the user sign out and sign back in to pick up the new claim.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('\u274C Failed to set claim:', err.message);
    process.exit(1);
  });
