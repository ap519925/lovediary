const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.password,
  },
});

exports.onNewRelationshipRequest = functions.firestore
    .document("relationship_requests/{requestId}")
    .onCreate(async (snapshot, context) => {
      const requestData = snapshot.data();
      const fromUserId = requestData.fromUserId;
      const toUserId = requestData.toUserId;
      const requestId = context.params.requestId;

      const [fromUserDoc, toUserDoc] = await Promise.all([
        db.collection("users").doc(fromUserId).get(),
        db.collection("users").doc(toUserId).get(),
      ]);

      const fromUserData = fromUserDoc.data();
      const toUserData = toUserDoc.data();

      if (!fromUserData || !toUserData) {
        console.error(
            "Missing user data for notification. Sender or receiver not found.",
        );
        return null;
      }

      // Replace optional chaining with ternary operator for compatibility
      const fromUserDisplayName =
      (fromUserData.profile && fromUserData.profile.displayName) ?
        fromUserData.profile.displayName :
        "A user";
      const toUserEmail = toUserData.email;
      const toUserFCMToken = toUserData.fcmToken;

      if (toUserEmail) {
        const mailOptions = {
          from: functions.config().email.user,
          to: toUserEmail,
          subject: `New Relationship Request from ${fromUserDisplayName} ` +
          `on Love Diary!`,
          html: `
          <p>Hello,</p>
          <p>You have received a new relationship request on Love Diary ` +
          `from <strong>${fromUserDisplayName}</strong>.</p>
          <p>Log in to the app to accept or decline the request.</p>
          <p>Best regards,</p>
          <p>The Love Diary Team</p>
        `,
        };
        try {
          await transporter.sendMail(mailOptions);
          console.log(`Email sent to ${toUserEmail}`);
        } catch (error) {
          console.error("Error sending email:", error);
        }
      }

      if (toUserFCMToken) {
        const payload = {
          notification: {
            title: "New Relationship Request!",
            body:
            `You received a request from ${fromUserDisplayName}. ` +
            `Tap to link!`,
          },
          data: {
            type: "RELATIONSHIP_REQUEST",
            requestId: requestId,
            fromUserId: fromUserId,
          },
        };

        try {
          await admin.messaging().sendToDevice(toUserFCMToken, payload);
          console.log(`FCM notification sent to ${toUserId}`);
        } catch (error) {
          console.error("Error sending FCM message:", error);
        }
      }

      return null;
    });
