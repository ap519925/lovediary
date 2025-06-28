# Firestore Setup Guide

## Overview
This guide explains how to set up the required Firestore indexes for the Love Diary application.

## Firestore Index Error
If you encounter the error:
```
[cloud_firestore/failed-precondition] The query requires an index
```

This means you need to create composite indexes in Firestore for efficient querying.

## Solution Options

### Option 1: Automatic Index Creation (Recommended)
1. Click on the provided link in the error message to automatically create the index
2. This will take you to the Firebase Console where you can create the index with one click

### Option 2: Manual Index Creation via Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `love-diary-776dc`
3. Navigate to Firestore Database
4. Click on "Indexes" tab
5. Click "Create Index"
6. Create the following composite indexes:

#### Posts Collection Indexes
- **Index 1**: Collection: `posts`, Fields: `userId` (Ascending), `createdAt` (Descending)
- **Index 2**: Collection: `posts`, Fields: `partnerId` (Ascending), `createdAt` (Descending)

#### Users Collection Indexes
- **Index 3**: Collection: `users`, Fields: `userCode` (Ascending)
- **Index 4**: Collection: `users`, Fields: `profile.searchableName` (Ascending)

#### Messages Collection Indexes
- **Index 5**: Collection: `messages`, Fields: `chatId` (Ascending), `timestamp` (Ascending)

#### Locations Collection Indexes
- **Index 6**: Collection: `locations`, Fields: `userId` (Ascending), `timestamp` (Descending)

### Option 3: Deploy via Firebase CLI
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`
3. Initialize Firebase in your project: `firebase init firestore`
4. Deploy the indexes: `firebase deploy --only firestore:indexes`

The `firestore.indexes.json` file in the project root contains all the required index definitions.

## Index Build Time
- Indexes may take several minutes to build depending on the amount of data
- You can monitor the build progress in the Firebase Console under Firestore > Indexes
- The app will work normally once the indexes are built

## Common Issues

### Index Already Exists
If you get an error that an index already exists, you can safely ignore it.

### Index Build Failed
If an index build fails:
1. Check that the field names match exactly (case-sensitive)
2. Ensure the collection names are correct
3. Try creating the index manually via the Firebase Console

### Performance Considerations
- Indexes improve query performance but use additional storage
- Each index is automatically maintained as data changes
- Consider the query patterns when designing indexes

## Verification
After creating the indexes, verify they're working by:
1. Refreshing your app
2. Performing the actions that previously caused the error
3. Checking that queries complete successfully without errors

## Support
If you continue to experience issues:
1. Check the Firebase Console for index build status
2. Verify your Firebase project configuration
3. Ensure you have the necessary permissions to create indexes
