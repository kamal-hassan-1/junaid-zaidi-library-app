import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/checkout.dart';

/// Schedules local "due tomorrow" reminders from data the app already
/// fetches (`Checkout.dueDate`, confirmed real — see deferred.md) — no new
/// Koha API surface at all.
///
/// Reminders are rebuilt from scratch every time [MyBooksScreen] loads
/// ([scheduleDueDateReminders] cancels everything, then reschedules from
/// the current checkout list) rather than diffed against what was
/// scheduled before. That makes renewals, returns, and new checkouts all
/// self-correcting for free, at the cost of only ever holding pending
/// reminders for whatever was checked out as of the last time the screen
/// was opened.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'due_date_reminders';
  static const String _channelName = 'Due Date Reminders';

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz.identifier));
    } catch (_) {
      // Falls back to the timezone package's UTC default — reminders
      // still fire, just possibly off from the device's local 9am.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Cancels every previously scheduled reminder, then schedules one for
  /// each currently-open checkout whose due date is still more than a day
  /// away — at 9am local time the day before it's due.
  ///
  /// Skips checkouts already due today/tomorrow-before-9am or overdue:
  /// those are surfaced immediately by the red badge already on the My
  /// Books screen, so a reminder at that point would be redundant, not
  /// helpful.
  Future<void> scheduleDueDateReminders(List<Checkout> checkouts) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();

    final open = checkouts
        .where((c) => c.checkinDate == null && c.dueDate != null)
        .toList();
    if (open.isEmpty) return;

    await _requestPermission();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: "Reminds you a day before a borrowed book is due.",
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    for (final checkout in open) {
      final dueDate = checkout.dueDate!;
      final reminderTime = tz.TZDateTime(
        tz.local,
        dueDate.year,
        dueDate.month,
        dueDate.day - 1,
        9,
      );
      if (!reminderTime.isAfter(now)) continue;

      final title = checkout.title ?? 'A library book';
      try {
        await _plugin.zonedSchedule(
          id: checkout.checkoutId,
          title: '$title is due tomorrow',
          body: 'Renew it in the app if you need more time.',
          scheduledDate: reminderTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {
        // Permission denied, or a platform quirk. The in-app due/overdue
        // badge in My Books is the fallback either way — no need to
        // surface this as an app error.
      }
    }
  }

  static const String _watchChannelId = 'watchlist_availability';
  static const String _watchChannelName = 'Book Availability';

  /// Fires immediately — used by [WatchlistService] when a watched title
  /// flips from checked-out to available. [id] should be the book's
  /// `biblioId`, kept in a separate id-space from due-date reminders
  /// (those use `checkoutId`) so the two features can never collide on
  /// the same notification id.
  Future<void> notifyBookAvailable({required int biblioId, required String title}) async {
    if (kIsWeb) return;
    await init();
    await _requestPermission();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _watchChannelId,
        _watchChannelName,
        channelDescription: 'Tells you when a watched book you were waiting on is returned.',
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.show(
        id: -biblioId, // negative id-space keeps this out of the due-date reminders' range
        title: '$title is available now',
        body: 'Place a hold before someone else gets to it.',
        notificationDetails: details,
      );
    } catch (_) {
      // Same reasoning as scheduleDueDateReminders — the in-app Watching
      // list in My Books is the fallback, so a failure here is silent.
    }
  }
}
