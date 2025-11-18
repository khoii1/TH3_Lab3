const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * Cloud Function tối ưu:
 * Tự động cập nhật avgRating và ratingCount của nhà hàng
 * mỗi khi có CREATE / UPDATE / DELETE review:
 *
 *   restaurants/{restaurantId}/reviews/{reviewId}
 */
exports.onReviewWrite = functions.firestore
  .document("restaurants/{restaurantId}/reviews/{reviewId}")
  .onWrite(async (change, context) => {
    const { restaurantId } = context.params;
    const restaurantRef = db.collection("restaurants").doc(restaurantId);

    return db.runTransaction(async (tx) => {
      const restaurantSnap = await tx.get(restaurantRef);

      if (!restaurantSnap.exists) {
        console.log("Restaurant không tồn tại, bỏ qua.");
        return;
      }

      const data = restaurantSnap.data() || {};
      let avgRating = typeof data.avgRating === "number" ? data.avgRating : 0;
      let ratingCount =
        typeof data.ratingCount === "number" ? data.ratingCount : 0;

      // Lấy rating cũ và mới
      let oldRating = null;
      let newRating = null;

      if (change.before.exists) {
        const beforeData = change.before.data() || {};
        if (typeof beforeData.rating === "number") {
          oldRating = beforeData.rating;
        }
      }

      if (change.after.exists) {
        const afterData = change.after.data() || {};
        if (typeof afterData.rating === "number") {
          newRating = afterData.rating;
        }
      }

      // Trường hợp 1: CREATE (before không tồn tại, after tồn tại)
      if (!change.before.exists && change.after.exists && newRating != null) {
        const newCount = ratingCount + 1;
        const newAvg = (avgRating * ratingCount + newRating) / newCount;

        ratingCount = newCount;
        avgRating = newAvg;
        console.log("CREATE review, rating =", newRating);
      }

      // Trường hợp 2: DELETE (before tồn tại, after không tồn tại)
      else if (
        change.before.exists &&
        !change.after.exists &&
        oldRating != null
      ) {
        const newCount = Math.max(0, ratingCount - 1);
        let newAvg = 0;

        if (newCount > 0) {
          newAvg = (avgRating * ratingCount - oldRating) / newCount;
        }

        ratingCount = newCount;
        avgRating = newAvg;
        console.log("DELETE review, rating =", oldRating);
      }

      // Trường hợp 3: UPDATE (cả before & after đều tồn tại)
      else if (
        change.before.exists &&
        change.after.exists &&
        oldRating != null &&
        newRating != null &&
        oldRating !== newRating
      ) {
        // Tổng điểm cũ = avg * count
        const total = avgRating * ratingCount;
        // Trừ rating cũ, cộng rating mới
        const newTotal = total - oldRating + newRating;
        const newAvg = ratingCount > 0 ? newTotal / ratingCount : 0;

        avgRating = newAvg;
        console.log(
          "UPDATE review, rating cũ =",
          oldRating,
          ", rating mới =",
          newRating
        );
      } else {
        // Không có thay đổi rating hợp lệ
        console.log("Không có thay đổi rating hợp lệ, bỏ qua.");
        return;
      }

      tx.update(restaurantRef, {
        avgRating,
        ratingCount,
      });

      console.log(
        `Đã cập nhật restaurant ${restaurantId}: avgRating=${avgRating.toFixed(
          2
        )}, ratingCount=${ratingCount}`
      );
    });
  });
