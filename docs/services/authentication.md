# Authentication Service

Secure user authentication with multiple authentication methods.

## Overview

The AuthenticationService provides:
- **InstantDB Magic Links** (recommended)
- **Password-based authentication** with bcrypt hashing
- **Biometric authentication** (Face ID, Touch ID, fingerprint)
- **JWT token management**
- **Session persistence**
- **Reactive state with Signals**

## Quick Start

### Magic Link Authentication (Recommended)

```dart
final auth = getIt<AuthenticationService>();

// Send magic link
await auth.signInWithMagicLink('user@example.com');

// User clicks link in email → automatically signed in
```

### Password Authentication

```dart
// Sign up
final result = await auth.signUp(
  'user@example.com',
  'securePassword123',
  'John Doe',
);

if (result.success) {
  print('Welcome, ${result.user!.name}!');
}

// Sign in
await auth.signIn('user@example.com', 'securePassword123');

// Sign out
await auth.signOut();
```

### Biometric Authentication

```dart
// Check availability
final canAuth = await auth.canAuthenticateWithBiometrics();

if (canAuth) {
  final result = await auth.signInWithBiometric();
  if (result.success) {
    print('Authenticated with biometrics!');
  }
}
```

## Reactive State

Watch authentication state in UI:

```dart
class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = getIt<AuthenticationService>();

    return Watch((context) {
      if (auth.isAuthenticated.value) {
        final user = auth.currentUser.value!;
        return Column(
          children: [
            Text('Welcome, ${user.name}!'),
            Text('Email: ${user.email}'),
            if (user.avatarUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user.avatarUrl!),
              ),
            ElevatedButton(
              onPressed: () => auth.signOut(),
              child: Text('Sign Out'),
            ),
          ],
        );
      }

      return SignInForm();
    });
  }
}
```

## BREAKING CHANGE in v2.0.0

**Password hashing upgraded from SHA-256 to bcrypt** for security.

### Migration Required

Existing password hashes will NOT work after upgrading. Choose one:

**Option A: Password Resets**
```dart
// Clear old hashes, users reset passwords
await auth.signOut();
```

**Option B: Migrate on Sign-In**
```dart
// Detect old hash and migrate
final oldHash = await getUserPasswordHash(email);
if (oldHash.length == 64) {  // SHA-256 hash
  final newHash = await auth.migratePasswordHash(
    email: email,
    plainPassword: password,
    oldSha256Hash: oldHash,
  );
  if (newHash != null) {
    await updateUserPasswordHash(email, newHash);
  }
}
```

See [Migration Guide](../migration-v2.md) for complete details.

## API Reference

### Properties

```dart
// Reactive signals
Signal<bool> isAuthenticated        // Authentication status
Signal<AuthUser?> currentUser       // Current user info
Signal<String?> authToken           // JWT token
Signal<DateTime?> tokenExpiry       // Token expiration

// Constants
static const tokenDuration = Duration(hours: 24)
static const refreshThreshold = Duration(hours: 2)
```

### Methods

#### Sign Up

```dart
Future<AuthResult> signUp(
  String email,
  String password,
  String name,
) async
```

Creates new account with password authentication.

**Example**:
```dart
final result = await auth.signUp(
  'user@example.com',
  'securePass123',
  'John Doe',
);

if (result.success) {
  print('Account created!');
} else {
  print('Error: ${result.error}');
}
```

#### Sign In

```dart
Future<AuthResult> signIn(
  String email,
  String password,
) async
```

Sign in with email and password.

#### Magic Link Sign In

```dart
Future<AuthResult> signInWithMagicLink(String email) async
```

Send magic link to email for passwordless authentication.

**Advantages**:
- No password to remember
- More secure (no password to steal)
- Better UX (one-click sign-in)
- No migration issues

#### Biometric Sign In

```dart
Future<AuthResult> signInWithBiometric() async
```

Authenticate using device biometrics.

**Requirements**:
- User previously authenticated with email/password
- Biometric enabled on device
- User granted biometric permission

#### Sign Out

```dart
Future<void> signOut() async
```

Clear authentication state and tokens.

#### Refresh Token

```dart
Future<bool> refreshToken() async
```

Refresh JWT token before expiry.

#### Validate Password

```dart
String? validatePassword(String password)
```

Returns null if valid, error message if invalid.

**Rules**:
- Minimum 6 characters
- Add your own rules as needed

## Security Best Practices

### 1. Use Magic Links When Possible

```dart
// Recommended
await auth.signInWithMagicLink('user@example.com');

// Instead of passwords
await auth.signIn('user@example.com', 'password');
```

### 2. Enforce Strong Passwords

```dart
String? validateStrongPassword(String password) {
  if (password.length < 12) {
    return 'Password must be at least 12 characters';
  }
  if (!password.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain uppercase letter';
  }
  if (!password.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain number';
  }
  return null;
}
```

### 3. Enable Biometrics

```dart
// After first sign-in, enable biometrics
if (await auth.canAuthenticateWithBiometrics()) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enable Face ID?'),
      content: Text('Sign in faster next time'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Not Now'),
        ),
        TextButton(
          onPressed: () {
            // Biometric already enabled after sign-in
            Navigator.pop(context);
          },
          child: Text('Enable'),
        ),
      ],
    ),
  );
}
```

### 4. Monitor Failed Attempts

```dart
int failedAttempts = 0;

Future<void> handleSignIn(String email, String password) async {
  final result = await auth.signIn(email, password);

  if (!result.success) {
    failedAttempts++;
    if (failedAttempts >= 5) {
      // Lock account temporarily
      await lockAccount(email, Duration(minutes: 15));
    }
  } else {
    failedAttempts = 0;
  }
}
```

### 5. Implement Rate Limiting

```dart
final lastAttempt = <String, DateTime>{};

Future<bool> canAttemptSignIn(String email) async {
  final last = lastAttempt[email];
  if (last != null) {
    final diff = DateTime.now().difference(last);
    if (diff < Duration(seconds: 3)) {
      return false;  // Too soon
    }
  }
  lastAttempt[email] = DateTime.now();
  return true;
}
```

## Troubleshooting

### "Magic link not working"

1. Check InstantDB configured in `.env`
2. Verify email delivery (check spam folder)
3. Ensure app handles deep links properly

### "Biometric not available"

```dart
final canAuth = await auth.canAuthenticateWithBiometrics();
if (!canAuth) {
  // Show error: Device doesn't support biometrics
  // or user hasn't enabled it
}
```

### "Token expired"

Tokens auto-refresh 2 hours before expiry. Manual refresh:

```dart
await auth.refreshToken();
```

## Related

- [InstantDB Integration](../cloud/instantdb.md)
- [Migration Guide v2.0](../migration-v2.md)
- [Security Best Practices](../reference/security.md)
