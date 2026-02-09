---
sidebar_position: 2
---

# Navigation

TrickBook uses Expo Router for file-based navigation, similar to Next.js. Routes are defined by the file system structure in the `app/` directory.

## Navigation Architecture

```
app/
   │
   ├── _layout.tsx              # Root layout (providers + auth gate)
   │       │
   │       ├── IF user authenticated:
   │       │   └── (tabs)/_layout.tsx (Bottom Tab Navigator)
   │       │
   │       └── ELSE (not authenticated):
   │           └── (auth)/_layout.tsx (Stack Navigator)
   │
   ├── (auth)/                   # Auth group
   │   ├── welcome.tsx
   │   ├── login.tsx
   │   └── register.tsx
   │
   ├── (tabs)/                   # Main tab group
   │   ├── index.tsx             # Home tab
   │   ├── trickbook/            # TrickBook tab
   │   ├── spots/                # Spots tab
   │   ├── homies/               # Homies tab
   │   ├── media/                # Media tab
   │   └── profile/              # Profile (hidden tab)
   │
   └── profile/                  # Profile settings (stack)
       ├── edit.tsx
       ├── settings.tsx
       └── ...
```

## Root Layout

The root layout sets up providers and conditionally renders auth or main app screens.

```typescript
// app/_layout.tsx
import { Stack } from 'expo-router';
import { QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from '@/lib/providers/ThemeProvider';
import { useAuthStore } from '@/lib/stores/authStore';

export default function RootLayout() {
  const { user, isLoading, loadStoredAuth } = useAuthStore();

  useEffect(() => {
    loadStoredAuth();
  }, []);

  if (isLoading) return <SplashScreen />;

  return (
    <SafeAreaProvider>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <Stack screenOptions={{ headerShown: false }}>
            {user ? (
              <Stack.Screen name="(tabs)" />
            ) : (
              <Stack.Screen name="(auth)" />
            )}
          </Stack>
        </ThemeProvider>
      </QueryClientProvider>
    </SafeAreaProvider>
  );
}
```

## Auth Group

Handles authentication screens before user login.

```typescript
// app/(auth)/_layout.tsx
import { Stack } from 'expo-router';

export default function AuthLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="welcome" />
      <Stack.Screen name="login" />
      <Stack.Screen name="register" />
    </Stack>
  );
}
```

**Screens:**
| Screen | File | Purpose |
|--------|------|---------|
| Welcome | `welcome.tsx` | Landing page with login/register options |
| Login | `login.tsx` | Email/password + Google SSO + Apple Sign-In |
| Register | `register.tsx` | New user registration |

## Tab Navigator

Main navigation for authenticated users with 5 tabs.

```typescript
// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function TabLayout() {
  return (
    <Tabs>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home" color={color} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="trickbook"
        options={{
          title: 'TrickBook',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="list" color={color} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="spots"
        options={{
          title: 'Spots',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="location" color={color} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="homies"
        options={{
          title: 'Homies',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="people" color={color} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="media"
        options={{
          title: 'Media',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="play-circle" color={color} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          href: null, // Hidden from tab bar
        }}
      />
    </Tabs>
  );
}
```

**Tabs:**
| Tab | Directory | Purpose |
|-----|-----------|---------|
| Home | `index.tsx` | Dashboard with stats, goals, activity |
| TrickBook | `trickbook/` | Trick list management and Trickipedia |
| Spots | `spots/` | Spot discovery, maps, reviews |
| Homies | `homies/` | Friend network and profiles |
| Media | `media/` | Social feed and The Couch |
| Profile | `profile/` | User profile (hidden from tab bar, accessed via Home) |

## Profile Routes

Stack navigation for profile and settings screens.

```
app/profile/
├── index.tsx              # User profile view
├── edit.tsx               # Edit profile info
├── settings.tsx           # App settings
├── account.tsx            # Account management
├── change-password.tsx    # Password update
├── notifications.tsx      # Notification preferences
├── privacy.tsx            # Privacy settings
├── theme.tsx              # Dark/Light theme selection
└── support.tsx            # Help and support
```

## Navigation Patterns

### Programmatic Navigation

```typescript
import { useRouter } from 'expo-router';

const MyComponent = () => {
  const router = useRouter();

  // Navigate to a route
  router.push('/spots/details/123');

  // Navigate back
  router.back();

  // Replace current screen
  router.replace('/(auth)/login');
};
```

### Link Component

```typescript
import { Link } from 'expo-router';

<Link href="/trickbook/list/123">
  View Trick List
</Link>
```

### Dynamic Routes

```typescript
// app/(tabs)/spots/[id].tsx
import { useLocalSearchParams } from 'expo-router';

export default function SpotDetails() {
  const { id } = useLocalSearchParams<{ id: string }>();
  // Fetch spot data using id...
}
```

## Navigation Flow Examples

### Login Flow

```
(auth)/welcome.tsx
     │
     ├── "Login" button
     │       │
     │       ▼
     │   (auth)/login.tsx
     │       │
     │       ├── Email/Password → POST /api/auth
     │       ├── Google SSO → OAuth2 flow
     │       └── Apple Sign-In → Apple auth flow
     │       │
     │       ├── Success → authStore.login()
     │       │              → Root layout redirects to (tabs)
     │       │
     │       └── Back → welcome.tsx
     │
     └── "Register" button
             │
             ▼
         (auth)/register.tsx
```

### Trick List Flow

```
(tabs)/trickbook/index.tsx (list of all trick lists)
     │
     ├── Tap list card
     │       │
     │       ▼
     │   (tabs)/trickbook/[listId].tsx (tricks in list)
     │       │
     │       ├── Tap "+" → Add trick modal
     │       │
     │       ├── Tap trick → Trick detail view
     │       │
     │       └── Swipe trick → Edit/Delete actions
     │
     └── Tap "+" header button
             │
             ▼
         Create new trick list
```

### Spots Flow

```
(tabs)/spots/index.tsx (map view + spot list)
     │
     ├── Tap spot marker on map
     │       │
     │       ▼
     │   Spot detail view
     │       │
     │       ├── View reviews
     │       ├── Add review (StarRatingInput)
     │       ├── Add to spot list
     │       └── Get directions
     │
     └── "My Lists" button
             │
             ▼
         Spot list management
```

## Key Differences from React Navigation

| Feature | Old (React Navigation 6) | New (Expo Router) |
|---------|--------------------------|-------------------|
| Route definition | `<Stack.Screen component={...}>` | File-based (`app/page.tsx`) |
| Navigation | `navigation.navigate('Screen')` | `router.push('/path')` |
| Params | `route.params.id` | `useLocalSearchParams()` |
| Deep linking | Manual config | Automatic from file structure |
| Type safety | Manual types | Generated from file paths |
| Layouts | Inline in navigators | `_layout.tsx` files |
| Groups | Not supported | `(groupName)/` directories |
