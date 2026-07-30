# BharathFix Admin Web Console Setup & Deployment Guide

This project is a fully responsive administrative console to manage bookings, clients, providers, and catalogue data live on Firebase.

---

## 1. Link Firebase Connection

We have preconfigured 90% of the settings in `lib/firebase_options.dart`. You only need to add your Web `appId`:

1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Select your project: **my-work-c68d9**.
3. Go to **Project Settings** (gear icon near search).
4. Scroll down to the **Your apps** section under the *General* tab.
5. Click **Add app** -> Select **Web** (`</>`).
6. Register the app name as: `BharathFix Admin`.
7. Once registered, copy the `"appId"` value (e.g. `1:233649114123:web:xxxxxxxxxxxxxxxxx`).
8. Paste it inside [firebase_options.dart](file:///c:/Users/user/Documents/AntiGravity/bharath_fix_admin/lib/firebase_options.dart#L18) replacing `'REPLACE_WITH_YOUR_WEB_APP_ID'`.
9. Restart your dev server (`R` in terminal).

---

## 2. Compiling the Production Build

To bundle the web app for hosting:
```bash
flutter build web --release
```
This creates a compiled static web directory under `build/web/` containing all production pages.

---

## 3. Deploy Everywhere for Free (No Node/NPM Needed)

Since Node.js/Firebase CLI is not globally configured, you can host the console on top-tier global CDNs in seconds using **Drag-and-Drop** interfaces:

### Option A: Netlify (Recommended)
1. Go to [Netlify Drop](https://app.netlify.com/drop).
2. Register/Login.
3. Drag and drop the `build/web/` folder directly onto the screen.
4. Netlify will deploy it instantly and provide a free secure SSL link (e.g. `https://xxxx.netlify.app`).

### Option B: Vercel
1. Go to [Vercel Dashboard](https://vercel.com).
2. Click **Add New** -> **Project**.
3. Use Vercel's visual project uploader or link your repository to automatically build and deploy the project on every git push.
