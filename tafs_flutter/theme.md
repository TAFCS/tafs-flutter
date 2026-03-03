This is a structured design system guide for your project. It’s designed to be clean, scannable, and easy for both designers and developers to follow.

---

# 🎨 Design System: Core UI Styling

This document outlines the visual language for our interface, focusing on a **layered light mode** architecture. We utilize a "surface-level" approach to create depth and hierarchy without relying solely on heavy shadows.

## 1. Brand Palette

Our primary and accent colors are chosen for a professional yet energetic feel.

| Role | Color | Hex | Sample |
| --- | --- | --- | --- |
| **Primary** | Denim Blue | `#255A94` | Brand identity, primary buttons, active states |
| **Accent** | Terracotta | `#D56637` | High-priority CTAs, notifications, highlights |

---

## 2. Surface Hierarchy (Light Mode)

We use four distinct surface levels to represent depth. As the level number increases, the surface "lifts" closer to the user.

| Level | Usage | Color (Hex) | Elevation / Border |
| --- | --- | --- | --- |
| **Level 0** | **Canvas/Background** | `#F8F9FA` | Deepest layer. Used for the main app background. |
| **Level 1** | **Base Component** | `#FFFFFF` | Main content areas, sidebars, and large containers. |
| **Level 2** | **Elevated Card** | `#FFFFFF` | Modals, popovers, or cards that sit on top of Level 1. |
| **Level 3** | **Overlay/Tooltip** | `#FFFFFF` | Floating elements, dropdown menus, and tooltips. |

> **Design Tip:** To distinguish between Level 1, 2, and 3 (which are all white), use **subtle borders** (`1px solid #E9ECEF`) or **soft shadows** that increase in blur/spread as the level increases.

---

## 3. Applied CSS Variables

Copy and paste these into your global stylesheet to maintain consistency across the project.

```css
:root {
  /* Brand Colors */
  --color-primary: #255A94;
  --color-accent: #D56637;
  
  /* Text Colors */
  --text-main: #1A1A1A;
  --text-muted: #6C757D;
  --text-on-primary: #FFFFFF;

  /* Surface Levels */
  --surface-0: #F8F9FA; /* Background */
  --surface-1: #FFFFFF; /* Content */
  --surface-2: #FFFFFF; /* Component */
  --surface-3: #FFFFFF; /* Floating */

  /* Depth (Shadows) */
  --shadow-l1: 0 1px 3px rgba(0,0,0,0.05);
  --shadow-l2: 0 4px 6px rgba(0,0,0,0.07);
  --shadow-l3: 0 10px 15px rgba(0,0,0,0.1);

  /* Borders */
  --border-subtle: 1px solid #E9ECEF;
}

```

---

## 4. Interaction States

Consistency in how elements react to user input is key to a polished UI.

* **Primary Button:** Background: `#255A94`. On hover: Darken 10%.
* **Accent Button:** Background: `#D56637`. On hover: Darken 10%.
* **Focus State:** `2px solid #255A94` with a `2px` offset.
* **Disabled:** Opacity 50%, `cursor: not-allowed`.

---

## 5. Spacing & Radius

* **Corner Radius:** `8px` for standard components (cards, buttons); `12px` for Level 2/3 containers.
* **Base Unit:** `4px` (All spacing should be multiples of 4: 8, 12, 16, 24, 32).

Would you like me to generate a **React** or **HTML/Tailwind** component library based on these surface levels?