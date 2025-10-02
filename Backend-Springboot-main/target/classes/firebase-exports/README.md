# Firebase Export Files Directory

## 📁 **Required Files**

Place your Firebase export files in this directory:

### **Core Collections**
- `users.json` - User accounts and profiles
- `products.json` - Product catalog
- `stores.json` - Store information
- `wishlists.json` - User wishlists
- `wishlistItems.json` - Items in wishlists
- `carts.json` - Shopping carts
- `ecoChallenges.json` - Eco challenges
- `paymentTransactions.json` - Payment records
- `userOrders.json` - Order history
- `userSettings.json` - User preferences

## 🔧 **How to Export from Firebase**

### **Method 1: Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Firestore Database**
4. For each collection:
   - Click on the collection name
   - Click **Export** (if available)
   - Download as JSON

### **Method 2: Firebase CLI**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Export all collections
firebase firestore:export ./firebase-export --project your-project-id

# Copy files to this directory
cp ./firebase-export/*.json src/main/resources/firebase-exports/
```

### **Method 3: Manual Export**
1. Go to each collection in Firebase Console
2. Copy the data manually
3. Save as JSON files with the exact names above

## 📝 **JSON Format Example**

Each JSON file should contain an array of documents:

```json
[
  {
    "id": "document_id",
    "field1": "value1",
    "field2": "value2",
    "createdAt": "2024-01-01T00:00:00Z"
  },
  {
    "id": "another_document_id",
    "field1": "value3",
    "field2": "value4",
    "createdAt": "2024-01-02T00:00:00Z"
  }
]
```

## 🚀 **After Adding Files**

1. **Commit and Push**:
   ```bash
   git add .
   git commit -m "Add Firebase export files"
   git push origin main
   ```

2. **Deploy Backend**:
   - Render will automatically deploy
   - Check logs for successful deployment

3. **Run Migration**:
   ```bash
   curl -X POST https://ecobazaarxspringboot-1.onrender.com/api/migration/start
   ```

## 🔍 **Verification**

After migration, verify data in Railway MySQL:
1. Go to Railway Dashboard
2. Open your MySQL service
3. Check **Data** tab
4. Verify tables are created with data

## 🆘 **Troubleshooting**

- **File Not Found**: Ensure files are in this exact directory
- **JSON Parse Error**: Validate JSON format
- **Missing Collections**: Add empty JSON arrays `[]` for missing collections
- **Permission Issues**: Check file permissions

This directory is where your Firebase export files should be placed for migration to Railway MySQL! 🚀
