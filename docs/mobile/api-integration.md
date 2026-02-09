---
sidebar_position: 4
---

# API Integration

The mobile app communicates with the backend using a custom fetch-based HTTP client with automatic auth token injection, retry logic, and modular API service files.

## API Client

```typescript
// src/lib/api/client.ts
import * as SecureStore from 'expo-secure-store';
import { API_BASE_URL } from '@/constants/api';

const getAuthToken = async () => {
  return await SecureStore.getItemAsync('authToken');
};

const request = async (url: string, options: RequestInit = {}) => {
  const token = await getAuthToken();

  const config: RequestInit = {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'x-auth-token': token ?? '',
      ...options.headers,
    },
  };

  // Retry logic
  let lastError;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const response = await fetch(`${API_BASE_URL}${url}`, config);
      const data = await response.json();
      return { ok: response.ok, data, status: response.status };
    } catch (error) {
      lastError = error;
      await new Promise(r => setTimeout(r, 1000));
    }
  }
  throw lastError;
};

export const apiClient = {
  get: (url: string) => request(url),
  post: (url: string, body: object) =>
    request(url, { method: 'POST', body: JSON.stringify(body) }),
  put: (url: string, body: object) =>
    request(url, { method: 'PUT', body: JSON.stringify(body) }),
  delete: (url: string) =>
    request(url, { method: 'DELETE' }),
};
```

### API Configuration

```typescript
// src/constants/api.ts
const DEV_URL = 'http://10.117.162.103:9000/api';
const PROD_URL = 'https://api.thetrickbook.com/api';

export const API_BASE_URL = __DEV__ ? DEV_URL : PROD_URL;

// Socket.IO
const DEV_SOCKET = 'http://10.117.162.103:9000';
const PROD_SOCKET = 'https://api.thetrickbook.com';
export const SOCKET_URL = __DEV__ ? DEV_SOCKET : PROD_SOCKET;
```

### Request Features

| Feature | Details |
|---------|---------|
| Auth token | Auto-injected from Expo Secure Store |
| Header | `x-auth-token` (not Bearer) |
| Retry | 3 attempts with 1s delay |
| Timeout | 30s default, 120s for uploads |
| Content-Type | `application/json` (default) |

## API Service Modules

Each feature has a dedicated API service file in `src/lib/api/`.

### Authentication (`auth.ts`)

```typescript
// src/lib/api/auth.ts
import { apiClient } from './client';

export const authApi = {
  login: (email: string, password: string) =>
    apiClient.post('/auth', { email, password }),

  googleAuth: (idToken: string) =>
    apiClient.post('/auth/google-auth', { idToken }),

  appleAuth: (identityToken: string, user?: object) =>
    apiClient.post('/auth/apple-auth', { identityToken, user }),

  register: (name: string, email: string, password: string) =>
    apiClient.post('/users', { name, email, password }),

  getCurrentUser: () =>
    apiClient.get('/user/me'),
};
```

### TrickBook (`trickbook.ts`)

```typescript
// src/lib/api/trickbook.ts
export const trickbookApi = {
  // Trick Lists
  getTrickLists: () => apiClient.get('/listings'),
  createTrickList: (data: { name: string }) => apiClient.post('/listings', data),
  deleteTrickList: (id: string) => apiClient.delete(`/listings/${id}`),
  toggleVisibility: (id: string) => apiClient.put(`/listings/${id}/visibility`, {}),

  // Individual Tricks
  getTricks: (listId: string) => apiClient.get(`/listing?list_id=${listId}`),
  addTrick: (data: object) => apiClient.post('/listing', data),
  updateTrick: (id: string, data: object) => apiClient.put(`/listing/${id}`, data),
  deleteTrick: (id: string) => apiClient.delete(`/listing/${id}`),

  // Trickipedia
  getTrickipedia: (params?: { category?: string; difficulty?: string; search?: string }) =>
    apiClient.get(`/trickipedia${buildQuery(params)}`),
  getTrick: (id: string) => apiClient.get(`/trickipedia/${id}`),
};
```

### Feed (`feed.ts`)

```typescript
// src/lib/api/feed.ts
export const feedApi = {
  getFeed: () => apiClient.get('/feed'),
  getPost: (id: string) => apiClient.get(`/feed/${id}`),
  createPost: (data: object) => apiClient.post('/feed/posts', data),
  deletePost: (id: string) => apiClient.delete(`/feed/${id}`),

  // Reactions
  reactToPost: (postId: string, type: 'love' | 'respect') =>
    apiClient.post(`/feed/${postId}/reactions`, { type }),

  // Comments
  getComments: (postId: string) => apiClient.get(`/feed/${postId}/comments`),
  addComment: (postId: string, content: string) =>
    apiClient.post(`/feed/${postId}/comments`, { content }),
  deleteComment: (postId: string, commentId: string) =>
    apiClient.delete(`/feed/${postId}/comments/${commentId}`),
};
```

### Spots (`spots.ts`)

```typescript
// src/lib/api/spots.ts
export const spotsApi = {
  getSpots: () => apiClient.get('/spots'),
  getSpot: (id: string) => apiClient.get(`/spots/${id}`),
  createSpot: (data: object) => apiClient.post('/spots', data),
  updateSpot: (id: string, data: object) => apiClient.put(`/spots/${id}`, data),
  deleteSpot: (id: string) => apiClient.delete(`/spots/${id}`),
  searchPlaces: (query: string) => apiClient.get(`/spots/places-search?query=${query}`),
  getSportTypes: () => apiClient.get('/spots/sport-types'),
};
```

### Spot Reviews (`spotReviews.ts`)

```typescript
// src/lib/api/spotReviews.ts
export const spotReviewsApi = {
  getReviews: (spotId: string) => apiClient.get(`/spot-reviews?spotId=${spotId}`),
  createReview: (data: object) => apiClient.post('/spot-reviews', data),
  updateReview: (id: string, data: object) => apiClient.put(`/spot-reviews/${id}`, data),
  deleteReview: (id: string) => apiClient.delete(`/spot-reviews/${id}`),
};
```

### Spot Lists (`spotlists.ts`)

```typescript
// src/lib/api/spotlists.ts
export const spotlistsApi = {
  getSpotLists: () => apiClient.get('/spotlists'),
  getSpotList: (id: string) => apiClient.get(`/spotlists/${id}`),
  createSpotList: (data: object) => apiClient.post('/spotlists', data),
  deleteSpotList: (id: string) => apiClient.delete(`/spotlists/${id}`),
  addSpotToList: (listId: string, spotId: string) =>
    apiClient.post(`/spotlists/${listId}/spots`, { spotId }),
  removeSpotFromList: (listId: string, spotId: string) =>
    apiClient.delete(`/spotlists/${listId}/spots/${spotId}`),
  getUsage: () => apiClient.get('/spotlists/usage'),
};
```

### Homies (`homies.ts`)

```typescript
// src/lib/api/homies.ts
export const homiesApi = {
  getHomies: (userId: string) => apiClient.get(`/users/${userId}/homies`),
  sendHomieRequest: (targetId: string) =>
    apiClient.post(`/users/homie-request`, { targetId }),
  respondToRequest: (requestId: string, accept: boolean) =>
    apiClient.post(`/users/homie-respond`, { requestId, accept }),
  getHomieStatus: (targetId: string) =>
    apiClient.get(`/user/homie-status/${targetId}`),
};
```

### Messages (`messages.ts`)

```typescript
// src/lib/api/messages.ts
export const messagesApi = {
  getConversations: () => apiClient.get('/dm/conversations'),
  getConversation: (id: string) => apiClient.get(`/dm/conversations/${id}`),
  getMessages: (conversationId: string) =>
    apiClient.get(`/dm/messages/${conversationId}`),
  sendMessage: (data: { conversationId: string; content: string }) =>
    apiClient.post('/dm/messages', data),
  markAsRead: (messageId: string) =>
    apiClient.put(`/dm/messages/${messageId}/read`, {}),
};
```

### The Couch (`couch.ts`)

```typescript
// src/lib/api/couch.ts
export const couchApi = {
  getVideos: () => apiClient.get('/couch'),
  getCollections: () => apiClient.get('/couch/collections'),
  getFeatured: () => apiClient.get('/couch/featured'),
};
```

### User (`user.ts`)

```typescript
// src/lib/api/user.ts
export const userApi = {
  getProfile: (id: string) => apiClient.get(`/user/${id}`),
  getPublicProfile: (id: string) => apiClient.get(`/user/${id}/public`),
  getStats: (id: string) => apiClient.get(`/user/${id}/stats`),
  getActivity: (id: string) => apiClient.get(`/user/${id}/activity`),
  updateProfile: (id: string, data: object) => apiClient.put(`/user/${id}`, data),
  getUserCount: () => apiClient.get('/user/count'),
};
```

### Upload (`upload.ts`)

```typescript
// src/lib/api/upload.ts
export const uploadApi = {
  uploadImage: async (uri: string, type: string = 'image/jpeg') => {
    const formData = new FormData();
    formData.append('file', { uri, type, name: 'upload.jpg' } as any);

    const token = await SecureStore.getItemAsync('authToken');
    const response = await fetch(`${API_BASE_URL}/upload`, {
      method: 'POST',
      headers: { 'x-auth-token': token ?? '' },
      body: formData,
    });
    return response.json();
  },

  uploadVideo: async (uri: string) => {
    // Similar but with 120s timeout
  },
};
```

## Using with React Query

API services are typically consumed through React Query hooks:

```typescript
// In a screen component
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { spotsApi } from '@/lib/api/spots';

const SpotsScreen = () => {
  const queryClient = useQueryClient();

  // Fetch spots
  const { data: spots, isLoading } = useQuery({
    queryKey: ['spots'],
    queryFn: spotsApi.getSpots,
  });

  // Create spot mutation
  const createSpot = useMutation({
    mutationFn: spotsApi.createSpot,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['spots'] });
    },
  });

  // ...
};
```

## Error Handling

```typescript
const { data, error } = useQuery({
  queryKey: ['trickLists'],
  queryFn: async () => {
    const response = await trickbookApi.getTrickLists();
    if (!response.ok) {
      if (response.status === 401) {
        // Token expired - logout
        useAuthStore.getState().logout();
      }
      throw new Error(`API error: ${response.status}`);
    }
    return response.data;
  },
});
```
