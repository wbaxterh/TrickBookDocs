---
sidebar_position: 3
---

# State Management

TrickBook uses a combination of React Context, local state, and AsyncStorage for state management.

## Authentication State

Global auth state using React Context.

### Context Definition

```javascript
// app/auth/context.js
import React from 'react';

const AuthContext = React.createContext();

export default AuthContext;
```

### Provider Setup

```javascript
// App.js
import AuthContext from './app/auth/context';

const App = () => {
  const [user, setUser] = useState(null);
  const [guest, setGuest] = useState(false);

  return (
    <AuthContext.Provider value={{ user, setUser, guest, setGuest }}>
      <NavigationContainer>
        {user ? <AppNavigator /> :
         guest ? <GuestNavigator /> :
         <AuthNavigator />}
      </NavigationContainer>
    </AuthContext.Provider>
  );
};
```

### Context Usage

```javascript
// In any component
import { useContext } from 'react';
import AuthContext from '../auth/context';

const MyComponent = () => {
  const { user, setUser } = useContext(AuthContext);

  const handleLogout = () => {
    setUser(null);
    authStorage.removeToken();
  };

  return (
    <View>
      <Text>Hello, {user?.name}</Text>
      <Button title="Logout" onPress={handleLogout} />
    </View>
  );
};
```

## Token Storage

Secure storage for JWT tokens using Expo Secure Store.

```javascript
// app/auth/storage.js
import * as SecureStore from 'expo-secure-store';

const key = 'authToken';

const storeToken = async (authToken) => {
  try {
    await SecureStore.setItemAsync(key, authToken);
  } catch (error) {
    console.log('Error storing auth token', error);
  }
};

const getToken = async () => {
  try {
    return await SecureStore.getItemAsync(key);
  } catch (error) {
    console.log('Error getting auth token', error);
    return null;
  }
};

const removeToken = async () => {
  try {
    await SecureStore.deleteItemAsync(key);
  } catch (error) {
    console.log('Error removing auth token', error);
  }
};

export default { storeToken, getToken, removeToken };
```

## Token Restoration

On app launch, restore user from stored token.

```javascript
// App.js
const restoreToken = async () => {
  const token = await authStorage.getToken();

  if (!token) return;

  // Decode JWT to get user data
  const decoded = jwtDecode(token);

  // Fetch complete user profile
  const response = await usersApi.getUser(decoded.email);

  if (response.ok) {
    setUser({ ...decoded, ...response.data });
  }
};

useEffect(() => {
  restoreToken();
}, []);
```

## Local Component State

Screen-level state using useState.

```javascript
// Typical screen state
const TrickListScreen = ({ route }) => {
  const [tricks, setTricks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState(null);

  const loadTricks = async () => {
    setLoading(true);
    const response = await tricksApi.getTricks(listId);

    if (response.ok) {
      setTricks(response.data);
    } else {
      setError('Failed to load tricks');
    }

    setLoading(false);
  };

  useEffect(() => {
    loadTricks();
  }, []);

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadTricks();
    setRefreshing(false);
  };

  return (
    <FlatList
      data={tricks}
      refreshing={refreshing}
      onRefresh={handleRefresh}
      // ...
    />
  );
};
```

## Guest Mode State

AsyncStorage for offline guest trick list.

```javascript
// Guest mode storage key
const GUEST_KEY = '@guest_trick_list';

// Save guest tricks
const saveGuestTricks = async (tricks) => {
  try {
    await AsyncStorage.setItem(GUEST_KEY, JSON.stringify(tricks));
  } catch (error) {
    console.log('Error saving guest tricks', error);
  }
};

// Load guest tricks
const loadGuestTricks = async () => {
  try {
    const data = await AsyncStorage.getItem(GUEST_KEY);
    return data ? JSON.parse(data) : [];
  } catch (error) {
    console.log('Error loading guest tricks', error);
    return [];
  }
};

// Usage in GuestTrickListScreen
const [tricks, setTricks] = useState([]);

useEffect(() => {
  const load = async () => {
    const stored = await loadGuestTricks();
    setTricks(stored);
  };
  load();
}, []);

const addTrick = async (name) => {
  const newTricks = [...tricks, { id: Date.now(), name, checked: false }];
  setTricks(newTricks);
  await saveGuestTricks(newTricks);
};
```

## Form State (Formik)

Form management with Formik and Yup validation.

```javascript
// app/components/forms/AppForm.js
import { Formik } from 'formik';

const AppForm = ({ initialValues, onSubmit, validationSchema, children }) => (
  <Formik
    initialValues={initialValues}
    onSubmit={onSubmit}
    validationSchema={validationSchema}
  >
    {() => <>{children}</>}
  </Formik>
);
```

### Login Form Example

```javascript
// LoginScreen.js
import * as Yup from 'yup';
import { AppForm, AppFormField, SubmitButton } from '../components/forms';

const validationSchema = Yup.object().shape({
  email: Yup.string().required().email().label('Email'),
  password: Yup.string().required().min(4).label('Password')
});

const LoginScreen = () => {
  const { setUser } = useContext(AuthContext);

  const handleSubmit = async ({ email, password }) => {
    const response = await authApi.login(email, password);

    if (!response.ok) {
      return setError('Invalid email or password');
    }

    const decoded = jwtDecode(response.data.token);
    setUser(decoded);
    authStorage.storeToken(response.data.token);
  };

  return (
    <AppForm
      initialValues={{ email: '', password: '' }}
      onSubmit={handleSubmit}
      validationSchema={validationSchema}
    >
      <AppFormField
        name="email"
        placeholder="Email"
        keyboardType="email-address"
        autoCapitalize="none"
      />

      <AppFormField
        name="password"
        placeholder="Password"
        secureTextEntry
      />

      <SubmitButton title="Login" />
    </AppForm>
  );
};
```

## Jotai (Available but Minimal)

Jotai is installed for atomic state but minimally used currently.

```javascript
import { atom, useAtom } from 'jotai';

// Define atom
const countAtom = atom(0);

// Use in component
const Counter = () => {
  const [count, setCount] = useAtom(countAtom);

  return (
    <Button
      title={`Count: ${count}`}
      onPress={() => setCount(c => c + 1)}
    />
  );
};
```

## State Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      App.js                              │
│  ┌─────────────────────────────────────────────────┐    │
│  │           AuthContext.Provider                   │    │
│  │  { user, setUser, guest, setGuest }             │    │
│  └─────────────────────────────────────────────────┘    │
│                          │                               │
│                          ▼                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Secure      │  │   Local      │  │  Async       │  │
│  │  Store       │  │   useState   │  │  Storage     │  │
│  │              │  │              │  │              │  │
│  │  JWT Token   │  │  UI State    │  │  Guest Data  │  │
│  │              │  │  Loading     │  │              │  │
│  │              │  │  Errors      │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Best Practices

1. **Use Context for global state** (auth, theme)
2. **Use local state for UI** (loading, modals)
3. **Use Secure Store for sensitive data** (tokens)
4. **Use AsyncStorage for non-sensitive persistence** (guest data)
5. **Use Formik for forms** (validation, submission)
