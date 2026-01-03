# Signals Best Practices Guide

This guide provides comprehensive best practices for using the Dart Signals library in the Flutter App Shell framework to prevent reactive cycles and `SignalEffectException` errors.

## Table of Contents

- [Quick Reference](#quick-reference)
- [Understanding Reactive Cycles](#understanding-reactive-cycles)
- [The untracked() Function](#the-untracked-function)
- [The batch() Function](#the-batch-function)
- [Common Patterns](#common-patterns)
- [Reference Implementations](#reference-implementations)
- [Common Pitfalls](#common-pitfalls)
- [Testing Signal Safety](#testing-signal-safety)

## Quick Reference

### When to Use Each Tool

| Scenario | Use | Example |
|----------|-----|---------|
| Async callback mutates signal | `untracked()` | `asyncOp().then((r) => untracked(() => signal.value = r))` |
| Error handler mutates signal | `untracked()` | `onError: (e) => untracked(() => errorSignal.value = e)` |
| Multiple signals updated together | `batch()` | `batch(() { s1.value = a; s2.value = b; })` |
| Read signal without dependency | `untracked()` | `final v = untracked(() => signal.value)` |
| Prevent intermediate reactions | `batch()` | `batch(() { /* multi-step update */ })` |

## Understanding Reactive Cycles

### What is a Reactive Cycle?

A reactive cycle occurs when an effect mutates a signal that the effect depends on, causing the effect to trigger itself repeatedly:

```dart
// ❌ CREATES REACTIVE CYCLE
effect(() {
  final value = mySignal.value;  // 1. Effect depends on mySignal

  asyncOperation().then((result) {
    mySignal.value = result;      // 2. Effect mutates mySignal
                                  // 3. Effect triggers again (cycle!)
  });
});
```

**Result**: `SignalEffectException: Cycle detected`

### Why Does This Happen?

The Signals library tracks dependencies automatically. When an effect:
1. Reads a signal → The effect becomes dependent on that signal
2. Mutates that signal → The effect is scheduled to run again
3. Runs again → Creates an infinite loop

The library detects this cycle and throws `SignalEffectException` to prevent infinite loops.

### The Fix: Breaking Dependencies

Use `untracked()` to read or mutate signals without creating reactive dependencies:

```dart
// ✅ CORRECT - No cycle
effect(() {
  final value = mySignal.value;  // 1. Effect depends on mySignal

  asyncOperation().then((result) {
    untracked(() {
      mySignal.value = result;    // 2. Mutation is untracked
                                  // 3. No cycle created!
    });
  });
});
```

## The untracked() Function

### Purpose

`untracked()` breaks reactive dependencies by:
- **Reading signals** without the effect depending on them
- **Mutating signals** without triggering dependent effects

### Syntax

```dart
// Read without dependency
final value = untracked(() => signal.value);

// Mutate without triggering
untracked(() => signal.value = newValue);

// Complex operations
untracked(() {
  final a = signal1.value;
  final b = signal2.value;
  signal3.value = a + b;
});
```

### When to Use

**1. Async Callbacks**

```dart
effect(() {
  final id = userId.value;

  // ✅ Wrap async callback mutations
  fetchUserData(id).then((data) {
    untracked(() => userData.value = data);
  });
});
```

**2. Error Handlers**

```dart
effect(() {
  final value = someSignal.value;

  saveToDatabase(value).then(
    (success) => untracked(() => lastError.value = null),
    onError: (e) => untracked(() => lastError.value = e),  // ✅ Critical!
  );
});
```

**3. Conditional Signal Reads**

```dart
effect(() {
  // ✅ Read config without dependency
  final threshold = untracked(() => configSignal.value.threshold);

  // Only depend on actualSignal
  if (actualSignal.value > threshold) {
    performAction();
  }
});
```

## The batch() Function

### Purpose

`batch()` groups multiple signal mutations into a single atomic update, preventing intermediate reactions:

```dart
// ❌ WITHOUT batch() - 3 separate updates
currentUser.value = null;     // Triggers reactions
isAuthenticated.value = false; // Triggers reactions
authToken.value = null;        // Triggers reactions

// ✅ WITH batch() - 1 atomic update
batch(() {
  currentUser.value = null;
  isAuthenticated.value = false;
  authToken.value = null;
});
```

### When to Use

**1. Multi-Signal State Updates**

```dart
void handleError(String key, dynamic error) {
  batch(() {
    lastError.value = error;
    errorCount.value += 1;
    errorTimestamp.value = DateTime.now();
  });
}
```

**2. Atomic State Transitions**

```dart
void logout() {
  batch(() {
    currentUser.value = null;
    isAuthenticated.value = false;
    authToken.value = null;
    sessionExpiry.value = null;
  });
}
```

**3. Coordinated UI Updates**

```dart
void applyTheme(ThemeConfig theme) {
  batch(() {
    primaryColor.value = theme.primary;
    accentColor.value = theme.accent;
    brightness.value = theme.brightness;
    fontScale.value = theme.fontScale;
  });
}
```

## Common Patterns

### Pattern 1: Persistence Effect

**Problem**: Saving signal changes to storage

```dart
// ❌ WRONG
effect(() {
  final value = setting.value;
  prefs.setInt('setting', value).then(
    (success) {
      if (success) {
        lastError.value = null;  // Cycle!
      }
    },
    onError: (e) => lastError.value = e,  // Cycle!
  );
});
```

**Solution**: Wrap all async mutations

```dart
// ✅ CORRECT
effect(() {
  final value = setting.value;
  prefs.setInt('setting', value).then(
    (success) {
      if (success) {
        untracked(() => lastError.value = null);
      }
    },
    onError: (e) => untracked(() => handleError('setting', e)),
  );
});

void handleError(String key, dynamic error) {
  batch(() {
    lastError.value = error;
    errorCount.value += 1;
  });
}
```

### Pattern 2: Database Query Effect

**Problem**: Watching query results

```dart
// ❌ WRONG
effect(() {
  final query = currentQuery.value;

  database.query(query).then((results) {
    queryResults.value = results;  // Cycle!
    isLoading.value = false;       // Multiple mutations!
  });
});
```

**Solution**: Combine untracked() and batch()

```dart
// ✅ CORRECT
effect(() {
  final query = currentQuery.value;
  isLoading.value = true;

  database.query(query).then((results) {
    untracked(() {
      batch(() {
        queryResults.value = results;
        isLoading.value = false;
        lastError.value = null;
      });
    });
  });
});
```

### Pattern 3: Authentication Flow

**Problem**: Multi-step auth state updates

```dart
// ❌ WRONG - Intermediate states visible
void login(User user, String token) {
  currentUser.value = user;           // UI sees partial state
  isAuthenticated.value = true;       // UI updates again
  authToken.value = token;            // UI updates again
}
```

**Solution**: Atomic updates with batch()

```dart
// ✅ CORRECT - Single atomic update
void login(User user, String token) {
  batch(() {
    currentUser.value = user;
    isAuthenticated.value = true;
    authToken.value = token;
  });
}
```

### Pattern 4: Error Recovery

**Problem**: Error handlers that update multiple signals

```dart
// ❌ WRONG - Creates cycles
void handleNetworkError(dynamic error) {
  lastError.value = error;            // Triggers effects
  errorCount.value += 1;              // Triggers effects
  retryCount.value = 0;               // Triggers effects
}
```

**Solution**: Wrap in batch() and call from untracked()

```dart
// ✅ CORRECT
effect(() {
  final request = pendingRequest.value;

  sendRequest(request).then(
    (response) => untracked(() => handleSuccess(response)),
    onError: (e) => untracked(() => handleNetworkError(e)),
  );
});

void handleNetworkError(dynamic error) {
  batch(() {
    lastError.value = error;
    errorCount.value += 1;
    retryCount.value = 0;
  });
}
```

## Reference Implementations

### DatabaseService (Good Example)

**File**: `lib/src/services/database_service.dart`

**Lines 505-506**: Correct `untracked()` usage in computed signal

```dart
final transformedSignal = computed(() {
  return untracked(() {  // ✅ Prevents dependency tracking
    final result = querySignal.value;
    // Safe to read other signals here
    return processResults(result);
  });
});
```

**Lines 571-572**: Defensive copying with untracked()

```dart
untracked(() {
  final defensiveCopy = List.from(results);
  resultSignal.value = defensiveCopy;
});
```

### AuthenticationService (Good Example)

**File**: `lib/src/services/authentication_service.dart`

**Lines 175-178**: Atomic logout with batch()

```dart
void logout() {
  batch(() {
    currentUser.value = null;
    isAuthenticated.value = false;
    authToken.value = null;
  });
}
```

**Lines 403, 477, 507, 595**: Consistent batch() usage for state transitions

### AppShellSettingsStore (Fixed Implementation)

**File**: `lib/src/state/app_shell_settings_store.dart`

**Lines 70-238**: All 8 persistence effects follow safe pattern:

```dart
effect(() {
  final value = brightness.value.index;
  _prefs.setInt('brightness', value).then(
    (success) {
      if (success) {
        untracked(() {  // ✅ Safe mutation
          if (lastPersistenceError.value?.contains('brightness') ?? false) {
            lastPersistenceError.value = null;
          }
        });
      }
    },
    onError: (e) => untracked(() => _handlePersistenceFailure('brightness', e)),
  );
});
```

**Lines 247-254**: Error handler uses batch()

```dart
void _handlePersistenceFailure(String key, dynamic error) {
  batch(() {  // ✅ Atomic error update
    lastPersistenceError.value = errorMessage;
    persistenceFailureCount.value += 1;
  });
}
```

## Common Pitfalls

### Pitfall 1: Forgetting Error Handlers

**Problem**: Only wrapping success path

```dart
// ❌ INCOMPLETE
effect(() {
  asyncOp().then((result) {
    untracked(() => signal.value = result);  // ✅ Good
  }, onError: (e) {
    errorSignal.value = e;  // ❌ Forgot untracked!
  });
});
```

**Fix**: Always wrap both paths

```dart
// ✅ COMPLETE
effect(() {
  asyncOp().then(
    (result) => untracked(() => signal.value = result),
    onError: (e) => untracked(() => errorSignal.value = e),
  );
});
```

### Pitfall 2: Nested Async Operations

**Problem**: Forgetting inner callbacks

```dart
// ❌ WRONG
effect(() {
  asyncOp1().then((result1) {
    untracked(() {
      signal1.value = result1;  // ✅ Wrapped

      asyncOp2().then((result2) {
        signal2.value = result2;  // ❌ Not wrapped!
      });
    });
  });
});
```

**Fix**: Wrap each level

```dart
// ✅ CORRECT
effect(() {
  asyncOp1().then((result1) {
    untracked(() {
      signal1.value = result1;

      asyncOp2().then((result2) {
        untracked(() => signal2.value = result2);  // ✅ Wrapped
      });
    });
  });
});
```

### Pitfall 3: Conditional Mutations

**Problem**: Only some code paths wrapped

```dart
// ❌ INCOMPLETE
effect(() {
  asyncOp().then((result) {
    if (result.success) {
      untracked(() => dataSignal.value = result.data);  // ✅ Wrapped
    } else {
      errorSignal.value = result.error;  // ❌ Not wrapped!
    }
  });
});
```

**Fix**: Wrap all mutation paths

```dart
// ✅ CORRECT
effect(() {
  asyncOp().then((result) {
    untracked(() {  // ✅ Wrap entire block
      if (result.success) {
        dataSignal.value = result.data;
      } else {
        errorSignal.value = result.error;
      }
    });
  });
});
```

### Pitfall 4: Not Using batch() for Multi-Signal Updates

**Problem**: Sequential mutations cause intermediate reactions

```dart
// ❌ INEFFICIENT - 3 separate reactions
void updateUserProfile(UserProfile profile) {
  userName.value = profile.name;
  userEmail.value = profile.email;
  userAvatar.value = profile.avatar;
}
```

**Fix**: Use batch() for atomic updates

```dart
// ✅ EFFICIENT - 1 atomic reaction
void updateUserProfile(UserProfile profile) {
  batch(() {
    userName.value = profile.name;
    userEmail.value = profile.email;
    userAvatar.value = profile.avatar;
  });
}
```

## Testing Signal Safety

### Test for SignalEffectException

```dart
test('should not throw SignalEffectException during initialization', () async {
  final store = AppShellSettingsStore(prefs);

  // Wait for initialization
  await Future.delayed(const Duration(milliseconds: 100));

  // Should complete without throwing
  expect(store.persistenceFailureCount.value, equals(0));
});
```

### Test Rapid Signal Changes

```dart
test('should handle rapid signal changes without crashes', () async {
  final store = AppShellSettingsStore(prefs);
  await Future.delayed(const Duration(milliseconds: 100));

  // Rapidly change multiple signals
  for (var i = 0; i < 10; i++) {
    store.brightness.value = i % 2 == 0 ? Brightness.light : Brightness.dark;
    store.sidebarCollapsed.value = i % 2 == 0;
  }

  // Wait for effects to settle
  await Future.delayed(const Duration(milliseconds: 200));

  // Should not throw SignalEffectException
  expect(store.persistenceFailureCount.value, equals(0));
});
```

### Test Initialization Lifecycle

```dart
test('isReady signal should become true after setup', () async {
  final store = AppShellSettingsStore(prefs);

  // Wait for microtask
  await Future.delayed(const Duration(milliseconds: 50));

  // Should be ready
  expect(store.isReady.value, isTrue);
});
```

## Summary

### Key Takeaways

1. **Always wrap async signal mutations in `untracked()`**
   - Success callbacks
   - Error callbacks
   - Nested async operations

2. **Use `batch()` for multi-signal updates**
   - Prevents intermediate reactions
   - More efficient
   - Better UX (atomic state transitions)

3. **Don't forget error handlers**
   - Error paths must also use `untracked()`
   - Error handlers that mutate multiple signals need `batch()`

4. **Test signal safety**
   - No `SignalEffectException` during initialization
   - Rapid changes handled correctly
   - Initialization lifecycle completes

5. **Follow reference implementations**
   - DatabaseService: `untracked()` patterns
   - AuthenticationService: `batch()` patterns
   - AppShellSettingsStore: Complete persistence pattern

### Quick Checklist

Before committing code with signals:

- [ ] All async callbacks wrap mutations in `untracked()`
- [ ] Error handlers use `untracked()`
- [ ] Multi-signal updates use `batch()`
- [ ] No signal mutations inside effects (without untracked)
- [ ] Tests verify no `SignalEffectException`
- [ ] Initialization lifecycle considered

---

**Last Updated**: 2026-01-03 (v2.0.3)
**Related Issues**: SignalEffectException fixes
**See Also**: CHANGELOG.md, CLAUDE.md
