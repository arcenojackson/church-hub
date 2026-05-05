import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

const REGION = "southamerica-east1";

const db = admin.firestore();

// ─────────────────────────────────────────────
// INTERFACES
// ─────────────────────────────────────────────

interface ChatMessage {
  text: string;
  userId: string;
  userName: string;
  mentionedUserIds?: string[];
}

interface UserData {
  name: string;
  email: string;
  fcmToken?: string;
  churchId?: string;
  disabledNotifications?: string[];
}

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────

/**
 * Sends a push notification to multiple FCM tokens.
 * @param {string[]} tokens - FCM device tokens.
 * @param {string} title - Notification title.
 * @param {string} body - Notification body.
 * @param {Record<string, string>} data - Custom data payload.
 */
async function sendPush(
    tokens: string[],
    title: string,
    body: string,
    data: Record<string, string>
): Promise<void> {
  if (tokens.length === 0) return;

  const payload: admin.messaging.MulticastMessage = {
    notification: {title, body},
    data,
    tokens,
    android: {priority: "high"},
    apns: {payload: {aps: {sound: "default", badge: 1}}},
  };

  const response = await admin.messaging().sendMulticast(payload);
  console.log(`Push sent: ${response.successCount}/${tokens.length}`);
}

/**
 * Returns FCM tokens for users who have not disabled a notification type.
 * @param {string[]} userIds - List of user IDs to query.
 * @param {string} notificationType - Notification type key to check.
 * @return {Promise<string[]>} Active FCM tokens.
 */
async function getActiveTokens(
    userIds: string[],
    notificationType: string
): Promise<string[]> {
  const tokens: string[] = [];
  const docs = await Promise.all(
      userIds.map((id) => db.collection("users").doc(id).get())
  );

  docs.forEach((doc) => {
    if (!doc.exists) return;
    const data = doc.data() as UserData;
    if (!data.fcmToken) return;
    const disabled = data.disabledNotifications || [];
    if (!disabled.includes(notificationType)) {
      tokens.push(data.fcmToken);
    }
  });

  return tokens;
}

// ─────────────────────────────────────────────
// TRIGGER: Chat mention notifications
// ─────────────────────────────────────────────

export const onMessageCreated = functions.region(REGION).firestore
    .document("churches/{churchId}/events/{eventId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
      const message = snapshot.data() as ChatMessage;
      const {churchId, eventId, messageId} = context.params;

      if (!message.mentionedUserIds?.length) return null;

      const eventDoc = await db
          .collection("churches").doc(churchId)
          .collection("events").doc(eventId)
          .get();
      const eventName = eventDoc.data()?.name || "Evento";

      const tokens = await getActiveTokens(
          message.mentionedUserIds,
          "chat_mention"
      );

      await sendPush(
          tokens.filter((t) => t !== message.userId),
          `@${message.userName} te mencionou`,
          `${eventName}: ${message.text.substring(0, 80)}`,
          {
            type: "chat_mention",
            churchId,
            eventId,
            messageId,
            senderId: message.userId,
            senderName: message.userName,
          }
      );

      return null;
    });

export const onSocietyMessageCreated = functions.region(REGION).firestore
    .document("churches/{churchId}/societies/{societyId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
      const message = snapshot.data() as ChatMessage;
      const {churchId, societyId, messageId} = context.params;

      if (!message.mentionedUserIds?.length) return null;

      const societyDoc = await db
          .collection("churches").doc(churchId)
          .collection("societies").doc(societyId)
          .get();
      const societyName = societyDoc.data()?.name || "Grupo";

      const tokens = await getActiveTokens(
          message.mentionedUserIds,
          "chat_mention"
      );

      await sendPush(
          tokens.filter((t) => t !== message.userId),
          `@${message.userName} te mencionou`,
          `${societyName}: ${message.text.substring(0, 80)}`,
          {
            type: "society_chat_mention",
            churchId,
            societyId,
            messageId,
            senderId: message.userId,
          }
      );

      return null;
    });

// ─────────────────────────────────────────────
// TRIGGER: Event scale notifications
// ─────────────────────────────────────────────

export const onServicePeopleUpdated = functions.region(REGION).firestore
    .document("churches/{churchId}/events/{eventId}")
    .onUpdate(async (change, context) => {
      const {churchId, eventId} = context.params;

      const before = change.before.data();
      const after = change.after.data();

      if (JSON.stringify(before.people) === JSON.stringify(after.people)) {
        return null;
      }

      // Coletar todos os IDs que foram ADICIONADOS
      const addedIds = new Set<string>();
      const afterPeople = after.people || {};
      const beforePeople = before.people || {};

      for (const roleId of Object.keys(afterPeople)) {
        const afterList: string[] = afterPeople[roleId] || [];
        const beforeList: string[] = beforePeople[roleId] || [];
        afterList.forEach((uid) => {
          if (!beforeList.includes(uid)) addedIds.add(uid);
        });
      }

      if (addedIds.size === 0) return null;

      const eventName = after.name || "Evento";
      const dateStr = after.date?.toDate?.()
          ?.toLocaleDateString("pt-BR") || "";

      const tokens = await getActiveTokens(
          Array.from(addedIds),
          "scale_inclusion"
      );

      await sendPush(
          tokens,
          "Você foi escalado!",
          `${eventName}${dateStr ? ` - ${dateStr}` : ""}`,
          {type: "scale_inclusion", churchId, eventId}
      );

      return null;
    });

export const onServiceStepsUpdated = functions.region(REGION).firestore
    .document("churches/{churchId}/events/{eventId}")
    .onUpdate(async (change, context) => {
      const {churchId, eventId} = context.params;

      const before = change.before.data();
      const after = change.after.data();

      if (JSON.stringify(before.steps) === JSON.stringify(after.steps)) {
        return null;
      }

      // Notificar todos os membros escalados
      const afterPeople = after.people || {};
      const allIds = new Set<string>();
      for (const list of Object.values(afterPeople) as string[][]) {
        list.forEach((id) => allIds.add(id));
      }

      if (allIds.size === 0) return null;

      const tokens = await getActiveTokens(
          Array.from(allIds),
          "music_update"
      );

      await sendPush(
          tokens,
          "Roteiro atualizado",
          `${after.name || "Evento"} teve seu roteiro atualizado`,
          {type: "music_update", churchId, eventId}
      );

      return null;
    });

// ─────────────────────────────────────────────
// TRIGGER: Church created
// ─────────────────────────────────────────────

export const onChurchCreated = functions.region(REGION).firestore
    .document("churches/{churchId}")
    .onCreate(async (snapshot, context) => {
      const {churchId} = context.params;
      console.log(`New church created: ${churchId}`);

      // Criar documento de assinatura padrão (free tier)
      await db
          .collection("churches").doc(churchId)
          .collection("subscription").doc("current")
          .set({
            tier: "free",
            userLimit: 30,
            billingStatus: "active",
            billingCycle: "free",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

      return null;
    });

// ─────────────────────────────────────────────
// TRIGGER: Subscription changed
// ─────────────────────────────────────────────

export const onSubscriptionChanged = functions.region(REGION).firestore
    .document("churches/{churchId}/subscription/current")
    .onUpdate(async (change, context) => {
      const {churchId} = context.params;
      const before = change.before.data();
      const after = change.after.data();

      if (before.tier === after.tier) return null;

      console.log(
          `Church ${churchId} tier changed: ${before.tier} → ${after.tier}`
      );

      // Atualizar tier no documento principal da igreja
      await db.collection("churches").doc(churchId).update({
        tier: after.tier,
      });

      return null;
    });

// ─────────────────────────────────────────────
// SCHEDULED: Daily reminders (every 6 hours)
// ─────────────────────────────────────────────

export const dailyReminders = functions
    .region(REGION)
    .pubsub.schedule("0 */6 * * *")
    .timeZone("America/Sao_Paulo")
    .onRun(async () => {
      console.log("Running daily reminders check...");

      const now = new Date();

      // Buscar todas as igrejas ativas
      const churchesSnap = await db
          .collection("churches")
          .where("setupCompleted", "==", true)
          .get();

      console.log(`Processing ${churchesSnap.size} churches`);

      for (const churchDoc of churchesSnap.docs) {
        const churchId = churchDoc.id;

        try {
        // Buscar configurações de lembretes da igreja
          const settingsDoc = await db
              .collection("churches").doc(churchId)
              .collection("settings").doc("config")
              .get();

          if (!settingsDoc.exists) continue;

          const settings = settingsDoc.data() || {};
          const reminderRules = settings.reminderRules || {};

          for (const [ruleId, rule] of Object.entries(reminderRules)) {
            const ruleData = rule as {
            type: string;
            daysBeforeEvent: number;
            message?: string;
          };

            await processReminderRule(churchId, ruleId, ruleData, now);
          }
        } catch (e) {
          console.error(`Error processing reminders for church ${churchId}:`,
              e);
        }
      }

      return null;
    });

/**
 * Processes a single reminder rule for a church and sends push notifications.
 * @param {string} churchId - The church document ID.
 * @param {string} ruleId - The reminder rule ID.
 * @param {Object} rule - Rule configuration object.
 * @param {Date} now - Current date reference.
 */
async function processReminderRule(
    churchId: string,
    ruleId: string,
    rule: {type: string; daysBeforeEvent: number; message?: string},
    now: Date
): Promise<void> {
  const targetDate = new Date(now);
  targetDate.setDate(now.getDate() + rule.daysBeforeEvent);
  targetDate.setHours(0, 0, 0, 0);

  const targetEnd = new Date(targetDate);
  targetEnd.setHours(23, 59, 59, 999);

  if (rule.type === "elo_availability") {
    // Lembrar membros ELO de confirmar disponibilidade
    const eventsSnap = await db
        .collection("churches").doc(churchId)
        .collection("events")
        .where("date", ">=", admin.firestore.Timestamp.fromDate(targetDate))
        .where("date", "<=", admin.firestore.Timestamp.fromDate(targetEnd))
        .get();

    if (eventsSnap.empty) return;

    // Pegar todos os membros ativos da igreja
    const membersSnap = await db
        .collection("users")
        .where("churchId", "==", churchId)
        .where("status", "==", "active")
        .get();

    const tokens: string[] = [];
    membersSnap.docs.forEach((doc) => {
      const data = doc.data() as UserData;
      if (data.fcmToken) {
        const disabled = data.disabledNotifications || [];
        if (!disabled.includes("elo_availability_reminder")) {
          tokens.push(data.fcmToken);
        }
      }
    });

    if (tokens.length > 0) {
      await sendPush(
          tokens,
          "Confirme sua disponibilidade",
          rule.message || "Confirme para os eventos dos próximos dias",
          {type: "elo_availability_reminder", churchId}
      );
    }
  } else if (rule.type === "liturgy_reminder") {
    // Lembrar responsável da liturgia
    const eventsSnap = await db
        .collection("churches").doc(churchId)
        .collection("events")
        .where("date", ">=", admin.firestore.Timestamp.fromDate(targetDate))
        .where("date", "<=", admin.firestore.Timestamp.fromDate(targetEnd))
        .get();

    if (eventsSnap.empty) return;

    for (const eventDoc of eventsSnap.docs) {
      const teams = eventDoc.data().teams || {};
      const liturgiaTeamId = teams.liturgia;
      if (!liturgiaTeamId) continue;

      const societyDoc = await db
          .collection("churches").doc(churchId)
          .collection("societies").doc(liturgiaTeamId)
          .get();

      if (!societyDoc.exists) continue;

      const boardPositions = societyDoc.data()?.boardWithPositions || {};
      const boardIds = new Set<string>();
      Object.values(boardPositions).forEach((ids: unknown) => {
        if (Array.isArray(ids)) ids.forEach((id) => boardIds.add(id));
      });

      const tokens = await getActiveTokens(
          Array.from(boardIds),
          "event_reminder"
      );

      if (tokens.length > 0) {
        await sendPush(
            tokens,
            "Lembrete de liturgia",
            rule.message || `Prepare a liturgia de ${eventDoc.data().name}`,
            {
              type: "event_reminder",
              churchId,
              eventId: eventDoc.id,
              responsibilityType: "liturgia",
            }
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
// SCHEDULED: Subscription checker (daily)
// ─────────────────────────────────────────────

export const subscriptionChecker = functions
    .region(REGION)
    .pubsub.schedule("0 0 * * *")
    .timeZone("America/Sao_Paulo")
    .onRun(async () => {
      console.log("Running subscription checker...");

      const now = admin.firestore.Timestamp.now();

      // Buscar assinaturas com trial expirando
      const trialSnap = await db
          .collectionGroup("subscription")
          .where("billingStatus", "==", "trial")
          .where("trialEndsAt", "<=", now)
          .get();

      for (const doc of trialSnap.docs) {
        const churchId = doc.ref.parent.parent?.id;
        if (!churchId) continue;

        console.log(`Trial expired for church: ${churchId}`);
        await doc.ref.update({
          billingStatus: "expired",
          tier: "free",
        });
        await db.collection("churches").doc(churchId).update({tier: "free"});
      }

      console.log(`Processed ${trialSnap.size} expired trials`);
      return null;
    });
