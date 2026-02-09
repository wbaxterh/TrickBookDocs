---
sidebar_position: 3
---

# State Management

TrickBook uses Zustand for auth state, React Query for server state, and React Context for theming.

## Overview

| State Type | Solution | Purpose |
|------------|----------|---------|
| Auth state | Zustand | User session, token, login/logout |
| Server state | React Query | API data fetching, caching, mutations |
| Theme | React Context | Dark/Light mode |
| Form state | React Hook Form + Zod | Form handling and validation |
| Secure storage | Expo Secure Store | JWT token persistence |

## Authentication State (Zustand)

Global auth state using Zustand with Expo Secure Store for persistence.

### Store Definition

```typescript
// src/lib/stores/authStore.ts
import { create } from 'zustand';
import * as SecureStore from 'expo-secure-store';
import jwtDecode from 'jwt-decode';

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  login: (token: string, user: User) => Promise<void>;
  logout: () => Promise<void>;
  loadStoredAuth: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  isLoading: true,

  login: async (token, user) => {
    await SecureStore.setItemAsync('authToken', token);
    set({ user, token, isLoading: false });
  },

  logout: async () => {
    await SecureStore.deleteItemAsync('authToken');
    set({ user: null, token: null });
  },

  loadStoredAuth: async () => {
    const token = await SecureStore.getItemAsync('authToken');
    if (token) {
      const decoded = jwtDecode(token);
      // Fetch full user profile from API
      const user = await fetchUserProfile(decoded);
      set({ user, token, isLoading: false });
    } else {
      set({ isLoading: false });
    }
  },
}));
```

### Usage in Components

```typescript
import { useAuthStore } from '@/lib/stores/authStore';

const ProfileScreen = () => {
  const { user, logout } = useAuthStore();

  return (
    <View>
      <Text>Hello, {user?.name}</Text>
      <Button title="Logout" onPress={logout} />
    </View>
  );
};
```

## Server State (React Query)

All API data is managed through React Query for automatic caching, background refetching, and optimistic updates.

### Query Client Setup

```typescript
// app/_layout.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      retry: 2,
    },
  },
});

export default function RootLayout() {
  return (
    <QueryClientProvider client={queryClient}>
      {/* ... */}
    </QueryClientProvider>
  );
}
```

### Fetching Data (useQuery)

```typescript
import { useQuery } from '@tanstack/react-query';
import { trickbookApi } from '@/lib/api/trickbook';

const TrickListsScreen = () => {
  const {
    data: trickLists,
    isLoading,
    error,
    refetch,
  } = useQuery({
    queryKey: ['trickLists'],
    queryFn: trickbookApi.getTrickLists,
  });

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;

  return (
    <FlatList
      data={trickLists}
      refreshing={false}
      onRefresh={refetch}
      renderItem={({ item }) => <TrickListCard list={item} />}
    />
  );
};
```

### Mutations (useMutation)

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

const CreateTrickList = () => {
  const queryClient = useQueryClient();

  const createMutation = useMutation({
    mutationFn: trickbookApi.createTrickList,
    onSuccess: () => {
      // Invalidate and refetch trick lists
      queryClient.invalidateQueries({ queryKey: ['trickLists'] });
    },
  });

  const handleCreate = (name: string) => {
    createMutation.mutate({ name });
  };

  return (
    <Button
      title="Create List"
      onPress={() => handleCreate('New List')}
      disabled={createMutation.isPending}
    />
  );
};
```

### Query Key Patterns

```typescript
// Common query keys used across the app
const queryKeys = {
  trickLists: ['trickLists'],
  trickList: (id: string) => ['trickList', id],
  tricks: (listId: string) => ['tricks', listId],
  trickipedia: (filters?: object) => ['trickipedia', filters],
  spots: ['spots'],
  spot: (id: string) => ['spot', id],
  spotLists: ['spotLists'],
  spotReviews: (spotId: string) => ['spotReviews', spotId],
  feed: ['feed'],
  feedPost: (id: string) => ['feedPost', id],
  homies: ['homies'],
  conversations: ['conversations'],
  messages: (conversationId: string) => ['messages', conversationId],
  userProfile: (id: string) => ['userProfile', id],
  userStats: (id: string) => ['userStats', id],
};
```

## Theme State (React Context)

Dark/Light mode managed via React Context with persistent preference.

```typescript
// src/lib/providers/ThemeProvider.tsx
import { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

type Theme = 'dark' | 'light';

const ThemeContext = createContext<{
  theme: Theme;
  toggleTheme: () => void;
}>({ theme: 'dark', toggleTheme: () => {} });

export const ThemeProvider = ({ children }) => {
  const [theme, setTheme] = useState<Theme>('dark');

  useEffect(() => {
    AsyncStorage.getItem('theme').then((stored) => {
      if (stored) setTheme(stored as Theme);
    });
  }, []);

  const toggleTheme = () => {
    const next = theme === 'dark' ? 'light' : 'dark';
    setTheme(next);
    AsyncStorage.setItem('theme', next);
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => useContext(ThemeContext);
```

## Form State (React Hook Form + Zod)

Forms use React Hook Form for efficient re-renders and Zod for schema validation.

```typescript
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(5, 'Password must be at least 5 characters'),
});

type LoginForm = z.infer<typeof loginSchema>;

const LoginScreen = () => {
  const { login } = useAuthStore();

  const {
    control,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  const onSubmit = async (data: LoginForm) => {
    const response = await authApi.login(data.email, data.password);
    if (response.token) {
      await login(response.token, response.user);
    }
  };

  return (
    <View>
      <Controller
        control={control}
        name="email"
        render={({ field: { onChange, value } }) => (
          <TextInput
            placeholder="Email"
            value={value}
            onChangeText={onChange}
            keyboardType="email-address"
            autoCapitalize="none"
          />
        )}
      />
      {errors.email && <Text>{errors.email.message}</Text>}

      <Controller
        control={control}
        name="password"
        render={({ field: { onChange, value } }) => (
          <TextInput
            placeholder="Password"
            value={value}
            onChangeText={onChange}
            secureTextEntry
          />
        )}
      />
      {errors.password && <Text>{errors.password.message}</Text>}

      <Button
        title={isSubmitting ? 'Logging in...' : 'Login'}
        onPress={handleSubmit(onSubmit)}
        disabled={isSubmitting}
      />
    </View>
  );
};
```

## State Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    app/_layout.tsx                            │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Zustand     │  │ React Query  │  │  ThemeProvider    │  │
│  │   AuthStore   │  │  Client      │  │  (Context)        │  │
│  │              │  │              │  │                    │  │
│  │  user        │  │  queries     │  │  theme: dark/light│  │
│  │  token       │  │  mutations   │  │  toggleTheme()    │  │
│  │  login()     │  │  cache       │  │                    │  │
│  │  logout()    │  │              │  │                    │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────────────┘  │
│         │                  │                                  │
│         ▼                  ▼                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Expo         │  │  API Client  │  │  React Hook Form │  │
│  │  Secure Store │  │  (fetch)     │  │  + Zod           │  │
│  │              │  │              │  │                    │  │
│  │  JWT Token   │  │  Auto-auth   │  │  Form validation  │  │
│  │  (encrypted) │  │  Retry logic │  │  Type inference    │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Migration Notes

The app is migrating from legacy patterns to the new stack:

| Old Pattern | New Pattern | Status |
|-------------|-------------|--------|
| React Context (auth) | Zustand authStore | Migrated |
| Manual useState/useEffect | React Query | Migrated |
| Formik + Yup | React Hook Form + Zod | Migrated |
| AsyncStorage (tokens) | Expo Secure Store | Migrated |
| apisauce | Custom fetch client | Migrated |
| Jotai atoms | Zustand stores | Migrated |

:::note
Some legacy code in `app/auth/` and `app/api/` still uses the old patterns and is being gradually migrated to `src/lib/`.
:::
