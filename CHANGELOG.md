# Changelog

All notable changes to the FestFlow project will be documented in this file.

## [1.0.0] - 2026-05-23

### Added
- **Role-Based Access Control (RBAC)**: Distinct access levels and dashboards for **Leaders**, **Members**, and **Guests**.
- **Event Creation Wizard**: A responsive 4-step event creation wizard with integrated geolocation services.
- **QR Code System**: Camera-based QR scanning and generation for seamless guest check-ins and registrations.
- **Form Builder**: Custom Google Forms-style questionnaire builder for Leaders to pre-screen guests.
- **AI-Powered Reports**: Gemini API integration to generate analytics reports and recommendations for events.
- **Real-Time Database**: Full integration with Firestore for real-time announcements, chat, and attendee updates.
- **Offline Presence**: WidgetsBindingObserver integration to track user online/offline status in real-time.
- **Safety Features**: Integrated Emergency SOS dialer for guests.
- **Admin Web Dashboard**: Modern web interface utilizing GSAP animations for global event oversight.
- **Professional Project Structure**: Standardized docs, asset organization, and security policies.

### Changed
- Reorganized repository structure to keep root clean for Flutter compiles.
- Relocated and renamed UML diagrams to `docs/architecture/`.
- Moved old HTML landing page site files into `web/landing-page/`.
