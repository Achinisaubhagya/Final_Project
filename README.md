# Budget Planning Mobile App

A modern, user-friendly mobile app to help you manage your finances, track your income and expenses, set financial goals, and stay on top of your budget with reminders and notifications.



## Features

- **Add Income & Expenses:**  
  Easily record your income and expenses. All entries are saved securely in the cloud.

- **Financial Goals:**  
  Set, view, and track your savings or spending goals.

- **Visual Reports:**  
  View your financial data with interactive **bar charts** and **pie charts** for better insights.

- **Reminders:**  
  - Add, edit, and delete reminders for important financial tasks.
  - Get notified when a reminder is due.
  - Daily notifications to remind you to add your income and expenses.

- **Notifications:**  
  - View all notifications in a dedicated page.
  - Swipe to delete notifications.

- **History & Budget Overview:**  
  - See your transaction history.
  - View your available balance and budget details.

- **User Profile & Settings:**  
  - Manage your profile.
  - Customize app settings.

## Technical Details

- **Built with:** Flutter, Firebase Auth, Cloud Firestore
- **Authentication:** Secure login and user management with Firebase Auth.
- **Data Storage:** All data is stored in Firestore, organized by user.
- **Charts:** Uses chart libraries for bar and pie charts.
- **Reminders & Notifications:**  
  - Reminders are stored in the `reminders` collection with a `userId` field.
  - Notifications are stored in the `notifications` collection with a `userId` field.
  - The app ensures no duplicate notifications for the same reminder.



## How to Use

1. **Sign Up / Log In:**  
   Create an account or log in with your credentials.

2. **Add Income/Expense:**  
   Use the "+" button to add new income or expense entries.

3. **Set Goals:**  
   Go to the Goals page to add and track your financial goals.

4. **View Reports:**  
   Access the dashboard to see bar and pie charts of your finances.

5. **Manage Reminders:**  
   - Add reminders for bills, savings, or custom events.
   - Edit or delete reminders as needed.

6. **Check Notifications:**  
   - View all reminders and important alerts in the Notifications page.
   - Swipe to delete notifications.



## Requirements

- Flutter SDK
- Firebase project (Auth & Firestore enabled)



## Getting Started

1. **Clone the repository:**
  
   git clone https://github.com/yourusername/your-repo-name.git
   cd your-repo-name
   

2. **Install dependencies:**
 
   flutter pub get
  

3. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.
   - Make sure Firebase Auth and Firestore are enabled.

4. **Run the app:**
   
   flutter run
  



## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

