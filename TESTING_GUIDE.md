# Reclamation System - Testing Guide

## ✅ Verified Setup

### Database Architecture
- **Single Database Instance**: All screens use `database_helper_new.dart` (Singleton pattern)
- **SQLite Database**: User and Admin access the SAME SQLite database file
- **Database Location**: `reclamations.db` stored on device
- **Data Persistence**: Reclamations persist across login sessions and app restarts

### Static User Accounts

#### User Account
- **Email**: `youssefouesalti54@gmail.com`
- **Password**: `user123`
- **Role**: `user`
- **Access**: Can create and view reclamations

#### Admin Account
- **Email**: `youssef.oueslati@esprit.tn`
- **Password**: `admin123`
- **Role**: `admin`
- **Access**: Can view ALL reclamations and respond to them

## Testing Flow

### Test 1: User Creates Reclamation

1. **Login as User**:
   ```
   Email: youssefouesalti54@gmail.com
   Password: user123
   ```

2. **Create Reclamation**:
   - Navigate to "Nouvelle Réclamation"
   - Fill in the form:
     - Name: Your Name
     - Email: your@email.com
     - Subject: Test Reclamation
     - Message: This is a test reclamation message
   - Click "Soumettre la réclamation"
   - Should see success message

3. **View Your Reclamation**:
   - Navigate to "All Reclamations" from drawer
   - Should see your reclamation with status "new" (blue)

### Test 2: Admin Responds to Reclamation

1. **Logout** (click logout icon)

2. **Login as Admin**:
   ```
   Email: youssef.oueslati@esprit.tn
   Password: admin123
   ```

3. **View Reclamations**:
   - Admin automatically sees "Liste des Réclamations"
   - Should see ALL reclamations including the one created by user
   - Each reclamation shows:
     - Status icon (blue/orange/green)
     - Subject and message preview
     - User name
     - Date

4. **Respond to Reclamation**:
   - Click on the user's reclamation
   - Should open "Admin Response" screen
   - See full reclamation details
   - Change status (select "In Progress" or "Resolved")
   - Enter response in the text field
   - Click "Save Response"
   - Should see success message

### Test 3: User Sees Admin Response

1. **Logout** from admin account

2. **Login as User** again:
   ```
   Email: youssefouesalti54@gmail.com
   Password: user123
   ```

3. **View Reclamation**:
   - Navigate to "All Reclamations"
   - Click on your reclamation
   - Should see:
     - Updated status (orange for "in_progress" or green for "resolved")
     - Admin's response in a highlighted box

## Expected Behavior

### ✅ What Should Work:
- [x] User can create reclamations
- [x] Admin can see ALL reclamations (including those created by users)
- [x] Admin can respond and update status
- [x] User can see admin responses
- [x] Data persists across login/logout
- [x] Same database for both user and admin

### Status Colors:
- **Blue** = New (just created)
- **Orange** = In Progress (admin working on it)
- **Green** = Resolved (completed)

## Database Verification

All screens use the same SQLite database:
- ✅ `reclamation_form_screen.dart` → `database_helper_new.dart` → SQLite
- ✅ `reclamation_list_screen.dart` → `database_helper_new.dart` → SQLite (Admin)
- ✅ `admin_response_screen.dart` → `database_helper_new.dart` → SQLite
- ✅ `view_reclamations_screen.dart` → `database_helper_new.dart` → SQLite
- ✅ `main.dart` → `database_helper_new.dart` → SQLite

**Database File**: `reclamations.db` (stored in app's database directory)

## Troubleshooting

**If Admin doesn't see user reclamations:**
- Make sure you're on the same device
- Stop the app completely and restart (not hot reload)
- Run: `flutter clean && flutter pub get && flutter run`
- SQLite database is shared across all users on the same device

**If Response doesn't appear:**
- Click the refresh button in the app
- Navigate away and back to the reclamation list
- Make sure response was saved (check for success message)

## Code Location

- **Login Screen**: `lib/screens/login_screen.dart`
- **User Form**: `lib/screens/reclamation_form_screen.dart`
- **Admin List**: `lib/screens/reclamation_list_screen.dart`
- **Admin Response**: `lib/screens/admin_response_screen.dart`
- **Database**: `lib/database/database_helper.dart`
