# InstantDB Datalog Parsing Guide

## Overview

The Flutter App Shell's DatabaseService includes comprehensive support for parsing InstantDB's datalog format. This guide explains how to diagnose and fix datalog parsing issues.

## Understanding the Datalog Format

InstantDB sometimes returns query results in a "datalog" format instead of the expected collection format:

```dart
// Expected collection format:
{
  "conversations": [
    {"id": "123", "title": "Chat", "createdAt": "2025-09-07T21:22:07.057152"}
  ]
}

// Datalog format:
{
  "datalog-result": {
    "join-rows": [
      ["entity-id", "attribute-id", "value", "timestamp"],
      ["123", "8ce3e8f1-...", "123", 1757294527119],
      ["123", "82a884f7-...", "Chat", 1757294527119],
      ["123", "90774276-...", "2025-09-07T21:22:07.057152", 1757294527119]
    ]
  }
}
```

## The Challenge: Attribute ID Mapping

The main challenge with datalog format is that attribute IDs (UUIDs) are:
- **Schema-specific**: Different for each InstantDB instance
- **Collection-specific**: May vary between collections
- **Not human-readable**: Need mapping to field names

## Solution: Flexible Attribute Mapping

### 1. Collection-Specific Mappings

The DatabaseService maintains mappings for common collections:

```dart
// In _getAttributeMappings() method
'conversations': {
  'id': ['8ce3e8f1-1c42-4683-9e91-dfe8f6879e1b'],
  'title': ['82a884f7-6e0f-427d-88b6-66c550e86d98'],
  'createdAt': ['90774276-102f-4963-856b-2e69315c0bfd'],
  'updatedAt': ['253a7374-4154-4cc4-b71b-5eca6f8e5db6'],
},
```

### 2. Diagnosing Parsing Issues

Use the built-in diagnostic method:

```dart
final dbService = GetIt.I<DatabaseService>();
final diagnosis = await dbService.diagnoseDatalogParsing('conversations');

// Diagnosis includes:
// - Format detected (datalog vs collection)
// - Number of documents parsed
// - All attribute IDs found in data
// - Which IDs are mapped vs unmapped
// - Sample values for unmapped attributes
```

### 3. Using the Investigation Screen

Navigate to `/datalog-investigation` in the app to:
1. Test datalog parsing for multiple collections
2. See detailed attribute mapping analysis
3. Identify unmapped attribute IDs
4. Get sample values to understand field types

## Fixing Unmapped Attributes

When you encounter unmapped attributes:

### Step 1: Run Diagnostics

```bash
# Navigate to the investigation screen
/datalog-investigation
```

Look for warnings like:
```
⚠️ Found 2 unmapped attribute IDs:
  - a1b2c3d4-e5f6-7890: String (26 occurrences) sample: "user@example.com"
  - f9e8d7c6-b5a4-3210: Boolean (26 occurrences) sample: "true"
```

### Step 2: Add Mappings

Edit `database_service.dart` and update `_getAttributeMappings()`:

```dart
'conversations': {
  'id': ['8ce3e8f1-1c42-4683-9e91-dfe8f6879e1b'],
  'title': ['82a884f7-6e0f-427d-88b6-66c550e86d98'],
  'email': ['a1b2c3d4-e5f6-7890'],  // Add this
  'isActive': ['f9e8d7c6-b5a4-3210'],  // Add this
  'createdAt': ['90774276-102f-4963-856b-2e69315c0bfd'],
  'updatedAt': ['253a7374-4154-4cc4-b71b-5eca6f8e5db6'],
},
```

### Step 3: Test Again

Run the investigation screen again to verify all attributes are now mapped.

## Fallback Strategies

Even without mappings, the DatabaseService tries to preserve data:

1. **Type Inference**: 
   - Booleans → likely 'completed' field
   - Email strings → 'email' field
   - ISO dates → 'createdAt' field

2. **Preserve Unknown Fields**: 
   - Unmapped attributes stored using their UUID as field name
   - Data is preserved even if field name is unknown

## Enhanced Logging

The DatabaseService provides detailed logging:

```dart
// Enable verbose logging to see parsing details
AppShellLogger.setLogLevel(Level.FINE);

// Logs will show:
// 🔍 Parsing datalog for collection "conversations" with 104 join-rows
// ⚠️ Found 2 unmapped attribute IDs:
//   - a1b2c3d4...: String (26 occurrences) sample: "email@example.com"
// ✅ Parsed 26 documents from 104 join-rows
```

## Best Practices

1. **Test with Real Data**: Use the investigation screen with actual collections
2. **Monitor Logs**: Watch for unmapped attribute warnings in production
3. **Document Mappings**: Comment attribute mappings with their field meanings
4. **Share Mappings**: If you discover new attribute IDs, update the defaults

## Future Improvements

The long-term solution is for InstantDB to handle datalog→collection conversion internally. Until then, this workaround ensures data is properly parsed.

## Troubleshooting

### Issue: 0 Documents Returned
**Cause**: Missing attribute mappings
**Solution**: Run diagnostics, add missing mappings

### Issue: Missing Fields in Documents
**Cause**: Some attribute IDs not mapped
**Solution**: Check logs for unmapped attributes, add to mappings

### Issue: Wrong Field Names
**Cause**: Incorrect attribute ID mapping
**Solution**: Verify mapping with sample data from diagnostics

## Related Files

- `/packages/flutter_app_shell/lib/src/services/database_service.dart` - Main parsing logic
- `/packages/flutter_app_shell/lib/src/screens/datalog_investigation_screen.dart` - Investigation UI
- `/DATALOG_WORKAROUND_REMOVAL_PLAN.md` - Plan for removing workaround when InstantDB fixes issue