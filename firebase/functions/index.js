const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentWritten, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

// ========================================
// 1. 헬스체크 함수
// ========================================
exports.healthCheck = onRequest((req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date().toISOString(),
    message: "Philfomation API is running",
  });
});

// ========================================
// 1-1. 테스트 푸시 알림 전송
// ========================================
exports.sendTestNotification = onRequest(async (req, res) => {
  // CORS 헤더
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  const { userId, title, body } = req.body;

  if (!userId) {
    res.status(400).json({ error: "userId is required" });
    return;
  }

  try {
    // 사용자 FCM 토큰 가져오기
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      res.status(404).json({ error: "User not found" });
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      res.status(400).json({ error: "FCM token not found for user" });
      return;
    }

    // 테스트 푸시 알림 전송
    const notification = {
      token: fcmToken,
      notification: {
        title: title || "테스트 알림",
        body: body || "푸시 알림이 정상적으로 작동합니다!",
      },
      data: {
        type: "test",
        timestamp: new Date().toISOString(),
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    const response = await getMessaging().send(notification);
    console.log(`Test notification sent to ${userId}: ${response}`);

    res.json({
      success: true,
      message: "Test notification sent successfully",
      messageId: response,
    });
  } catch (error) {
    console.error("Error sending test notification:", error);
    res.status(500).json({
      error: "Failed to send notification",
      details: error.message,
    });
  }
});

// ========================================
// 2. 신규 사용자 처리
// ========================================
exports.onUserCreate = onDocumentCreated("users/{userId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const userData = snapshot.data();
  console.log(`New user created: ${userData.name} (${userData.email})`);

  // 환영 알림 등 추가 로직 가능
});

// ========================================
// 3. 1:1 채팅 푸시 알림
// ========================================
exports.onNewMessage = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const message = snapshot.data();
  const chatId = event.params.chatId;

  try {
    // 채팅 정보 가져오기
    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) return;

    const chat = chatDoc.data();
    const participants = chat.participants || [];

    // 발신자 제외한 수신자 찾기
    const receiverId = participants.find((id) => id !== message.senderId);
    if (!receiverId) return;

    // 수신자 정보 가져오기
    const receiverDoc = await db.collection("users").doc(receiverId).get();
    if (!receiverDoc.exists) return;

    const receiver = receiverDoc.data();
    const fcmToken = receiver.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user: ${receiverId}`);
      return;
    }

    // 푸시 알림 전송
    const notification = {
      token: fcmToken,
      notification: {
        title: message.senderName || "새 메시지",
        body: message.text || "[이미지]",
      },
      data: {
        type: "chat",
        chatId: chatId,
        senderId: message.senderId,
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    await getMessaging().send(notification);
    console.log(`Push notification sent to ${receiverId}`);
  } catch (error) {
    console.error("Error sending push notification:", error);
  }
});

// ========================================
// 4. 단톡방 푸시 알림
// ========================================
exports.onNewRoomMessage = onDocumentCreated("chatRooms/{roomId}/messages/{messageId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const message = snapshot.data();
  const roomId = event.params.roomId;

  try {
    // 단톡방 멤버 가져오기
    const membersSnapshot = await db.collection("chatRooms").doc(roomId).collection("members").get();

    // 단톡방 정보 가져오기
    const roomDoc = await db.collection("chatRooms").doc(roomId).get();
    const roomName = roomDoc.exists ? roomDoc.data().name : "단톡방";

    // 발신자 제외한 모든 멤버에게 알림 전송
    const sendPromises = [];

    for (const memberDoc of membersSnapshot.docs) {
      const member = memberDoc.data();
      if (member.userId === message.senderId) continue;

      // 멤버의 FCM 토큰 가져오기
      const userDoc = await db.collection("users").doc(member.userId).get();
      if (!userDoc.exists) continue;

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) continue;

      const notification = {
        token: fcmToken,
        notification: {
          title: `${roomName}`,
          body: `${message.senderName}: ${message.text || "[이미지]"}`,
        },
        data: {
          type: "chatRoom",
          roomId: roomId,
          senderId: message.senderId,
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: "default",
            },
          },
        },
      };

      sendPromises.push(getMessaging().send(notification));
    }

    await Promise.all(sendPromises);
    console.log(`Push notifications sent to ${sendPromises.length} members`);
  } catch (error) {
    console.error("Error sending room push notifications:", error);
  }
});

// ========================================
// 5. 게시글 댓글 푸시 알림
// ========================================
exports.onNewComment = onDocumentCreated("comments/{commentId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const comment = snapshot.data();
  const postId = comment.postId;

  try {
    // 게시글 정보 가져오기
    const postDoc = await db.collection("posts").doc(postId).get();
    if (!postDoc.exists) return;

    const post = postDoc.data();

    // 자기 게시글에 댓글 단 경우 알림 안 보냄
    if (post.authorId === comment.authorId) return;

    // 게시글 작성자 정보 가져오기
    const authorDoc = await db.collection("users").doc(post.authorId).get();
    if (!authorDoc.exists) return;

    const author = authorDoc.data();
    const fcmToken = author.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user: ${post.authorId}`);
      return;
    }

    // 푸시 알림 전송
    const notification = {
      token: fcmToken,
      notification: {
        title: "새 댓글",
        body: `${comment.authorName}님이 "${post.title}"에 댓글을 남겼습니다.`,
      },
      data: {
        type: "comment",
        postId: postId,
        commentId: event.params.commentId,
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    await getMessaging().send(notification);
    console.log(`Comment notification sent to ${post.authorId}`);
  } catch (error) {
    console.error("Error sending comment notification:", error);
  }
});

// ========================================
// 6. 게시글 좋아요 푸시 알림
// ========================================
exports.onNewLike = onDocumentCreated("likes/{likeId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const like = snapshot.data();

  // 게시글 좋아요만 처리 (targetType이 있는 경우)
  if (like.targetType !== "post") return;

  const postId = like.targetId;

  try {
    // 게시글 정보 가져오기
    const postDoc = await db.collection("posts").doc(postId).get();
    if (!postDoc.exists) return;

    const post = postDoc.data();

    // 자기 게시글에 좋아요한 경우 알림 안 보냄
    if (post.authorId === like.userId) return;

    // 게시글 작성자 정보 가져오기
    const authorDoc = await db.collection("users").doc(post.authorId).get();
    if (!authorDoc.exists) return;

    const author = authorDoc.data();
    const fcmToken = author.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user: ${post.authorId}`);
      return;
    }

    // 푸시 알림 전송
    const notification = {
      token: fcmToken,
      notification: {
        title: "좋아요",
        body: `${like.userName || "누군가"}님이 "${post.title}"을 좋아합니다.`,
      },
      data: {
        type: "like",
        postId: postId,
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    await getMessaging().send(notification);
    console.log(`Like notification sent to ${post.authorId}`);
  } catch (error) {
    console.error("Error sending like notification:", error);
  }
});

// ========================================
// 7. 리뷰 생성/삭제 시 평점 자동 계산
// ========================================
exports.updateBusinessRating = onDocumentWritten("reviews/{reviewId}", async (event) => {
  const beforeData = event.data.before?.data();
  const afterData = event.data.after?.data();

  // 삭제된 경우 이전 데이터에서 businessId 가져오기
  const businessId = afterData?.businessId || beforeData?.businessId;
  if (!businessId) return;

  try {
    // 해당 업소의 모든 리뷰 가져오기
    const reviewsSnapshot = await db
      .collection("reviews")
      .where("businessId", "==", businessId)
      .get();

    let totalRating = 0;
    let reviewCount = 0;

    reviewsSnapshot.forEach((doc) => {
      const review = doc.data();
      totalRating += review.rating || 0;
      reviewCount++;
    });

    const averageRating = reviewCount > 0 ? totalRating / reviewCount : 0;

    // 업소 평점 업데이트
    await db.collection("businesses").doc(businessId).update({
      rating: Math.round(averageRating * 10) / 10, // 소수점 1자리
      reviewCount: reviewCount,
      updatedAt: FieldValue.serverTimestamp(),
    });

    console.log(`Updated business ${businessId}: rating=${averageRating}, reviews=${reviewCount}`);
  } catch (error) {
    console.error("Error updating business rating:", error);
  }
});

// ========================================
// 6. 단톡방 멤버 수 자동 업데이트
// ========================================
exports.updateChatRoomMemberCount = onDocumentWritten("chatRooms/{roomId}/members/{memberId}", async (event) => {
  const roomId = event.params.roomId;

  try {
    // 현재 멤버 수 계산
    const membersSnapshot = await db
      .collection("chatRooms")
      .doc(roomId)
      .collection("members")
      .get();

    const memberCount = membersSnapshot.size;

    // 단톡방 멤버 수 업데이트
    await db.collection("chatRooms").doc(roomId).update({
      memberCount: memberCount,
      updatedAt: FieldValue.serverTimestamp(),
    });

    console.log(`Updated chatRoom ${roomId}: memberCount=${memberCount}`);
  } catch (error) {
    console.error("Error updating member count:", error);
  }
});

// ========================================
// 7. 단톡방 삭제 시 멤버 0명이면 자동 삭제
// ========================================
exports.cleanupEmptyChatRoom = onDocumentDeleted("chatRooms/{roomId}/members/{memberId}", async (event) => {
  const roomId = event.params.roomId;

  try {
    const membersSnapshot = await db
      .collection("chatRooms")
      .doc(roomId)
      .collection("members")
      .limit(1)
      .get();

    // 멤버가 없으면 단톡방 삭제
    if (membersSnapshot.empty) {
      // 메시지 서브컬렉션 삭제
      const messagesSnapshot = await db
        .collection("chatRooms")
        .doc(roomId)
        .collection("messages")
        .get();

      const batch = db.batch();
      messagesSnapshot.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();

      // 단톡방 문서 삭제
      await db.collection("chatRooms").doc(roomId).delete();
      console.log(`Deleted empty chatRoom: ${roomId}`);
    }
  } catch (error) {
    console.error("Error cleaning up empty chat room:", error);
  }
});
