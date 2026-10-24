# OnlyTurf - Sports Turf & Facility Booking Platform

<p align="center">
  <strong>Find, Book, and Manage Sports Venues Effortlessly</strong>
  <br />
  <a href="https://onlyturf.in/"><strong>🌐 Visit Official Website (onlyturf.in) »</strong></a>
</p>

---

## 📌 Overview

**OnlyTurf** is a comprehensive multi-platform sports facility booking ecosystem designed for sports enthusiasts, players, and venue owners. The platform simplifies discovering nearby turfs, checking real-time slot availability, booking courts (cricket, football, badminton, pickleball, etc.), and managing operations effortlessly.

### 🌐 Live Platform & Links
- **Official Website:** [https://onlyturf.in/](https://onlyturf.in/)
- **Repository:** [https://github.com/ompandey84/onlyturf.git](https://github.com/ompandey84/onlyturf.git)

---

## 🏗️ Repository Architecture

This repository contains the full end-to-end suite for the OnlyTurf ecosystem:

```
Turf_1/
├── application/         # Flutter User Mobile Application (Android / iOS)
├── owner_application/   # Flutter Turf Owner & Manager Application (Android / iOS)
├── website/             # React + Vite Web Portal for Players & Admins
├── .gitignore           # Root gitignore for Flutter, React, and secrets
└── README.md            # Project documentation & setup instructions
```

---

## 📱 Modules & Features

### 1. `application/` — Player Mobile App (Flutter)
The user-facing mobile app enabling sports players to explore and book turfs.
- **Location-Based Search:** Geolocation and distance-based filtering of available venues.
- **Real-Time Booking:** Dynamic time slot picker with live availability status.
- **Secure Payments:** Integrated payment gateway (Razorpay) for instant and transparent confirmations.
- **Booking History & Alerts:** View past/upcoming bookings and receive real-time notifications.
- **Rich Experience:** Shimmer loading effects, smooth animations (Lottie), and Google Fonts integration.

### 2. `owner_application/` — Turf Owner App (Flutter)
A dedicated management application tailored for turf operators and venue owners.
- **Facility Management:** Add, update, and showcase court details, pricing, pictures, and amenities.
- **Slot Scheduling:** Configure custom operating hours, peak/off-peak pricing, and manual slot blocking.
- **Booking Management:** Real-time visibility into customer bookings, walk-in management, and cancellation tracking.
- **Analytics & Revenue:** Overview of revenue performance, daily metrics, and occupancy rates.

### 3. `website/` — Web Portal (React + Vite + Tailwind CSS)
The modern web application hosted at [onlyturf.in](https://onlyturf.in/).
- **Responsive Web Interface:** Built with React 18, Vite, and Tailwind CSS.
- **Interactive Facility Catalog:** Browse turf options, inspect amenities, and filter by sport.
- **Owner & Admin Dashboards:** Dedicated portal views for venue managers with Recharts data visualizations.
- **Customer Portal:** User authentication, fast booking flows, and policy pages.

---

## 🛠️ Tech Stack

- **Mobile Frontends:** Flutter 3.x, Dart
- **Web Frontend:** React 18, Vite, Tailwind CSS, Lucide Icons, Recharts
- **Backend / Database:** Supabase (PostgreSQL, Realtime, Auth, Storage)
- **Payments:** Razorpay Integration
- **State Management:** Provider (Flutter), React Hooks (Web)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.9.x)
- [Node.js](https://nodejs.org/) (>= 18.x) & npm
- Git

---

### Setup Instructions

#### 1. Clone the repository
```bash
git clone https://github.com/ompandey84/onlyturf.git
cd onlyturf
```

#### 2. Run the User Mobile App (`application`)
```bash
cd application
flutter pub get
flutter run
```

#### 3. Run the Owner Mobile App (`owner_application`)
```bash
cd owner_application
flutter pub get
flutter run
```

#### 4. Run the Web Application (`website`)
```bash
cd website
npm install
npm run dev
```
Visit the local server running at `http://localhost:5173` or access the production website at [onlyturf.in](https://onlyturf.in/).

---

## 🔒 Environment Configuration

For security reasons, `.env` files containing API keys and database credentials are excluded from version control. 

Create a `.env` file in each respective directory based on the following templates:

- **`application/.env`** and **`owner_application/.env`**:
  ```env
  SUPABASE_URL=your_supabase_url
  SUPABASE_ANON_KEY=your_supabase_anon_key
  ```

- **`website/.env`**:
  ```env
  VITE_SUPABASE_URL=your_supabase_url
  VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
  ```

---

## 📄 License & Attribution

Developed and maintained by [ompandey84](https://github.com/ompandey84). All rights reserved.  
Visit [https://onlyturf.in/](https://onlyturf.in/) for bookings and inquiries.
