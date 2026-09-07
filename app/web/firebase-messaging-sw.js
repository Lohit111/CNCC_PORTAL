importScripts(
  "https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js",
);

importScripts(
  "https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js",
);

firebase.initializeApp({
  apiKey: "AIzaSyDvn9YsaPaMNQQUswEYQeGz",
  authDomain: "demo1-17dbe.firebaseapp.com",
  projectId: "demo1-17dbe",
  storageBucket: "demo1-17dbe.firebasestorage.app",
  messagingSenderId: "835948077761",
  appId: "1:835948077761:web:83592e93996c6377e6aa40",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Background message:", payload);
});
