# FestFlow — Event Management System

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-v3.6.2+-02569B?logo=flutter&logoColor=white&style=for-the-badge)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-v11.0.0+-FFCA28?logo=firebase&logoColor=black&style=for-the-badge)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-v3.6.x-0175C2?logo=dart&logoColor=white&style=for-the-badge)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Source--Available-4CAF50?style=for-the-badge)](LICENSE)

*The Streamlined Way to Manage College Fests & Events*

[View Presentation](docs/reports/README.md) · [Setup Guide](docs/SETUP.md) · [Report Vulnerability](SECURITY.md)

</div>

---

FestFlow is a feature-rich, role-based Event Management System designed to handle complex event registration, guest scanning, real-time feedback, and attendee management. Built using **Flutter** and backed by **Firebase**, FestFlow bridges the gap between event organizers (Leaders), staff (Members), and attendees (Guests). It features interactive analytics, offline status tracking, security controls, and a dedicated Web Admin Console.

---

## 🌟 Key Features

### 👤 Role-Based Access Control (RBAC)
- **Leaders (Hosts)**: Fully manage fests and sub-events, invite members via custom credentials, approve/reject guests, build custom forms, and generate AI-powered analytics.
- **Members (Staff)**: Scan QR codes for attendee entry, view event statistics, update event details, and manage check-in logs.
- **Guests (Attendees)**: Register for events, fill custom questionnaire forms, access event maps, receive announcements, and trigger SOS alerts.

### 📋 Custom Form Builder
- Google Forms-style dynamic question creator for event organizers.
- Supports text fields, multiple-choice options, and check-ins.
- Guest answers are captured in Firestore for screening.

### 📊 AI-Powered Analytics
- Integration with the **Google Gemini API** to generate automated event performance reports.
- Real-time statistics on attendee count, approval rate, checked-in guests, and engagement.

### 🔑 Secure QR Code Check-Ins
- Secure QR code generation for approved guests.
- Real-time camera scanner (`mobile_scanner`) for event members to validate tickets instantly.

### 📢 Real-Time Communications
- In-app global announcement board with instant updates.
- Real-time presence detection (Online/Offline) tracking for coordination.
- Live chat support between members and guests.

### 🛡️ Safety & SOS
- Instant Emergency SOS button for guests, allowing quick escalation to event organizers.

---

## 🛠️ Technology Stack

| Component | Technology | Version / Purpose |
| --- | --- | --- |
| **Mobile Core** | Flutter / Dart | `v3.6.2+` / Cross-platform app shell |
| **Backend** | Firebase Suite | Auth, Cloud Firestore, Cloud Storage |
| **AI Engine** | Google Generative AI | `gemini-2.0-flash` / Analytics reports |
| **Admin Web** | HTML / JS / Vanilla CSS | GSAP animations for global dashboard |
| **QR Scanner** | Mobile Scanner | Camera-based check-in integration |

---

## 📐 System Architecture

FestFlow's system design is modeled using standard software engineering principles. Below is the conceptual workflow:

```mermaid
graph TD
    Leader[Event Leader] -->|Creates Event| FS[(Cloud Firestore)]
    Leader -->|Creates Questions| Form[Custom Form Builder]
    Guest[Guest User] -->|Fills Form| Form
    Form -->|Saves Application| FS
    Leader -->|Approves Application| QR[QR Ticket Generated]
    Guest -->|Presents QR| Scanner[Mobile scanner app]
    Member[Event Member] -->|Scans QR| Scanner
    Scanner -->|Updates Check-in Status| FS
    FS -->|Aggregates Stats| Gemini[Gemini AI Engine]
    Gemini -->|Generates Recommendations| Leader
```

For comprehensive structural diagrams, see the [Architecture Docs](docs/architecture/):
- [Class Diagram](docs/architecture/class-diagram.png)
- [Sequence Diagram](docs/architecture/sequence-diagram.png)
- [Use Case Diagram](docs/architecture/use-case-diagram.png)
- [System Deployment Diagram](docs/architecture/system-architecture.png)

---

## 📸 Screenshots & Showcase

### Mobile Application

<table width="100%">
  <tr>
    <td width="25%" align="center"><b>Login & Auth</b></td>
    <td width="25%" align="center"><b>Registration</b></td>
    <td width="25%" align="center"><b>Leader Dashboard</b></td>
    <td width="25%" align="center"><b>Event Creation</b></td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/placeholder-login.png" alt="Login Screenshot" width="100%"></td>
    <td><img src="assets/screenshots/placeholder-registration.png" alt="Registration Screenshot" width="100%"></td>
    <td><img src="assets/screenshots/placeholder-leader-dashboard.png" alt="Leader Dashboard Screenshot" width="100%"></td>
    <td><img src="assets/screenshots/placeholder-event-creation.png" alt="Event Creation Screenshot" width="100%"></td>
  </tr>
  <tr>
    <td align="center"><i>Secure login</i></td>
    <td align="center"><i>Role registration</i></td>
    <td align="center"><i>Event metrics overview</i></td>
    <td align="center"><i>4-step wizard</i></td>
  </tr>
  <tr>
    <td width="25%" align="center"><b>Analytics & AI</b></td>
    <td width="25%" align="center"><b>Notifications</b></td>
    <td width="25%" align="center"><b>Responsive UI</b></td>
    <td width="25%" align="center"><b>SOS Safety</b></td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/placeholder-analytics.png" alt="Analytics Screenshot" width="100%"></td>
    <td><img src="assets/screenshots/placeholder-notifications.png" alt="Notifications Screenshot" width="100%"></td>
    <td><img src="assets/screenshots/placeholder-responsive.png" alt="Responsive UI Screenshot" width="100%"></td>
    <td><img src="assets/screenshots/placeholder-sos.png" alt="SOS Safety Screenshot" width="100%"></td>
  </tr>
  <tr>
    <td align="center"><i>Gemini event reports</i></td>
    <td align="center"><i>Real-time announcements</i></td>
    <td align="center"><i>Adaptable layout</i></td>
    <td align="center"><i>Emergency dialer</i></td>
  </tr>
</table>

### Admin Web Dashboard

<div align="center">
  <img src="assets/screenshots/placeholder-admin-panel.png" alt="Admin Panel Screenshot" width="90%">
  <br>
  <i>GSAP-animated Web Console for global database administration</i>
</div>

---

## 📁 Repository Structure

```
FestFlow/
├── lib/                      # Core Flutter application source
│   ├── admin/                # Admin interfaces
│   ├── guest/                # Guest screens, settings, and workflows
│   ├── home/                 # Launch, auth, services (Gemini, etc.)
│   ├── leader/               # Organizer tools, dashboards, and form creators
│   ├── member/               # Staff check-in tools and stats
│   ├── main.dart             # Application entry point
│   └── global.dart           # Global application state singleton
│
├── assets/                   # Static app resources
│   ├── screenshots/          # App screenshots & UI mockups
│   ├── icons/                # App launchers and icons
│   └── images/               # Image resources & presentation backgrounds
│
├── docs/                     # Documentation
│   ├── architecture/         # System design diagrams (UML Class/Sequence/etc.)
│   └── reports/              # PPTX Presentation Links & documentation reports
│
├── admin_dashboard/          # HTML/JS admin dashboard console
│   ├── index.html            # Dashboard entrance
│   ├── styles.css            # Dark glassmorphic design system
│   └── script.js             # GSAP controller (sanitized)
│
├── web/                      # Flutter Web files
│   └── landing-page/         # Archived original HTML landing pages
│
├── pubspec.yaml              # Dart project manifest
├── LICENSE                   # Proprietary Source-Available License
├── .gitignore                # Hardened security-focused Git excludes
└── README.md                 # Project README (this file)
```

---

## 🚀 Setup & Installation

Please refer to the [Local Setup Guide](docs/SETUP.md) for step-by-step instructions on:
1. Creating your own Firebase project and configuring the Android/iOS client files.
2. Obtaining a Gemini API key and configuring environment variables.
3. Fetching packages and building the application.

---

## 📄 License & Terms

FestFlow is released under the terms of the **FestFlow Source-Available License v1.0**. 

- **Allows**: Source code viewing, local configuration/testing, and educational review.
- **Prohibits**: Commercial usage, re-distribution, and app store publishing.

For complete terms, check the [LICENSE](LICENSE) file.

---

## 📧 Contact & Support

For queries, permissions, or career opportunities:
- **Author**: Kotoju Preetham Chary
- **Email**: kotojupreetham@gmail.com
- **LinkedIn**: [KOTOJU PREETHAM CHARY](https://linkedin.com/in/kotojupreetham) *(Placeholder)*
- **GitHub**: [github.com/kotojupreetham](https://github.com/kotojupreetham)
