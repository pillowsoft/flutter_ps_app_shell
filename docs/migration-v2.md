# Migration Guide: v1.x → v2.0.0

**Version 2.0.0** contains critical security improvements and bug fixes. This guide helps you migrate your application safely.

---

## Breaking Changes

### 🔴 CRITICAL: Password Hashing Security Fix

**Issue**: v1.x used SHA-256 for password hashing, which is vulnerable to rainbow table attacks due to:
- No built-in salt
- Too fast (attackers can try billions of passwords/second)
- Not designed for password storage

**Solution**: v2.0.0 uses **bcrypt** with cost factor 12:
- Built-in salt (prevents rainbow table attacks)
- Adaptive cost (resistant to brute-force)
- Industry standard for password storage
- 200-400ms hashing time (acceptable for authentication)

**Impact**: **Existing password hashes will NOT work after upgrade**

---

## Migration Paths

Choose the migration strategy that best fits your application:

### Option A: Require Password Resets (Recommended for Production)

**Best for**: Production apps with "forgot password" functionality

**Steps**:

1. **Before upgrading**, notify users that passwords will need to be reset
2. **Upgrade to v2.0.0**
3. **Clear stored password hashes** (if you're storing them)
4. **Users reset passwords** via "forgot password" flow

**Advantages**:
- ✅ Simplest implementation
- ✅ Forces users to create new, secure passwords
- ✅ No migration code needed

**Disadvantages**:
- ❌ All users must reset passwords
- ❌ Requires working "forgot password" flow

---

### Option B: Transparent Migration on First Sign-In

**Best for**: Apps where password resets would cause significant friction

**Steps**:

1. **Update your sign-in flow** to detect old SHA-256 hashes and migrate them:

```dart
Future<AuthResult> signIn(String email, String password) async {
  final auth = getIt<AuthenticationService>();

  // Get stored password hash from your database
  final storedHash = await _getStoredPasswordHash(email);

  if (storedHash == null) {
    return AuthResult.failure('User not found');
  }

  // Detect old SHA-256 hash (64 characters)
  if (storedHash.length == 64) {
    // Attempt migration
    final newHash = await auth.migratePasswordHash(
      email: email,
      plainPassword: password,
      oldSha256Hash: storedHash,
    );

    if (newHash != null) {
      // Migration successful - update storage
      await _updatePasswordHash(email, newHash);
      _logger.info('Migrated password hash for: $email');

      // Continue with sign-in
      return await auth.signIn(email, password);
    } else {
      // Migration failed - password incorrect
      return AuthResult.failure('Invalid password');
    }
  } else {
    // Already bcrypt hash, proceed normally
    return await auth.signIn(email, password);
  }
}
```

2. **Implement helper methods** for your database:

```dart
// Get stored password hash from your database
Future<String?> _getStoredPasswordHash(String email) async {
  // Your database query here
  final db = getIt<DatabaseService>();
  final user = await db.getUserByEmail(email);
  return user?.passwordHash;
}

// Update password hash in your database
Future<void> _updatePasswordHash(String email, String newHash) async {
  final db = getIt<DatabaseService>();
  await db.updateUser(email, {'passwordHash': newHash});
}
```

**Advantages**:
- ✅ Seamless user experience
- ✅ No password resets required
- ✅ Migration happens automatically

**Disadvantages**:
- ❌ More complex implementation
- ❌ Requires additional migration code
- ❌ Migration only happens when users sign in

---

### Option C: Clear All Auth Data (Recommended for Development)

**Best for**: Development/testing environments

**Steps**:

1. **Upgrade to v2.0.0**
2. **Clear all local authentication data**:

```dart
final auth = getIt<AuthenticationService>();
await auth.signOut();

// If you're storing password hashes in a database, clear them:
final db = getIt<DatabaseService>();
await db.clearAllPasswordHashes();
```

3. **Users re-authenticate** on next app launch

**Advantages**:
- ✅ Quick and simple
- ✅ Clean slate for testing

**Disadvantages**:
- ❌ All users signed out
- ❌ Not suitable for production

---

## Migration Code Reference

The `AuthenticationService` provides a migration helper method:

```dart
/// Migrate password hash from SHA-256 to bcrypt
Future<String?> migratePasswordHash({
  required String email,
  required String plainPassword,
  required String oldSha256Hash,
}) async
```

**Usage**:
- **Input**: Email, plain password, old SHA-256 hash
- **Process**: Verifies password against old hash, generates new bcrypt hash
- **Output**: New bcrypt hash (or `null` if password invalid)

**Example**:

```dart
final newHash = await auth.migratePasswordHash(
  email: 'user@example.com',
  plainPassword: 'userPassword123',
  oldSha256Hash: 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
);

if (newHash != null) {
  // Migration successful
  await updateUserPasswordHash('user@example.com', newHash);
} else {
  // Password incorrect
  return AuthResult.failure('Invalid password');
}
```

---

## Important Notes

### InstantDB Magic Link Authentication Unaffected

If your app uses **InstantDB magic link authentication** (recommended), you are **not affected** by this breaking change. Magic links don't use password hashing.

**No migration needed if**:
- You only use `auth.signInWithMagicLink(email)`
- You don't use `auth.signIn(email, password)`
- You don't store password hashes

### Password Hashing Implementation

The framework provides password hashing utilities but **does not store passwords** by default. If you haven't implemented password storage in your app, **this breaking change does not affect you**.

**You are affected only if**:
- You store password hashes in your database
- You use `_hashPassword()` in your custom authentication logic
- You have existing users with SHA-256 password hashes

---

## Security Best Practices

### After Migration

1. **Require strong passwords**: Enforce minimum length (12+ characters recommended)
2. **Enable biometric authentication**: Use `AuthenticationService.signInWithBiometric()`
3. **Use magic links when possible**: InstantDB magic links eliminate password storage risks
4. **Monitor failed sign-ins**: Track and alert on suspicious activity
5. **Implement rate limiting**: Prevent brute-force attacks on sign-in endpoints

### Bcrypt Configuration

The default cost factor is **12** (2^12 = 4096 iterations):

```dart
String _hashPassword(String password) {
  return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 12));
}
```

**Performance**:
- Mobile devices: ~300ms
- Desktop: ~100-200ms

**Cost Factor Recommendations**:
- **12**: Good balance (default)
- **13-14**: Higher security, slower (500-800ms)
- **10-11**: Faster, lower security (NOT recommended for production)

---

## Testing Your Migration

### Before Upgrading

1. **Backup your data**: Save all password hashes
2. **Test migration code**: Use development/staging environment
3. **Verify password resets work**: Ensure "forgot password" flow functional

### After Upgrading

1. **Test sign-in with migrated hash**:

```dart
test('password sign-in works after migration', () async {
  final auth = getIt<AuthenticationService>();

  // Create user with v1.x SHA-256 hash
  final oldHash = 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
  await createUser(email: 'test@example.com', passwordHash: oldHash);

  // Attempt migration
  final newHash = await auth.migratePasswordHash(
    email: 'test@example.com',
    plainPassword: 'password123',
    oldSha256Hash: oldHash,
  );

  expect(newHash, isNotNull);
  expect(newHash!.startsWith('\$2'), isTrue); // Bcrypt hashes start with $2

  // Update and verify sign-in
  await updateUserPasswordHash('test@example.com', newHash);
  final result = await auth.signIn('test@example.com', 'password123');
  expect(result.isSuccess, isTrue);
});
```

2. **Test new registrations**:

```dart
test('new users get bcrypt hashes', () async {
  final auth = getIt<AuthenticationService>();

  final result = await auth.signUp(
    email: 'newuser@example.com',
    password: 'securePassword123',
    name: 'New User',
  );

  expect(result.isSuccess, isTrue);

  // Verify hash format
  final hash = await getStoredPasswordHash('newuser@example.com');
  expect(hash!.startsWith('\$2'), isTrue);
});
```

---

## Rollback Plan

If you need to rollback to v1.x after upgrading:

**⚠️ WARNING**: Bcrypt hashes **cannot be converted back** to SHA-256. You will need to:

1. **Revert to v1.x** in your `pubspec.yaml`
2. **Clear all password hashes** created with bcrypt
3. **Require all users to reset passwords**

**Recommendation**: Thoroughly test v2.0.0 in development/staging before production upgrade.

---

## Support

If you encounter issues during migration:

1. **Check logs**: Look for migration-related warnings
2. **Review code**: Ensure migration helper is called correctly
3. **Test thoroughly**: Use development environment first
4. **Open an issue**: [GitHub Issues](https://github.com/yourusername/flutter_app_shell/issues)

---

## Summary

**Action Required**:
- ✅ Review your authentication implementation
- ✅ Choose migration strategy (A, B, or C)
- ✅ Test migration in development
- ✅ Update production after successful testing

**No Action Needed If**:
- ✅ You only use InstantDB magic links
- ✅ You don't store password hashes
- ✅ Your app doesn't have existing users

**Security Benefit**:
- 🔒 Protection against rainbow table attacks
- 🔒 Resistance to brute-force attacks
- 🔒 Industry-standard password security
