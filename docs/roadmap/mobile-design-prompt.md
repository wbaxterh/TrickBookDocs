---
sidebar_position: 6
title: Mobile Design Prompt
description: NanoBananaPro design specifications for the TrickBook mobile app
---

# Mobile App Design Prompt

Design specifications used with NanoBananaPro to create the TrickBook mobile app UI.

---

## Brand Identity

### Colors

**Primary Color:** Gold/Yellow - This is the signature TrickBook color

```
┌─────────────────────────────────────────────────────────────┐
│                      DARK THEME                              │
├─────────────────────────────────────────────────────────────┤
│ Primary:        #FFD700 (TrickBook Gold)                    │
│ Primary Dark:   #FFC000 (Pressed/Active state)              │
│ Secondary:      #1976D2 (Blue accent)                       │
│ Background:     #121212                                      │
│ Surface:        #1E1E1E (Cards/Elevated)                    │
│ Surface Light:  #2C2C2C (Elevated cards)                    │
│ Text Primary:   #FFFFFF                                      │
│ Text Secondary: #A0A0A0                                      │
│ Border:         #333333                                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      LIGHT THEME                             │
├─────────────────────────────────────────────────────────────┤
│ Primary:        #FFD700 (TrickBook Gold)                    │
│ Primary Dark:   #E6C200 (Pressed/Active state)              │
│ Secondary:      #1976D2 (Blue accent)                       │
│ Background:     #FFFFFF                                      │
│ Surface:        #F5F5F5 (Cards/Elevated)                    │
│ Surface Dark:   #EEEEEE (Elevated cards)                    │
│ Text Primary:   #1A1A1A                                      │
│ Text Secondary: #666666                                      │
│ Border:         #E0E0E0                                      │
└─────────────────────────────────────────────────────────────┘

Semantic Colors (both themes):
│ Success:        #4CAF50                                      │
│ Error:          #F44336                                      │
│ Warning:        #FF9800                                      │
│ Info:           #2196F3                                      │
│ Premium Badge:  #1DA1F2 (Verified Blue checkmark)           │
```

### Theme Support

**IMPORTANT:** The app must support both light and dark themes, automatically matching the user's system preference.

### Design Philosophy: Personal First, Social Second

**IMPORTANT:** TrickBook is primarily a **personal progression tool**, not a social media app. The home screen should feel like opening YOUR trick book - personal, focused, and motivating. Social features (Feed, Homies) are supplementary, not the core experience.

The app should ask: **"What are YOU working on?"** not "What is everyone else doing?"

---

## App Structure

### Bottom Navigation (5 tabs)

```
┌─────────────────────────────────────────────────────┐
│   🏠        📚         📍        👥        🎬      │
│  Home    TrickBook   Spots    Homies    Media      │
└─────────────────────────────────────────────────────┘
```

| Tab | Icon | Primary Function |
|-----|------|------------------|
| Home | House | Personal dashboard & feature hub |
| TrickBook | Book | Trick progression & Trickipedia |
| Spots | Map Pin | Location discovery |
| Homies | People | Social connections & messaging |
| Media | Film | Video content (Couch + Feed) |

---

## Screen Designs

### 1. HOME TAB - Personal Dashboard

The Home tab is the user's personal TrickBook - a dashboard that welcomes them and provides quick access to their progression and all features.

```
┌─────────────────────────────────────────┐
│ [Avatar]    Welcome back!    🔔 ⚙️      │
├─────────────────────────────────────────┤
│ 🎯 Current Goals                        │
│ ┌─────┐ ┌─────┐ ┌─────┐                │
│ │Trick│ │Trick│ │Trick│                │
│ └─────┘ └─────┘ └─────┘                │
├─────────────────────────────────────────┤
│ 📊 Your Progress                        │
│ [Stats and visual chart]                │
├─────────────────────────────────────────┤
│ Quick Access                            │
│ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐         │
│ │📚 │ │📍 │ │👥 │ │🎬 │ │📺 │         │
│ └───┘ └───┘ └───┘ └───┘ └───┘         │
├─────────────────────────────────────────┤
│ 🔥 Homie Activity (compact)             │
│ [2-3 recent updates from homies]        │
└─────────────────────────────────────────┘
```

**Key Elements:**
- Personalized greeting with profile avatar
- Settings (gear) and notifications (bell) in header
- Current Goals section showing tricks user is actively learning
- Progress stats (tricks landed, spots saved, etc.)
- Quick Access grid to all main features
- Compact homie activity preview (not the main focus)

### 2. TRICKBOOK TAB

**Trickipedia Browser:**
- Segmented control: "Trickipedia" | "My Lists" | "Homie Lists"
- 3-column grid of trick cards
- Each card: Image, name, difficulty badge (1-10)
- Filter by category and difficulty

**My TrickLists:**
- List of user's trick lists
- Each item: List name, progress bar, trick count
- Status badges: Not Started, Learning, Landed, Mastered

### 3. SPOTS TAB

**Map View:**
- Full-screen map with spot markers
- Category filter chips at top
- Tag filter (bowl, street, lights, indoor)
- Current location button
- List view toggle

**Spot Detail:**
- Hero image gallery (swipe)
- Spot name and location
- Tags as chips
- Map preview with "Get Directions" button
- "Add to My List" button

### 4. HOMIES TAB

**My Homies:**
- Segmented control: "My Homies" | "Find Riders" | "Requests"
- List of connected homies
- Each item: Avatar (with premium badge), name, sport chips
- Chat/View Profile buttons

**Chat:**
- WhatsApp-style messaging UI
- Message bubbles (sent vs received)
- Typing indicator

### 5. MEDIA TAB

**The Couch (Netflix-style):**
- Featured video hero
- "Continue Watching" row
- Category rows (Skateboarding, Snowboarding, etc.)
- Each video card: Thumbnail, title, duration

**The Feed (TikTok-style):**
- Full-screen vertical video/image scroll
- Overlay UI: Profile pic, Love, Respect, Comment, Share
- Swipe up for next post

---

## Component Library

### Cards
- Trick Card (image, name, difficulty)
- Spot Card (image, name, location, tags)
- User Card (avatar, name, sports)
- Video Card (thumbnail, title, duration)

### Badges
- Premium verified badge (blue check)
- Difficulty badge (1-10)
- Status badge (Not Started, Learning, Landed, Mastered)
- Count badge (notifications)
- Tag chips

### Navigation
- Bottom tab bar
- Top app bar (with back, title, actions)
- Segmented control

---

## Feed Post Layout

```
┌─────────────────────────────────────┐
│ [Full-bleed video/image]            │
│                                     │
│                              ┌───┐  │
│                              │ 👤│  │ ← Avatar
│                              ├───┤  │
│                              │ ❤️│  │ ← Love
│                              ├───┤  │
│                              │ 🤝│  │ ← Respect
│                              ├───┤  │
│                              │ 💬│  │ ← Comments
│                              ├───┤  │
│                              │ ↗️│  │ ← Share
│                              └───┘  │
│                                     │
│ @username                           │
│ Caption text goes here...           │
│ #skateboarding #kickflip            │
└─────────────────────────────────────┘
```

---

## Technical Constraints

- **React Native** - Design with RN components in mind
- **SafeAreaView** - Account for notches and home indicators
- **Minimum touch target:** 44x44 points
- **Theme Support:** MUST provide both light and dark theme variants
- **System Detection:** App follows device appearance settings automatically
