# ReliefNet

**A Crowd-Sourced Disaster Relief Coordination Platform**

ReliefNet is a Flutter + Firebase mobile application that helps Sri Lankan communities coordinate dry-ration disaster relief without routing everything through centralized NGO administration. It connects victims who need help, volunteers who run donation centres and deliver parcels, and admins who oversee the platform — plus a public map anyone can browse without an account.

Built as the IT4052 ICT Project for the HNDIT programme at the Advanced Technological Institute – Kurunegala (SLIATE), Batch 2324(FT).

---

## The Problem

Sri Lanka deals with floods, landslides, and droughts on a regular basis — DMC data shows flood events between 2010 and 2023 displaced an average of over 300,000 people annually. Communities are usually quick to respond: volunteers show up, donors bring goods. The real problem is coordination — donors keep bringing the same items to the same locations while other areas get nothing, volunteers don't know where help is needed, and victims have no direct channel to say what they need. Existing relief apps only solve pieces of this puzzle; none combine donation centre management, inventory tracking, victim verification, and public donor access in one place.

## What ReliefNet Does

- **Public map access** — anyone can view active donation centres and live parcel availability, no account required.
- **Victim relief requests** — family-size-based parcel entitlement (not item-by-item selection), backed by a live camera photo automatically checked for tampering.
- **Volunteer-run donation centres** — verified volunteers register centres that go live on the public map instantly, no admin approval needed.
- **Temporary coordinator roles** — the volunteer who opens a centre automatically becomes its Main Coordinator and can add other verified volunteers as Sub Coordinators for as long as the centre stays open.
- **Parcel blueprint & bottleneck engine** — a single admin-managed blueprint defines the standard parcel, and a bottleneck algorithm calculates exactly how many complete parcels each centre can currently assemble from its stock.
- **Transaction-safe parcel lifecycle** — parcels move through `Available → Reserved → In Transit → Distributed`, with Firestore transactions ensuring no parcel is ever double-allocated.
- **Dual-confirmed delivery workflow** — coordinator confirms parcel collection, volunteer delivers, and the victim's QR code seals an immutable, tamper-evident handover receipt.
- **Admin panel** — volunteer approval queue, parcel blueprint editor, flagged-photo review, emergency broadcast, and a system-wide metrics dashboard.

## User Roles

| Role | Access |
|---|---|
| **Public** | Browse donation centres and parcel availability on a map — no sign-in |
| **Victim** | Submit relief requests, track delivery status, confirm handover via QR code |
| **Volunteer** | Browse/accept relief requests, register donation centres, deliver parcels |
| **Main / Sub Coordinator** | Temporary roles layered on Volunteer — manage a centre's inventory, packing, and dispatch |
| **Admin** | Approve volunteers, edit the parcel blueprint, review flagged photos, send broadcasts, view metrics |

## Tech Stack

| Category | Tools / Technologies |
|---|---|
| Frontend Framework | Flutter 3.32+ (Dart 3.8+) |
| State Management | Provider 6.1.5 |
| Navigation | GoRouter 14.x |
| Backend | Firebase (Authentication, Cloud Firestore, Storage, Cloud Functions, Cloud Messaging) |
| Maps & Location | Google Maps Flutter Plugin, Geolocator, Geocoding |
| Camera & Verification | image_picker, exif |
| Charts & Visuals | fl_chart |
| Testing | Flutter test package, Mockito, Firebase Emulator Suite |
| Design | Figma |

## Architecture

ReliefNet follows a layered architecture:

1. **Presentation layer** — four Flutter module groups (Public, Victim, Volunteer/Coordinator, Admin) sitting on a shared Provider state-management and GoRouter navigation layer.
2. **Service abstraction layer** — screens were built and verified against Provider-managed mock services first; those were then swapped for Firebase-backed implementations of the same interface, with no changes to screen code. That migration is complete across every module.
3. **Firebase backend** — Cloud Firestore for real-time data and transactions, Firebase Authentication for phone-OTP sign-in, Firebase Storage for damage/completion photos, and Cloud Functions for backend logic: a 6-hourly parcel packing scheduler, photo metadata (EXIF) verification, parcel reservation return on task cancellation, hourly 72-hour request expiry, blueprint-change recalculation, and push notification dispatch via Cloud Messaging.
4. **Google Maps Platform** — donation centre pins, victim/volunteer location, and directions throughout the app.

### Data Model

Firestore collections: `Users`, `Donation Centres` (with `Inventory Items` and `Packed Parcels` as subcollections), `Relief Requests`, `Delivery Tasks`, `Handover Receipts`, a single admin-managed `Parcel Blueprint` document, `Notifications`, and `Admin Logs`.

## Project Status

Development followed a UI-first, feature-module Agile process across 15 planned phases — from project setup through to Firebase integration, UI polish, and documentation. All phases are complete: the app now runs end-to-end on live Firebase services rather than mocks.

## Getting Started

This is a Flutter project. To run it locally:

```bash
flutter pub get
flutter run
```

You'll need a Firebase project configured for this app (Authentication with Phone sign-in, Cloud Firestore, Storage, Cloud Functions, and Cloud Messaging enabled) and a Google Maps API key set up for the Maps Flutter plugin.

A few general Flutter resources if you're new to the framework:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
- [Flutter online documentation](https://docs.flutter.dev/)

## Author

**H.G.K.U. Premarathna**
KUR/IT/2324/F/0058 · HNDIT, Batch 2324(FT)
Advanced Technological Institute – Kurunegala (SLIATE)

Supervised by **Ms. P.G.R.N.J. Gamlath**