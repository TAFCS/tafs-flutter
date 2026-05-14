# Design System

---

## Brand Colors

| Token | Hex | Usage |
|---|---|---|
| `--color-white` | `#FFFFFF` | Page background, card surfaces |
| `--color-blue-100` | `#BCD0EA` | Subtle backgrounds, hover states, dividers |
| `--color-blue-200` | `#B1C7E4` | Input borders, secondary badges, chips |
| `--color-blue-300` | `#A0BBDD` | Sidebar tints, table row alternates |
| `--color-navy` | `#021A54` | Headings, primary buttons, navbar, heavy text |

---

## Semantic / Status Colors

| Token | Hex | Usage |
|---|---|---|
| `--color-paid` | `#22C27B` | "Paid" badges, success states, positive amounts |
| `--color-paid-bg` | `#E8FAF3` | Paid badge background fill |
| `--color-unpaid` | `#E84646` | "Unpaid" badges, error states, overdue alerts |
| `--color-unpaid-bg` | `#FDEAEA` | Unpaid badge background fill |

---

## Typography

**Body Font:** [Readex Pro](https://fonts.google.com/specimen/Readex+Pro) — a geometric sans-serif with wide language support and clean readability.

```css
@import url('https://fonts.googleapis.com/css2?family=Readex+Pro:wght@300;400;500;600;700&display=swap');
```

| Scale | Size | Weight | Usage |
|---|---|---|---|
| `--text-xs` | 11px | 400 | Labels, captions, metadata |
| `--text-sm` | 13px | 400 | Table cells, helper text |
| `--text-base` | 15px | 400 | Body copy, form inputs |
| `--text-md` | 17px | 500 | Card titles, section labels |
| `--text-lg` | 21px | 600 | Page subheadings |
| `--text-xl` | 27px | 700 | Page headings |
| `--text-2xl` | 34px | 700 | Hero / dashboard stats |

---

## Border Radius

Fixed, relatively high — giving the UI a modern, friendly, card-based feel.

| Token | Value | Usage |
|---|---|---|
| `--radius-sm` | `8px` | Chips, badges, tags |
| `--radius-md` | `12px` | Inputs, dropdowns, small cards |
| `--radius-lg` | `16px` | Modals, cards, panels |
| `--radius-xl` | `20px` | Page-level containers, hero cards |
| `--radius-full` | `9999px` | Pills, avatars, toggle switches |

---

## Spacing Scale

Based on a 4px base unit.

| Token | Value |
|---|---|
| `--space-1` | `4px` |
| `--space-2` | `8px` |
| `--space-3` | `12px` |
| `--space-4` | `16px` |
| `--space-5` | `20px` |
| `--space-6` | `24px` |
| `--space-8` | `32px` |
| `--space-10` | `40px` |
| `--space-12` | `48px` |
| `--space-16` | `64px` |

---

## Shadows

| Token | Value | Usage |
|---|---|---|
| `--shadow-xs` | `0 1px 3px rgba(2,26,84,0.06)` | Subtle lift on inputs |
| `--shadow-sm` | `0 2px 8px rgba(2,26,84,0.08)` | Cards at rest |
| `--shadow-md` | `0 4px 16px rgba(2,26,84,0.12)` | Modals, dropdowns |
| `--shadow-lg` | `0 8px 32px rgba(2,26,84,0.16)` | Page overlays |

Shadows are tinted with `--color-navy` to feel intentional and on-brand rather than generic grey.

---

## Component Patterns

### Buttons

```
Primary:   bg navy (#021A54)  ·  text white  ·  radius-full  ·  px-6 py-3  ·  font-weight 600
Secondary: bg blue-100        ·  text navy   ·  radius-full  ·  px-6 py-3  ·  font-weight 500
Ghost:     bg transparent     ·  text navy   ·  border 1.5px navy  ·  radius-full
Danger:    bg unpaid          ·  text white  ·  radius-full
```

### Status Badges

```
Paid:    bg #E8FAF3  ·  text #22C27B  ·  radius-full  ·  px-3 py-1  ·  font-weight 600  ·  text-xs uppercase
Unpaid:  bg #FDEAEA  ·  text #E84646  ·  radius-full  ·  px-3 py-1  ·  font-weight 600  ·  text-xs uppercase
```

### Cards

```
bg white  ·  radius-xl  ·  shadow-sm  ·  p-6
Border: 1px solid #BCD0EA (blue-100)
Hover: shadow-md, border-color blue-200
```

### Inputs

```
bg white  ·  border 1.5px blue-200  ·  radius-md  ·  px-4 py-3  ·  text-base
Focus: border-color navy, shadow-xs
Placeholder: color blue-300
```

### Tables

```
Header row: bg blue-100  ·  text navy  ·  font-weight 600  ·  text-sm uppercase tracking-wide
Odd rows:   bg white
Even rows:  bg #F5F9FE  (mix of white + blue-100 at ~30%)
Border:     none (use spacing and bg to separate rows)
Row hover:  bg blue-100
```

### Navigation / Sidebar

```
bg navy (#021A54)
Active item:   bg blue-300 at 20% opacity  ·  text white  ·  font-weight 600
Inactive item: text white at 65% opacity   ·  font-weight 400
Hover item:    bg white at 8% opacity
```

---

## CSS Variables (Ready to Copy)

```css
:root {
  /* Brand */
  --color-white:       #FFFFFF;
  --color-blue-100:    #BCD0EA;
  --color-blue-200:    #B1C7E4;
  --color-blue-300:    #A0BBDD;
  --color-navy:        #021A54;

  /* Status */
  --color-paid:        #22C27B;
  --color-paid-bg:     #E8FAF3;
  --color-unpaid:      #E84646;
  --color-unpaid-bg:   #FDEAEA;

  /* Typography */
  --font-body:         'Readex Pro', sans-serif;
  --text-xs:           11px;
  --text-sm:           13px;
  --text-base:         15px;
  --text-md:           17px;
  --text-lg:           21px;
  --text-xl:           27px;
  --text-2xl:          34px;

  /* Radius */
  --radius-sm:         8px;
  --radius-md:         12px;
  --radius-lg:         16px;
  --radius-xl:         20px;
  --radius-full:       9999px;

  /* Spacing */
  --space-1:  4px;
  --space-2:  8px;
  --space-3:  12px;
  --space-4:  16px;
  --space-5:  20px;
  --space-6:  24px;
  --space-8:  32px;
  --space-10: 40px;
  --space-12: 48px;
  --space-16: 64px;

  /* Shadows */
  --shadow-xs: 0 1px 3px  rgba(2,26,84,0.06);
  --shadow-sm: 0 2px 8px  rgba(2,26,84,0.08);
  --shadow-md: 0 4px 16px rgba(2,26,84,0.12);
  --shadow-lg: 0 8px 32px rgba(2,26,84,0.16);
}
```

---

## Do / Don't

| ✅ Do | ❌ Don't |
|---|---|
| Use `navy` for all heavy text and primary actions | Use pure black (`#000`) anywhere |
| Use `blue-100` for subtle surface fills | Use grey tones — stay in the blue family |
| Use `radius-full` for badges and buttons | Mix different radius values on the same component type |
| Tint shadows with navy | Use default grey `box-shadow` |
| Use Readex Pro for all text | Mix in a second body font |
| Show paid/unpaid with both color AND a label | Rely on color alone to convey status |