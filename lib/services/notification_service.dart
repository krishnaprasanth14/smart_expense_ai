import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const String spendingAlertsKey = 'spending_alerts';
  static const String budgetAlertsKey = 'budget_alerts';
  static const String dailyReminderKey = 'daily_reminder';

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
    );
  }

  static Future<bool> getSpendingAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(spendingAlertsKey) ?? true;
  }

  static Future<bool> getBudgetAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(budgetAlertsKey) ?? true;
  }

  static Future<bool> getDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dailyReminderKey) ?? false;
  }

  static Future<void> setSpendingAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(spendingAlertsKey, value);
  }

  static Future<void> setBudgetAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(budgetAlertsKey, value);
  }

  static Future<void> setDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dailyReminderKey, value);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'smart_expense_alerts',
      'SmartExpense Alerts',
      channelDescription: 'Expense and budget alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  static Future<void> showBudgetWarning(
      double percentage,
      ) async {
    final enabled = await getBudgetAlerts();

    if (!enabled) {
      return;
    }

    await showNotification(
      title: 'Budget Alert ⚠️',
      body:
      'You have used ${percentage.toStringAsFixed(0)}% of your monthly budget.',
    );
  }

  static Future<void> showBudgetExceeded() async {
    final enabled = await getBudgetAlerts();

    if (!enabled) {
      return;
    }

    await showNotification(
      title: 'Budget Exceeded 🚨',
      body: 'Your monthly spending has exceeded your budget.',
    );
  }

  static Future<void> showHighSpendingAlert(
      String category,
      ) async {
    final enabled = await getSpendingAlerts();

    if (!enabled) {
      return;
    }

    await showNotification(
      title: 'Spending Alert 💰',
      body: 'Your spending is high in the $category category.',
    );
  }
}