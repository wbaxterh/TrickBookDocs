---
sidebar_position: 4
---

# API Integration

The mobile app communicates with the backend using apisauce, a lightweight axios wrapper.

## API Client Setup

```javascript
// app/api/client.js
import { create } from 'apisauce';

const apiClient = create({
  baseURL: "https://api.thetrickbook.com/api",
});

export default apiClient;
```

## Response Format

Apisauce returns standardized responses:

```javascript
{
  ok: true,           // Was the request successful?
  data: {...},        // Response data
  status: 200,        // HTTP status code
  problem: null,      // Error type if failed
  originalError: null // Original error object
}
```

**Problem types:**
- `CLIENT_ERROR` - 4xx errors
- `SERVER_ERROR` - 5xx errors
- `TIMEOUT_ERROR` - Request timed out
- `NETWORK_ERROR` - No network connection
- `CANCEL_ERROR` - Request cancelled

## API Modules

### Authentication API

```javascript
// app/api/auth.js
import client from './client';

const login = (email, password) =>
  client.post('/auth', { email, password });

const googleAuth = (idToken) =>
  client.post('/auth/google-auth', { idToken });

export default {
  login,
  googleAuth
};
```

**Usage:**
```javascript
import authApi from '../api/auth';

const handleLogin = async (email, password) => {
  const response = await authApi.login(email, password);

  if (!response.ok) {
    console.log('Login failed:', response.problem);
    return;
  }

  const token = response.data.token;
  // Store token and decode user...
};
```

### Users API

```javascript
// app/api/users.js
import client from './client';

const addUser = (user) =>
  client.post('/users', user);

const getUser = (email) =>
  client.get('/users', { email });

const deleteUser = (id) =>
  client.delete(`/users/${id}`);

export default {
  addUser,
  getUser,
  deleteUser
};
```

### Trick Lists API

```javascript
// app/api/tricks.js
import client from './client';

const endpoint = '/listings';

const getTricks = (userId) =>
  client.get(endpoint, { userId });

const addTrickList = (userId, title) =>
  client.post(endpoint, { userId, title });

const deleteTrickList = (listId) =>
  client.delete(`${endpoint}/${listId}`);

const editTrickList = (listId, title) =>
  client.put(`${endpoint}/${listId}`, { title });

export default {
  getTricks,
  addTrickList,
  deleteTrickList,
  editTrickList
};
```

### Individual Tricks API

```javascript
// app/api/trick.js
import client from './client';

const endpoint = '/listing';

const getTrick = (listId) =>
  client.get(endpoint, { list_id: listId });

const addTrick = (listId, name) =>
  client.put(endpoint, { list_id: listId, name, checked: false });

const updateTrick = (trickId, checked) =>
  client.put(`${endpoint}/${trickId}`, { checked });

const deleteTrick = (trickId) =>
  client.delete(`${endpoint}/${trickId}`);

const editTrick = (trickId, name) =>
  client.put(`${endpoint}/edit`, { trickId, name });

export default {
  getTrick,
  addTrick,
  updateTrick,
  deleteTrick,
  editTrick
};
```

### Image Upload API

```javascript
// app/api/image.js
import client from './client';
import * as ImageManipulator from 'expo-image-manipulator';
import FormData from 'form-data';

const endpoint = '/image';

const getImage = (email) =>
  client.get(endpoint, { email });

const setImage = async (email, imageUri) => {
  // Resize image before upload
  const manipResult = await ImageManipulator.manipulateAsync(
    imageUri,
    [{ resize: { width: 640 } }],
    { compress: 0.2, format: ImageManipulator.SaveFormat.JPEG }
  );

  // Create form data
  const formData = new FormData();
  formData.append('email', email);
  formData.append('file', {
    uri: manipResult.uri,
    type: 'image/jpeg',
    name: 'profile.jpg'
  });

  return client.post(`${endpoint}/upload`, formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  });
};

export default {
  getImage,
  setImage
};
```

## Adding Auth Token to Requests

For protected endpoints, include the JWT token:

```javascript
// Set auth token for subsequent requests
import authStorage from '../auth/storage';

const setAuthToken = async () => {
  const token = await authStorage.getToken();
  if (token) {
    apiClient.setHeader('x-auth-token', token);
  }
};

// Call on app startup after token restoration
setAuthToken();
```

## Error Handling Pattern

```javascript
const loadData = async () => {
  setLoading(true);
  setError(null);

  const response = await api.getData();

  if (!response.ok) {
    // Handle specific error types
    if (response.problem === 'NETWORK_ERROR') {
      setError('No internet connection');
    } else if (response.status === 401) {
      setError('Please login again');
      // Redirect to login
    } else if (response.status === 403) {
      setError('Access denied');
    } else {
      setError('Something went wrong');
    }

    setLoading(false);
    return;
  }

  setData(response.data);
  setLoading(false);
};
```

## Retry Logic (Optional Enhancement)

```javascript
const fetchWithRetry = async (apiCall, maxRetries = 3) => {
  let lastError;

  for (let i = 0; i < maxRetries; i++) {
    const response = await apiCall();

    if (response.ok) {
      return response;
    }

    // Don't retry client errors
    if (response.problem === 'CLIENT_ERROR') {
      return response;
    }

    lastError = response;

    // Wait before retry (exponential backoff)
    await new Promise(r => setTimeout(r, Math.pow(2, i) * 1000));
  }

  return lastError;
};

// Usage
const response = await fetchWithRetry(() => api.getData());
```

## Offline Handling

```javascript
import NetInfo from '@react-native-community/netinfo';

const checkConnection = async () => {
  const state = await NetInfo.fetch();
  return state.isConnected;
};

const loadData = async () => {
  const isConnected = await checkConnection();

  if (!isConnected) {
    // Load from cache or show offline message
    const cached = await AsyncStorage.getItem('cachedData');
    if (cached) {
      setData(JSON.parse(cached));
    }
    setError('You are offline');
    return;
  }

  // Normal API call
  const response = await api.getData();
  // ...
};
```

## API Call Examples

### Fetching Trick Lists

```javascript
// ListTrickListsScreen.js
const [lists, setLists] = useState([]);
const { user } = useContext(AuthContext);

useEffect(() => {
  loadLists();
}, []);

const loadLists = async () => {
  const response = await tricksApi.getTricks(user.userId);

  if (response.ok) {
    setLists(response.data);
  }
};
```

### Creating a Trick List

```javascript
const handleCreate = async (title) => {
  const response = await tricksApi.addTrickList(user.userId, title);

  if (response.ok) {
    navigation.navigate(routes.TRICKS, { listId: response.data._id });
  } else {
    Alert.alert('Error', 'Could not create list');
  }
};
```

### Toggling Trick Completion

```javascript
const handleToggle = async (trickId, currentStatus) => {
  // Optimistic update
  setTricks(prev =>
    prev.map(t => t._id === trickId ? { ...t, checked: !currentStatus } : t)
  );

  const response = await trickApi.updateTrick(trickId, !currentStatus);

  if (!response.ok) {
    // Revert on failure
    setTricks(prev =>
      prev.map(t => t._id === trickId ? { ...t, checked: currentStatus } : t)
    );
    Alert.alert('Error', 'Could not update trick');
  }
};
```
