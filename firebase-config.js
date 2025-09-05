// Firebase configuration for EcoBazaarX (Firestore only - Auth disabled)
const firebaseConfig = {
  apiKey: "AIzaSyBDFe6o3M18xli1ssoNE2db_8luRpF8wCk",
  authDomain: "ecobazzarx.firebaseapp.com",
  projectId: "ecobazzarx",
  storageBucket: "ecobazzarx.firebasestorage.app",
  messagingSenderId: "321134139960",
  appId: "1:321134139960:web:8e7f3c2dd23ba98a32a4cd",
  measurementId: "G-0TYKMV0NS9"
};

// Initialize Firebase (Firestore only - no Auth)
firebase.initializeApp(firebaseConfig);

// Initialize only Firestore - Auth is handled by Spring Boot
console.log('Firebase initialized for Firestore only (Auth disabled)');
