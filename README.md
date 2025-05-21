## Reminders & Notifications

This app allows users to create personal reminders and receive notifications for important events.

### Features

- **Add Reminders:**  
  Go to the Reminders page to add a new reminder with a title, date, and time. Reminders are saved to Firestore and are user-specific.

- **Edit/Delete Reminders:**  
  Tap the menu on any reminder to edit or delete it.

- **Automatic Notifications:**  
  - When a reminder is due, a notification is automatically created in the notifications list.
  - A daily notification is also generated at 10:00 PM to remind you to add your income and expenses.

- **View Notifications:**  
  The Notifications page displays all notifications for the logged-in user.  
  You can swipe to delete any notification.

### Technical Details

- **Firestore Structure:**
  - Reminders are stored in the `reminders` collection with a `userId` field.
  - Notifications are stored in the `notifications` collection with a `userId` field.
- **No Duplicate Notifications:**  
  The app ensures that each reminder only creates one notification when due.

### How It Works

- When you add a reminder, it is saved under your user ID.
- When a reminder's time passes, the app checks and creates a notification if one does not already exist.
- The Notifications page only shows items from the `notifications` collection, so you never see duplicates.

### Requirements

- Firebase Auth (for user management)
- Cloud Firestore (for storing reminders and notifications)
- Flutter SDK

### Usage

1. **Add a Reminder:**  
   - Tap the "+" button on the Reminders page.
   - Fill in the title, date, and time, then save.

2. **View Notifications:**  
   - Go to the Notifications page to see all your notifications.

3. **Delete Notifications:**  
   - Swipe left on any notification to delete it.
