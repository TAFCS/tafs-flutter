For the **TAFS Parent Portal**, transitioning to a **Hamburger Menu (Navigation Drawer)** is a strategic architectural decision. It ensures that as we scale from the Phase 1 "Backbone" to future modules like Academics, Attendance, and Payroll, the UI remains uncluttered and expandable.

The following layout defines the "Student-Centric" dashboard experience, optimized for a multi-child household.

---

### **1. The "Switching" Architecture (The Student Selector)**

To make switching between siblings effortless, we will implement a **Sticky Profile Header** and a **Quick-Switch Drawer Header**.

* 
**The Active Profile Hub (Top Bar):** * Instead of a static title, the top app bar features the active student’s name and a "Switch" icon.


* Tapping this triggers a bottom-sheet overlay showing all children linked to the **Family ID**, allowing for a one-tap context switch.




* 
**The Identity Persistence:** * The **GR Number** and **Campus Code** are always visible in the header to ensure the parent knows exactly which child's ledger they are viewing.



---

### **2. The Primary Dashboard Layout**

The dashboard is designed for high-glanceability, prioritizing the **Advanced Finance Engine** results.

#### **A. The Navigation Drawer (The Hamburger Menu)**

This menu houses the roadmap for TAFS's digital future.

* 
**Header:** Displays the **Family ID** and the Parent/Guardian's name.


* **Core Modules (Phase 1):** * **Dashboard:** Returns to the current student's overview.
* 
**Fee Ledger:** Direct access to the **Credit Bucket** and payment history.


* 
**Downloads:** Access to generated **Barcoded Challans**.




* 
**Future Slots (Placeholders):** * Grayed-out icons for **Attendance**, **Report Cards**, and **Staff Directory** to build anticipation for future phases.



#### **B. The "Live Ledger" Action Card**

Following our **Manual-First** logic, this card provides real-time transparency.

* 
**Financial Status:** A bold display of the "Total Outstanding" or "Advance Credit".


* **Installment Tracker:** If a **Bifurcated Plan** (e.g., an 8-month admission fee split) is active, a progress bar shows how many installments have been cleared.
* 
**Payment Webhook Status:** A "Last Updated" timestamp showing when the last **PayPro/Bank** sync occurred.



#### **C. The Communication Feed**

* 
**Priority Alerts:** A dedicated section for **Push Notifications**.


* 
**Institutional Data:** Current Grade and Section, ensuring the **Single Source of Truth** is always front-and-center.



---

### **3. Technical Implementation Standards**

| Feature | Flutter Coding Practice | Operational Benefit |
| --- | --- | --- |
| **Drawer Logic** | **Scaffold.drawer** | Centralized navigation that scales for future 2026-2027 modules.

 |
| **Sibling State** | **BLoC Pattern** | Tapping a sibling in the switcher triggers a `SwitchStudentContext` event, instantly reloading all finance and identity data. |
| **Caching** | **Hive / FlutterSecureStorage** | The student list is cached locally, ensuring the switcher is instantaneous even on slow networks. |
| **Asset Delivery** | **AWS S3 + CloudFront** | Student photos are served via a CDN to ensure the switcher feels "premium" and fast.

 |