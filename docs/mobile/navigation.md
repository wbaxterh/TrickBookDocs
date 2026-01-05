---
sidebar_position: 2
---

# Navigation

TrickBook uses React Navigation 6 with a conditional navigation structure based on authentication state.

## Navigation Architecture

```
App.js
   │
   ├── AuthContext.Provider
   │
   └── NavigationContainer
       │
       ├── IF user logged in:
       │   └── AppNavigator (Bottom Tabs)
       │
       ├── ELSE IF guest mode:
       │   └── GuestNavigator (Bottom Tabs)
       │
       └── ELSE (not authenticated):
           └── AuthNavigator (Stack)
```

## Auth Navigator

Handles authentication screens before user login.

```javascript
// app/navigation/AuthNavigator.js
const AuthNavigator = () => (
  <Stack.Navigator screenOptions={{ headerShown: false }}>
    <Stack.Screen name="Welcome" component={WelcomeScreen} />
    <Stack.Screen name="Login" component={LoginScreen} />
    <Stack.Screen name="Register" component={RegisterScreen} />
  </Stack.Navigator>
);
```

**Screens:**
| Screen | Purpose |
|--------|---------|
| Welcome | Landing page with login/register/guest options |
| Login | Email/password authentication |
| Register | New user registration |

## App Navigator

Main navigation for authenticated users. Bottom tab layout.

```javascript
// app/navigation/AppNavigator.js
const AppNavigator = () => (
  <Tab.Navigator>
    <Tab.Screen
      name="Account"
      component={AccountNavigator}
      options={{
        tabBarIcon: ({ color, size }) => (
          <MaterialCommunityIcons name="account" color={color} size={size} />
        )
      }}
    />

    <Tab.Screen
      name="Create"
      component={CreateTrickListScreen}
      options={{
        tabBarButton: () => <NewListButton onPress={...} />
      }}
    />

    <Tab.Screen
      name="Tricks"
      component={TrickNavigator}
      options={{
        tabBarIcon: ({ color, size }) => (
          <MaterialCommunityIcons name="playlist-check" color={color} size={size} />
        )
      }}
    />
  </Tab.Navigator>
);
```

**Tabs:**
| Tab | Navigator | Purpose |
|-----|-----------|---------|
| Account | AccountNavigator | User profile & settings |
| Create | Direct screen | New trick list (+ button) |
| Tricks | TrickNavigator | Trick list management |

## Account Navigator

Stack navigation for account-related screens.

```javascript
// app/navigation/AccountNavigator.js
const AccountNavigator = () => (
  <Stack.Navigator>
    <Stack.Screen name="My Account" component={AccountScreen} />
    <Stack.Screen name="Edit Account" component={EditAccountDetailsScreen} />
    <Stack.Screen name="Trick Lists" component={TrickNavigator} />
    <Stack.Screen name="Settings" component={SettingsScreen} />
    <Stack.Screen name="Stats" component={StatsScreen} />
    <Stack.Screen name="Spin The Wheel" component={SpinTheWheelScreen} />
    <Stack.Screen name="Tutorials" component={TutorialScreen} />
    <Stack.Screen name="How To Use" component={HowToUse} />
  </Stack.Navigator>
);
```

## Trick Navigator

Stack navigation for trick list management.

```javascript
// app/navigation/TrickNavigator.js
const TrickNavigator = () => (
  <Stack.Navigator>
    <Stack.Screen name="My Trick Lists" component={ListTrickListsScreen} />

    <Stack.Screen
      name="Edit Trick List"
      component={EditTrickListScreen}
      options={{ presentation: 'modal' }}
    />

    <Stack.Screen name="Tricks" component={TrickListScreen} />

    <Stack.Screen
      name="Edit Trick"
      component={EditTrickScreen}
      options={{ presentation: 'modal' }}
    />

    <Stack.Screen
      name="Add Trick"
      component={AddTrickScreen}
      options={{ presentation: 'modal' }}
    />

    <Stack.Screen
      name="Trick Details"
      component={TrickDetailsScreen}
      options={{ presentation: 'modal' }}
    />
  </Stack.Navigator>
);
```

## Guest Navigator

Simplified navigation for guest mode (no account features).

```javascript
// app/navigation/GuestNavigator.js
const GuestNavigator = () => (
  <Tab.Navigator>
    <Tab.Screen name="Account" component={GuestAccountNavigator} />
    <Tab.Screen name="Add" component={AddTrickScreen} />
    <Tab.Screen name="Tricks" component={GuestTrickNavigator} />
  </Tab.Navigator>
);
```

## Route Constants

Centralized route names prevent typos.

```javascript
// app/navigation/routes.js
export default Object.freeze({
  // Trick routes
  TRICKS: "Tricks",
  EDITTRICK: "Edit Trick",
  ADDTRICK: "Add Trick",
  TRICKDETAILS: "Trick Details",

  // List routes
  TRICKLISTS: "Trick Lists",
  EDITTRICKLIST: "Edit Trick List",

  // Account routes
  ACCOUNT: "My Account",
  EDITACCOUNT: "Edit Account",
  SETTINGS: "Settings",
  STATS: "Stats",

  // Auth routes
  LOGIN: "Login",
  REGISTER: "Register",
  WELCOME: "Welcome",

  // Guest routes
  GUESTTRICKS: "Guest Tricks",

  // Feature routes
  TUTORIALS: "Tutorials",
  HOWTO: "How To Use",
  SPINTHEWHEEL: "Spin The Wheel"
});
```

**Usage:**
```javascript
import routes from '../navigation/routes';

navigation.navigate(routes.TRICKS);
```

## Navigation Theme

Custom theme matching app design.

```javascript
// app/navigation/navigationTheme.js
import { DefaultTheme } from '@react-navigation/native';
import colors from '../config/colors';

export default {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    primary: colors.primary,
    background: colors.background
  }
};
```

## Navigation Flow Examples

### Login Flow

```
WelcomeScreen
     │
     ├── "Login" button
     │       │
     │       ▼
     │   LoginScreen
     │       │
     │       ├── Success → setUser() → AppNavigator
     │       │
     │       └── Back → WelcomeScreen
     │
     └── "Continue as Guest" button
             │
             ▼
         setGuest(true) → GuestNavigator
```

### Trick List Flow

```
ListTrickListsScreen (list of all lists)
     │
     ├── Tap list card
     │       │
     │       ▼
     │   TrickListScreen (tricks in list)
     │       │
     │       ├── Tap "+" button
     │       │       │
     │       │       ▼
     │       │   AddTrickScreen (modal)
     │       │
     │       ├── Tap trick
     │       │       │
     │       │       ▼
     │       │   TrickDetailsScreen (modal)
     │       │
     │       └── Swipe trick → Edit/Delete actions
     │
     └── Tap "+" header button
             │
             ▼
         CreateTrickListScreen (modal)
```

## Header Configuration

Custom headers for different screens:

```javascript
// Add button to header
<Stack.Screen
  name="My Trick Lists"
  component={ListTrickListsScreen}
  options={({ navigation }) => ({
    headerRight: () => (
      <TouchableOpacity onPress={() => navigation.navigate(routes.CREATE)}>
        <MaterialCommunityIcons name="plus" size={24} />
      </TouchableOpacity>
    )
  })}
/>

// Modal close button
<Stack.Screen
  name="Add Trick"
  component={AddTrickScreen}
  options={({ navigation }) => ({
    presentation: 'modal',
    headerRight: () => (
      <TouchableOpacity onPress={() => navigation.goBack()}>
        <AppText>Close</AppText>
      </TouchableOpacity>
    )
  })}
/>
```

## New List Button

Custom center tab button with special styling.

```javascript
// app/navigation/NewListButton.js
const NewListButton = ({ onPress }) => (
  <TouchableOpacity onPress={onPress} style={styles.container}>
    <View style={styles.button}>
      <MaterialCommunityIcons name="plus" color="white" size={40} />
    </View>
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    top: -20  // Float above tab bar
  },
  button: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: colors.primary
  }
});
```
