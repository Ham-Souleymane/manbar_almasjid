const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

/**
 * 1. On new posts document creation:
 * - Read mosque followers and imam followers.
 * - Deduplicate user UIDs.
 * - Retrieve FCM tokens from follower docs or users profiles.
 * - Send a multicast FCM push notification.
 */
exports.onNewPostCreated = onDocumentCreated("posts/{postId}", async (event) => {
  const postId = event.params.postId;
  const postData = event.data.data();
  if (!postData) {
    logger.warn(`Post ${postId} has no data.`);
    return;
  }

  const { mosqueId, imamId, category, text } = postData;
  if (!mosqueId || !imamId) {
    logger.warn(`Post ${postId} is missing mosqueId (${mosqueId}) or imamId (${imamId}).`);
    return;
  }

  try {
    const uids = new Set();
    const tokens = new Set();

    // 1. Fetch mosque followers subcollection
    const mosqueFollowersSnap = await db
      .collection("mosques")
      .doc(mosqueId)
      .collection("followers")
      .get();
    
    mosqueFollowersSnap.forEach((doc) => {
      uids.add(doc.id);
      const token = doc.data().fcmToken || doc.data().token;
      if (token) tokens.add(token);
    });

    // 2. Fetch imam followers subcollection
    const imamFollowersSnap = await db
      .collection("imams")
      .doc(imamId)
      .collection("followers")
      .get();
    
    imamFollowersSnap.forEach((doc) => {
      uids.add(doc.id);
      const token = doc.data().fcmToken || doc.data().token;
      if (token) tokens.add(token);
    });

    // 3. For any user IDs that don't have a token cached in the followers document, fetch their user/worshipper document
    const missingUids = Array.from(uids).filter(uid => {
      return true; 
    });

    if (missingUids.length > 0) {
      const batchSize = 100;
      for (let i = 0; i < missingUids.length; i += batchSize) {
        const batchUids = missingUids.slice(i, i + batchSize);
        const userRefs = batchUids.map(uid => db.collection("users").doc(uid).get());
        const userSnaps = await Promise.all(userRefs);
        
        userSnaps.forEach(snap => {
          if (snap.exists) {
            const token = snap.data().fcmToken || snap.data().token;
            if (token) tokens.add(token);
          }
        });

        const worshipperRefs = batchUids.map(uid => db.collection("worshippers").doc(uid).get());
        const worshipperSnaps = await Promise.all(worshipperRefs);

        worshipperSnaps.forEach(snap => {
          if (snap.exists) {
            const token = snap.data().fcmToken || snap.data().token;
            if (token) tokens.add(token);
          }
        });
      }
    }

    const tokenList = Array.from(tokens).filter(t => typeof t === "string" && t.trim().length > 0);
    logger.info(`Found ${tokenList.length} unique FCM tokens for post ${postId}.`);

    if (tokenList.length === 0) {
      logger.info("No FCM tokens found. Skipping notification.");
      return;
    }

    // 4. Send multicast FCM notification
    const previewText = text && text.length > 80 ? text.substring(0, 80) + "..." : text;
    const message = {
      tokens: tokenList,
      notification: {
        title: `منشور جديد - تصنيف ${category || "إعلان"}`,
        body: previewText || "تصفح آخر الإعلانات والأنشطة المضافة حديثاً."
      },
      data: {
        postId: postId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(`Successfully sent ${response.successCount} notifications; failed ${response.failureCount}.`);
  } catch (error) {
    logger.error("Error in onNewPostCreated trigger:", error);
  }
});

/**
 * 2. On posts/{postId}/likes/{userId} create/delete:
 * - Update posts/{postId}.likeCount.
 */
exports.onPostLikeWritten = onDocumentWritten("posts/{postId}/likes/{userId}", async (event) => {
  const { postId } = event.params;
  const postRef = db.collection("posts").doc(postId);

  const beforeExists = event.data.before.exists;
  const afterExists = event.data.after.exists;

  try {
    if (!beforeExists && afterExists) {
      // Created
      logger.info(`Incrementing likeCount for post ${postId}`);
      await postRef.update({
        likeCount: admin.firestore.FieldValue.increment(1)
      });
    } else if (beforeExists && !afterExists) {
      // Deleted
      logger.info(`Decrementing likeCount for post ${postId}`);
      await postRef.update({
        likeCount: admin.firestore.FieldValue.increment(-1)
      });
    }
  } catch (error) {
    logger.error(`Error updating likeCount for post ${postId}:`, error);
  }
});

/**
 * 3. On posts/{postId}/comments/{commentId} create:
 * - Increment posts/{postId}.commentCount.
 * - Write history document to imams/{imamId}/notifications.
 * - Send FCM notification to the post's imam if commentsNotify !== false.
 */
exports.onPostCommentCreated = onDocumentCreated("posts/{postId}/comments/{commentId}", async (event) => {
  const { postId, commentId } = event.params;
  const commentData = event.data.data();
  if (!commentData) {
    logger.warn(`Comment ${commentId} has no data.`);
    return;
  }

  const postRef = db.collection("posts").doc(postId);

  try {
    // 1. Increment comment count
    logger.info(`Incrementing commentCount for post ${postId}`);
    await postRef.update({
      commentCount: admin.firestore.FieldValue.increment(1)
    });

    // 2. Fetch the post to get the imam's UID
    const postSnap = await postRef.get();
    if (!postSnap.exists) {
      logger.warn(`Post ${postId} does not exist. Cannot notify imam.`);
      return;
    }

    const { imamId, text: postText } = postSnap.data();
    if (!imamId) {
      logger.warn(`Post ${postId} does not contain an imamId.`);
      return;
    }

    // 3. Write in-app notification history document
    const commentatorName = commentData.userName || "مستخدم مجهول";
    const commentSnippet = commentData.text && commentData.text.length > 50 
      ? commentData.text.substring(0, 50) + "..." 
      : commentData.text;

    const notificationBody = `${commentatorName}: ${commentSnippet}`;

    await db.collection("imams").doc(imamId).collection("notifications").add({
      title: "تعليق جديد على منشورك",
      body: notificationBody,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      type: "comment",
      postId: postId,
      commentId: commentId,
      read: false
    });
    logger.info(`Wrote comment in-app notification history for imam ${imamId}`);

    // 4. Fetch the Imam's profile to get their FCM token & preferences
    const imamSnap = await db.collection("imams").doc(imamId).get();
    if (!imamSnap.exists) {
      logger.warn(`Imam ${imamId} profile not found.`);
      return;
    }

    const imamData = imamSnap.data();
    const commentsNotify = imamData.commentsNotify !== false;

    if (!commentsNotify) {
      logger.info(`Imam ${imamId} disabled comment notifications. Skipping FCM.`);
      return;
    }

    const token = imamData.fcmToken || imamData.token;
    if (!token) {
      logger.info(`Imam ${imamId} does not have an FCM token registered.`);
      return;
    }

    // 5. Send FCM notification to the Imam
    const message = {
      token: token,
      notification: {
        title: "تعليق جديد على منشورك",
        body: notificationBody
      },
      data: {
        postId: postId,
        commentId: commentId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    };

    await admin.messaging().send(message);
    logger.info(`Sent comment notification to imam ${imamId}.`);
  } catch (error) {
    logger.error("Error in onPostCommentCreated trigger:", error);
  }
});

/**
 * 4. On imams/{imamId} status field change to "verified":
 * - Write history document to imams/{imamId}/notifications.
 * - Send an FCM notification to that imam if verificationNotify !== false.
 */
exports.onImamStatusUpdated = onDocumentUpdated("imams/{imamId}", async (event) => {
  const { imamId } = event.params;
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (!beforeData || !afterData) {
    return;
  }

  // Check if status changed to verified
  if (beforeData.status !== "verified" && afterData.status === "verified") {
    try {
      const title = "تم توثيق حسابك";
      const body = "تهانينا! تم توثيق حسابك كإمام في التطبيق ويمكنك الآن النشر والمشاركة.";

      // 1. Write in-app notification history document
      await db.collection("imams").doc(imamId).collection("notifications").add({
        title: title,
        body: body,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        type: "verification",
        read: false
      });
      logger.info(`Wrote verification status in-app notification history for imam ${imamId}`);

      // 2. Respect preferences and FCM token
      const verificationNotify = afterData.verificationNotify !== false;
      if (!verificationNotify) {
        logger.info(`Imam ${imamId} disabled verification notifications. Skipping FCM.`);
        return;
      }

      const token = afterData.fcmToken || afterData.token;
      if (!token) {
        logger.info(`Imam ${imamId} status verified but no FCM token is registered.`);
        return;
      }

      const message = {
        token: token,
        notification: {
          title: title,
          body: body
        },
        data: {
          imamId: imamId,
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        }
      };

      await admin.messaging().send(message);
      logger.info(`Sent verification status notification to imam ${imamId}.`);
    } catch (error) {
      logger.error(`Error sending verification notification to imam ${imamId}:`, error);
    }
  }
});

/**
 * 5. Scheduled Cloud Function (runs daily at midnight):
 * - Loops through all mosques.
 * - Calls the Aladhan API using coordinates & calculationMethod.
 * - Writes result to mosques/{mosqueId}/prayerTimes/{yyyy-mm-dd}.
 */
exports.scheduledPrayerTimesFetch = onSchedule("0 0 * * *", async (event) => {
  logger.info("Starting scheduled daily prayer times fetch.");

  const now = new Date();
  const yyyy = now.getFullYear();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const dateYyyyMmDd = `${yyyy}-${mm}-${dd}`;
  const dateDdMmYyyy = `${dd}-${mm}-${yyyy}`;

  try {
    const mosquesSnap = await db.collection("mosques").get();
    logger.info(`Found ${mosquesSnap.size} mosques to process.`);

    const fetchPromises = [];

    mosquesSnap.forEach((mosqueDoc) => {
      const mosqueId = mosqueDoc.id;
      const mosqueData = mosqueDoc.data();
      const geopoint = mosqueData.geopoint;

      if (!geopoint || typeof geopoint.latitude !== "number" || typeof geopoint.longitude !== "number") {
        logger.warn(`Mosque ${mosqueId} has invalid or missing geopoint. Skipping.`);
        return;
      }

      const methodId = mosqueData.calculationMethod || 4;
      
      const p = async () => {
        try {
          logger.info(`Fetching prayer times for Mosque ${mosqueId} using method ${methodId}.`);
          
          const response = await axios.get(`https://api.aladhan.com/v1/timings/${dateDdMmYyyy}`, {
            params: {
              latitude: geopoint.latitude,
              longitude: geopoint.longitude,
              method: methodId
            },
            timeout: 10000
          });

          if (response.status !== 200 || !response.data || response.data.code !== 200) {
            throw new Error(`Aladhan API returned status ${response.status} or code ${response.data ? response.data.code : 'unknown'}`);
          }

          const timings = response.data.data.timings;
          
          const cleanTime = (raw) => {
            if (!raw) return null;
            return raw.trim().split(" ")[0];
          };

          const fajr = cleanTime(timings.Fajr);
          const dhuhr = cleanTime(timings.Dhuhr);
          const asr = cleanTime(timings.Asr);
          const maghrib = cleanTime(timings.Maghrib);
          const isha = cleanTime(timings.Isha);

          const dayDocRef = db
            .collection("mosques")
            .doc(mosqueId)
            .collection("prayerTimes")
            .doc(dateYyyyMmDd);

          const dayDocSnap = await dayDocRef.get();
          let useAutoCalculation = true;
          if (dayDocSnap.exists) {
            const currentData = dayDocSnap.data();
            if (currentData && currentData.useAutoCalculation !== undefined) {
              useAutoCalculation = currentData.useAutoCalculation;
            }
          }

          await dayDocRef.set({
            fajr,
            dhuhr,
            asr,
            maghrib,
            isha,
            calculationMethod: methodId,
            useAutoCalculation: useAutoCalculation,
            lastFetchedAt: admin.firestore.FieldValue.serverTimestamp()
          }, { merge: true });

          logger.info(`Successfully cached prayer times for mosque ${mosqueId} on date ${dateYyyyMmDd}.`);
        } catch (err) {
          logger.error(`Failed caching prayer times for mosque ${mosqueId}:`, err);
        }
      };

      fetchPromises.push(p());
    });

    await Promise.all(fetchPromises);
    logger.info("Finished scheduled daily prayer times fetch execution.");
  } catch (error) {
    logger.error("Error running scheduledPrayerTimesFetch:", error);
  }
});
