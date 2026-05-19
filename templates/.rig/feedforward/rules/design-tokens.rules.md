# Design Tokens — UI standards

> **Frontend projects only.** Defines colors, typography, spacing, and global style sources.
> Remove this file or leave as `[DRAFT]` if the project has no UI.

---

## Source of truth

Document where tokens actually live in the codebase:

| Token type | Location | Notes |
|---|---|---|
| CSS variables | `[e.g. src/styles/tokens.css]` | |
| Tailwind theme | `[e.g. tailwind.config.ts]` | |
| Component library | `[e.g. components/ui/]` | shadcn, MUI, etc. |

---

## Colors

- **Primary:** `[hex / css var]`
- **Secondary:** `[hex / css var]`
- **Semantic:** success, warning, error, info — list vars
- **Do not** hardcode hex values in components — use tokens or theme classes

---

## Typography

- **Font families:** `[sans / mono]`
- **Scale:** document heading and body sizes (e.g. `text-sm` … `text-4xl`)
- **Line height / weight:** conventions for headings vs body

---

## Spacing & layout

- Use the project spacing scale only (e.g. Tailwind `4`, `8`, `16` — no arbitrary `px` unless documented)
- Max content width, grid breakpoints: `[values]`

---

## Components

- Shared primitives live in: `[path]`
- Domain components must compose primitives — no duplicate button/card styles

---

## Dark mode (if applicable)

- Strategy: `[class on html / prefers-color-scheme / toggle]`
- Token pairs for light/dark documented in: `[file]`

---

## Sensor

Enforced by: `feedback/sensors/standards-compliance.sensor.md` (semantic review)
Computational: add stylelint or Tailwind lint in `lint.sensor.md` when configured
