# Car Inspection API Documentation

## Base URL
- **Local Development**: `http://localhost:3000`
- **Production**: `https://your-api-gateway-url.amazonaws.com`

## Authentication
All endpoints (except register/login) require JWT authentication.

**Header:**
```
Authorization: Bearer <your-jwt-token>
```

---

## 1. Authentication APIs

### 1.1 Register User
**POST** `/api/auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+1234567890",
  "role": "user"
}
```

**Note:** This project uses **OTP-only authentication for all roles** (no password anywhere). After register, an OTP is sent to email and **no JWT is returned** until OTP verification.

**Response (201):**
```json
{
  "statusCode": 201,
  "message": "User registered. OTP sent to email for verification",
  "data": {
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user",
      "status": "inactive"
    },
    "token": null,
    "otpRequired": true
  }
}
```

---

### 1.2 Login
**POST** `/api/auth/login`

**Request Body (OTP-only for all roles):**
```json
{
  "email": "user@example.com"
}
```

**Response (200) - OTP Required:**
```json
{
  "statusCode": 200,
  "message": "OTP sent to email; verify to complete login",
  "data": {
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user"
    },
    "token": null,
    "otpRequired": true
  }
}
```

---

### 1.3 Send OTP
**POST** `/api/auth/send-otp`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "OTP sent to email",
  "data": {
    "message": "OTP sent to your email."
  }
}
```

**Note:** Available for **all roles**. Use this to resend OTP if needed.

---

### 1.4 Verify OTP
**POST** `/api/auth/verify-otp`

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "OTP verified successfully",
  "data": {
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Note:** OTP is valid for 10 minutes. After verification, user receives JWT token for authenticated requests.

---

## 2. User Management APIs (Admin Only)

### 2.1 Create User
**POST** `/api/users`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Request Body:**
```json
{
  "email": "inspector@example.com",
  "firstName": "Jane",
  "lastName": "Smith",
  "phone": "+1234567890",
  "role": "inspector"
}
```

**Response (201):**
```json
{
  "statusCode": 201,
  "message": "User created successfully",
  "data": {
    "user": {
      "id": "507f1f77bcf86cd799439012",
      "email": "inspector@example.com",
      "firstName": "Jane",
      "lastName": "Smith",
      "role": "inspector",
      "status": "inactive"
    }
  }
}
```

---

### 2.2 Get All Users
**GET** `/api/users?page=1&limit=10&search=john&role=inspector&status=active&sortBy=createdAt&sortOrder=DESC`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Query Parameters:**
- `page` (optional, default: 1) - Page number
- `limit` (optional, default: 10, max: 100) - Items per page
- `search` (optional) - Search in email, firstName, lastName, phone
- `role` (optional) - Filter by role: `admin`, `inspector`, `user`
  - **Note:** By default, admin users are excluded from results. To see admin users, explicitly filter by `role=admin`.
- `status` (optional) - Filter by status: `active`, `blocked`, `inactive`
- `sortBy` (optional, default: `id`) - Sort field: `id`, `email`, `firstName`, `lastName`, `role`, `status`, `createdAt`
- `sortOrder` (optional, default: `DESC`) - Sort order: `ASC`, `DESC`

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Users retrieved successfully",
  "data": {
    "users": [
      {
        "id": "507f1f77bcf86cd799439011",
        "email": "user@example.com",
        "firstName": "John",
        "lastName": "Doe",
        "role": "user",
        "status": "active"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalCount": 50,
      "limit": 10,
      "hasNextPage": true,
      "hasPreviousPage": false
    },
    "filters": {
      "search": "john",
      "role": "inspector",
      "status": "active",
      "sortBy": "createdAt",
      "sortOrder": "DESC"
    }
  }
}
```

---

### 2.3 Get User by ID
**GET** `/api/users/{id}`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "User retrieved successfully",
  "data": {
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "user",
      "status": "active"
    }
  }
}
```

---

### 2.4 Update User
**PUT** `/api/users/{id}`

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "firstName": "John Updated",
  "lastName": "Doe Updated",
  "phone": "+9876543210"
}
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "User updated successfully",
  "data": {
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "email": "user@example.com",
      "firstName": "John Updated",
      "lastName": "Doe Updated",
      "phone": "+9876543210"
    }
  }
}
```

---

### 2.5 Block User
**PUT** `/api/users/{id}/block`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "User blocked successfully",
  "data": {
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "status": "blocked"
    }
  }
}
```

---

### 2.6 Delete User
**DELETE** `/api/users/{id}`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "User deleted successfully"
}
```

---

## 3. Checklist Template APIs (Admin Only)

### 3.1 Create Checklist Template
**POST** `/api/checklists/templates`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Request Body:**
```json
{
  "name": "Standard Car Inspection Template",
  "description": "Comprehensive inspection template for all vehicle types",
  "types": [
    {
      "typeName": "Exterior",
      "checklistItems": [
        {
          "position": 1,
          "label": "Paint Condition",
          "description": "Check for scratches, dents, and paint quality",
          "isRequired": true
        },
        {
          "position": 2,
          "label": "Body Panels",
          "description": "Inspect all body panels for damage",
          "isRequired": true
        },
        {
          "position": 3,
          "label": "Windows and Mirrors",
          "description": "Check for cracks or damage",
          "isRequired": true
        }
      ],
      "allowOverallRemarks": true,
      "allowOverallPhotos": true,
      "allowVideos": true,
      "maxVideos": 2
    },
    {
      "typeName": "Interior",
      "checklistItems": [
        {
          "position": 1,
          "label": "Seat Condition",
          "description": "Check seats for wear and tear",
          "isRequired": true
        },
        {
          "position": 2,
          "label": "Dashboard",
          "description": "Inspect dashboard for damage",
          "isRequired": true
        }
      ],
      "allowOverallRemarks": true,
      "allowOverallPhotos": true,
      "allowVideos": true,
      "maxVideos": 2
    },
    {
      "typeName": "Engine",
      "checklistItems": [
        {
          "position": 1,
          "label": "Engine Oil Level",
          "description": "Check engine oil level and quality",
          "isRequired": true
        },
        {
          "position": 2,
          "label": "Coolant Level",
          "description": "Inspect coolant level",
          "isRequired": true
        }
      ],
      "allowOverallRemarks": true,
      "allowOverallPhotos": true,
      "allowVideos": false,
      "maxVideos": 0
    }
  ]
}
```

**Available Type Names:**
- `Exterior`
- `Light Conditions and Operations`
- `Interior`
- `Engine`
- `Transmission and Drivetrain`
- `Chasis`
- `Tyre and Breaks`
- `Overall Safety Feature`
- `Entertainment`
- `Drive and Passenger Experience`

**Note:** `allowVideos` can only be `true` for `Interior` and `Exterior` types.

**Response (201):**
```json
{
  "statusCode": 201,
  "message": "Checklist template created successfully",
  "data": {
    "template": {
      "id": "507f1f77bcf86cd799439020",
      "name": "Standard Car Inspection Template",
      "description": "Comprehensive inspection template for all vehicle types",
      "types": [...],
      "isActive": true,
      "version": 1,
      "createdBy": "507f1f77bcf86cd799439010",
      "createdAt": "2024-01-15T10:30:00.000Z",
      "updatedAt": "2024-01-15T10:30:00.000Z"
    }
  }
}
```

---

### 3.2 Get All Templates
**GET** `/api/checklists/templates?page=1&limit=10&search=standard&isActive=true&sortBy=createdAt&sortOrder=DESC`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Query Parameters:**
- `page` (optional, default: 1) - Page number
- `limit` (optional, default: 10, max: 100) - Items per page
- `search` (optional) - Search in name and description
- `isActive` (optional) - Filter by active status: `true`, `false`
- `sortBy` (optional, default: `createdAt`) - Sort field: `id`, `name`, `createdAt`, `updatedAt`
- `sortOrder` (optional, default: `DESC`) - Sort order: `ASC`, `DESC`

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Templates retrieved successfully",
  "data": {
    "templates": [
      {
        "id": "507f1f77bcf86cd799439020",
        "name": "Standard Car Inspection Template",
        "description": "Comprehensive inspection template",
        "isActive": true,
        "version": 1,
        "createdBy": {
          "id": "507f1f77bcf86cd799439010",
          "firstName": "Admin",
          "lastName": "User",
          "email": "admin@example.com"
        }
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalCount": 25,
      "limit": 10,
      "hasNextPage": true,
      "hasPreviousPage": false
    },
    "filters": {
      "search": "standard",
      "isActive": true,
      "sortBy": "createdAt",
      "sortOrder": "DESC"
    }
  }
}
```

---

### 3.3 Get Template by ID
**GET** `/api/checklists/templates/{id}`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Template retrieved successfully",
  "data": {
    "template": {
      "id": "507f1f77bcf86cd799439020",
      "name": "Standard Car Inspection Template",
      "description": "Comprehensive inspection template",
      "types": [
        {
          "typeName": "Exterior",
          "checklistItems": [
            {
              "position": 1,
              "label": "Paint Condition",
              "description": "Check for scratches, dents, and paint quality",
              "isRequired": true
            }
          ],
          "allowOverallRemarks": true,
          "allowOverallPhotos": true,
          "allowVideos": true,
          "maxVideos": 2
        }
      ],
      "isActive": true,
      "version": 1,
      "createdBy": {
        "id": "507f1f77bcf86cd799439010",
        "firstName": "Admin",
        "lastName": "User"
      }
    }
  }
}
```

**Note:** Inspectors will only see active templates.

---

### 3.4 Update Template
**PUT** `/api/checklists/templates/{id}`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Request Body:**
```json
{
  "name": "Updated Template Name",
  "description": "Updated description",
  "isActive": false
}
```

**Or update types:**
```json
{
  "types": [
    {
      "typeName": "Exterior",
      "checklistItems": [
        {
          "position": 1,
          "label": "Updated Label",
          "description": "Updated description",
          "isRequired": true
        }
      ],
      "allowOverallRemarks": true,
      "allowOverallPhotos": true,
      "allowVideos": true,
      "maxVideos": 2
    }
  ]
}
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Template updated successfully",
  "data": {
    "template": {
      "id": "507f1f77bcf86cd799439020",
      "name": "Updated Template Name",
      "version": 2,
      "updatedAt": "2024-01-15T11:00:00.000Z"
    }
  }
}
```

**Note:** Version automatically increments when types are updated.

---

### 3.5 Delete Template
**DELETE** `/api/checklists/templates/{id}`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Template deleted successfully"
}
```

**Note:** Cannot delete templates that have been used in inspections. Deactivate them instead.

---

### 3.6 Get Active Templates (Inspector)
**GET** `/api/checklists/templates/active`

**Headers:**
```
Authorization: Bearer <inspector-token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Active templates retrieved successfully",
  "data": {
    "templates": [
      {
        "id": "507f1f77bcf86cd799439020",
        "name": "Standard Car Inspection Template",
        "description": "Comprehensive inspection template",
        "types": [
          {
            "typeName": "Exterior",
            "checklistItems": [
              {
                "position": 1,
                "label": "Paint Condition",
                "description": "Check for scratches, dents, and paint quality",
                "isRequired": true
              }
            ]
          }
        ],
        "version": 1,
        "createdAt": "2024-01-15T10:30:00.000Z"
      }
    ]
  }
}
```

---

## 4. Inspection APIs

### 4.1 Create Inspection
**POST** `/api/checklists/inspections`

**Headers:**
```
Authorization: Bearer <inspector-token>
```

**Request Body:**
```json
{
  "checklistTemplateId": "507f1f77bcf86cd799439020",
  "vehicleInfo": {
    "make": "Toyota",
    "model": "Camry",
    "year": 2020,
    "vin": "4T1BF1FK5EU123456",
    "licensePlate": "ABC123",
    "mileage": 50000,
    "color": "Silver"
  },
  "types": [
    {
      "typeName": "Exterior",
      "checklistItems": [
        {
          "position": 1,
          "label": "Paint Condition",
          "status": "Excellent",
          "rating": 4,
          "remarks": "Paint is in perfect condition with no scratches",
          "photos": [
            "https://example.com/photos/paint1.jpg",
            "https://example.com/photos/paint2.jpg"
          ]
        },
        {
          "position": 2,
          "label": "Body Panels",
          "status": "Good",
          "rating": 3,
          "remarks": "Minor dents on rear bumper",
          "photos": [
            "https://example.com/photos/body1.jpg"
          ]
        },
        {
          "position": 3,
          "label": "Windows and Mirrors",
          "status": "Excellent",
          "rating": 4,
          "remarks": "All windows and mirrors are in perfect condition",
          "photos": []
        }
      ],
      "overallRemarks": "Exterior is in excellent condition overall with minor cosmetic issues",
      "overallPhotos": [
        "https://example.com/photos/exterior1.jpg",
        "https://example.com/photos/exterior2.jpg"
      ],
      "videos": [
        "https://example.com/videos/exterior1.mp4",
        "https://example.com/videos/exterior2.mp4"
      ],
      "averageRating": 3.67
    },
    {
      "typeName": "Interior",
      "checklistItems": [
        {
          "position": 1,
          "label": "Seat Condition",
          "status": "Good",
          "rating": 3,
          "remarks": "Seats show minor wear",
          "photos": [
            "https://example.com/photos/seat1.jpg"
          ]
        },
        {
          "position": 2,
          "label": "Dashboard",
          "status": "Excellent",
          "rating": 4,
          "remarks": "Dashboard is clean and functional",
          "photos": []
        }
      ],
      "overallRemarks": "Interior is well maintained",
      "overallPhotos": [
        "https://example.com/photos/interior1.jpg"
      ],
      "videos": [
        "https://example.com/videos/interior1.mp4"
      ],
      "averageRating": 3.5
    },
    {
      "typeName": "Engine",
      "checklistItems": [
        {
          "position": 1,
          "label": "Engine Oil Level",
          "status": "Good",
          "rating": 3,
          "remarks": "Oil level is adequate",
          "photos": [
            "https://example.com/photos/oil1.jpg"
          ]
        },
        {
          "position": 2,
          "label": "Coolant Level",
          "status": "Excellent",
          "rating": 4,
          "remarks": "Coolant level is perfect",
          "photos": []
        }
      ],
      "overallRemarks": "Engine is in good working condition",
      "overallPhotos": [
        "https://example.com/photos/engine1.jpg"
      ],
      "videos": [],
      "averageRating": 3.5
    }
  ],
  "status": "completed",
  "inspectionDate": "2024-01-15T10:00:00.000Z",
  "notes": "Overall vehicle is in excellent condition"
}
```

**Status Values:**
- `Excellent` → rating: `4`
- `Good` → rating: `3`
- `Average` → rating: `2`
- `Poor` → rating: `1`

**Important Notes:**
1. **Rating must match status**: `Excellent=4`, `Good=3`, `Average=2`, `Poor=1`
2. **Videos only for Interior/Exterior**: Maximum 2 videos per type
3. **All types from template must be included**
4. **All checklist items from template must be included**
5. **averageRating** is auto-calculated (you can include it, but it will be recalculated)

**Response (201):**
```json
{
  "statusCode": 201,
  "message": "Inspection created successfully",
  "data": {
    "inspection": {
      "id": "507f1f77bcf86cd799439030",
      "checklistTemplateId": "507f1f77bcf86cd799439020",
      "inspectorId": "507f1f77bcf86cd799439015",
      "vehicleInfo": {
        "make": "Toyota",
        "model": "Camry",
        "year": 2020,
        "vin": "4T1BF1FK5EU123456",
        "licensePlate": "ABC123",
        "mileage": 50000,
        "color": "Silver"
      },
      "types": [
        {
          "typeName": "Exterior",
          "checklistItems": [...],
          "overallRemarks": "Exterior is in excellent condition overall",
          "overallPhotos": [...],
          "videos": [...],
          "averageRating": 3.67
        }
      ],
      "overallRating": 3.56,
      "status": "completed",
      "inspectionDate": "2024-01-15T10:00:00.000Z",
      "completedAt": "2024-01-15T10:30:00.000Z",
      "notes": "Overall vehicle is in excellent condition",
      "createdAt": "2024-01-15T10:30:00.000Z",
      "updatedAt": "2024-01-15T10:30:00.000Z"
    }
  }
}
```

---

### 4.2 Get All Inspections
**GET** `/api/checklists/inspections?page=1&limit=10&status=completed&templateId=507f1f77bcf86cd799439020&sortBy=inspectionDate&sortOrder=DESC`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `page` (optional, default: 1) - Page number
- `limit` (optional, default: 10, max: 100) - Items per page
- `status` (optional) - Filter by status: `draft`, `completed`, `submitted`
- `templateId` (optional) - Filter by template ID
- `sortBy` (optional, default: `inspectionDate`) - Sort field: `id`, `inspectionDate`, `createdAt`, `overallRating`
- `sortOrder` (optional, default: `DESC`) - Sort order: `ASC`, `DESC`

**Note:** Inspectors can only see their own inspections. Admins can see all.

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Inspections retrieved successfully",
  "data": {
    "inspections": [
      {
        "id": "507f1f77bcf86cd799439030",
        "checklistTemplateId": {
          "id": "507f1f77bcf86cd799439020",
          "name": "Standard Car Inspection Template",
          "version": 1
        },
        "inspectorId": {
          "id": "507f1f77bcf86cd799439015",
          "firstName": "Jane",
          "lastName": "Smith",
          "email": "inspector@example.com"
        },
        "vehicleInfo": {
          "make": "Toyota",
          "model": "Camry",
          "year": 2020
        },
        "overallRating": 3.56,
        "status": "completed",
        "inspectionDate": "2024-01-15T10:00:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalCount": 50,
      "limit": 10,
      "hasNextPage": true,
      "hasPreviousPage": false
    },
    "filters": {
      "status": "completed",
      "templateId": "507f1f77bcf86cd799439020",
      "sortBy": "inspectionDate",
      "sortOrder": "DESC"
    }
  }
}
```

---

### 4.3 Get Inspection by ID
**GET** `/api/checklists/inspections/{id}`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Inspection retrieved successfully",
  "data": {
    "inspection": {
      "id": "507f1f77bcf86cd799439030",
      "checklistTemplateId": {
        "id": "507f1f77bcf86cd799439020",
        "name": "Standard Car Inspection Template",
        "description": "Comprehensive inspection template",
        "version": 1
      },
      "inspectorId": {
        "id": "507f1f77bcf86cd799439015",
        "firstName": "Jane",
        "lastName": "Smith",
        "email": "inspector@example.com"
      },
      "vehicleInfo": {
        "make": "Toyota",
        "model": "Camry",
        "year": 2020,
        "vin": "4T1BF1FK5EU123456",
        "licensePlate": "ABC123",
        "mileage": 50000,
        "color": "Silver"
      },
      "types": [
        {
          "typeName": "Exterior",
          "checklistItems": [
            {
              "position": 1,
              "label": "Paint Condition",
              "status": "Excellent",
              "rating": 4,
              "remarks": "Paint is in perfect condition",
              "photos": ["https://example.com/photos/paint1.jpg"]
            }
          ],
          "overallRemarks": "Exterior is in excellent condition",
          "overallPhotos": ["https://example.com/photos/exterior1.jpg"],
          "videos": ["https://example.com/videos/exterior1.mp4"],
          "averageRating": 3.67
        }
      ],
      "overallRating": 3.56,
      "status": "completed",
      "inspectionDate": "2024-01-15T10:00:00.000Z",
      "completedAt": "2024-01-15T10:30:00.000Z",
      "notes": "Overall vehicle is in excellent condition"
    }
  }
}
```

**Note:** Only the inspector who created it or an admin can view the inspection.

---

### 4.4 Update Inspection
**PUT** `/api/checklists/inspections/{id}`

**Headers:**
```
Authorization: Bearer <inspector-token>
```

**Request Body:**
```json
{
  "types": [
    {
      "typeName": "Exterior",
      "checklistItems": [
        {
          "position": 1,
          "label": "Paint Condition",
          "status": "Good",
          "rating": 3,
          "remarks": "Updated remarks",
          "photos": ["https://example.com/photos/paint1.jpg"]
        }
      ],
      "overallRemarks": "Updated overall remarks",
      "overallPhotos": ["https://example.com/photos/exterior1.jpg"],
      "videos": ["https://example.com/videos/exterior1.mp4"]
    }
  ],
  "status": "submitted",
  "notes": "Updated notes"
}
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Inspection updated successfully",
  "data": {
    "inspection": {
      "id": "507f1f77bcf86cd799439030",
      "overallRating": 3.5,
      "status": "submitted",
      "updatedAt": "2024-01-15T11:00:00.000Z"
    }
  }
}
```

**Note:** Only draft inspections can be updated. Only the inspector who created it can update.

---

### 4.5 Delete Inspection
**DELETE** `/api/checklists/inspections/{id}`

**Headers:**
```
Authorization: Bearer <inspector-token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Inspection deleted successfully"
}
```

**Note:** Only draft inspections can be deleted. Only the inspector who created it can delete.

---

## 5. Inspection Request APIs

### 5.1 Create Inspection Request (User Only)
**POST** `/api/inspection-requests`

**Headers:**
```
Authorization: Bearer <user-token>
```

**Request Body:**
```json
{
  "requestType": "car inspection",
  "vehicleInfo": {
    "make": "Toyota",
    "model": "Camry",
    "year": 2020,
    "vin": "4T1BF1FK5EU123456",
    "licensePlate": "ABC123",
    "mileage": 50000,
    "color": "Silver"
  },
  "preferredDate": "2024-01-20T10:00:00.000Z",
  "preferredTime": "10:00 AM",
  "location": {
    "address": "123 Main Street",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001"
  },
  "notes": "Please inspect the vehicle thoroughly"
}
```

**Request Type Values:**
- `"car inspection"` (default)
- `"car valuation"`

**Response (201):**
```json
{
  "statusCode": 201,
  "message": "Inspection request created successfully",
  "data": {
    "request": {
      "id": "507f1f77bcf86cd799439040",
      "userId": "507f1f77bcf86cd799439011",
      "requestType": "car inspection",
      "vehicleInfo": {
        "make": "Toyota",
        "model": "Camry",
        "year": 2020,
        "vin": "4T1BF1FK5EU123456",
        "licensePlate": "ABC123",
        "mileage": 50000,
        "color": "Silver"
      },
      "preferredDate": "2024-01-20T10:00:00.000Z",
      "preferredTime": "10:00 AM",
      "location": {
        "address": "123 Main Street",
        "city": "New York",
        "state": "NY",
        "zipCode": "10001"
      },
      "status": "pending",
      "notes": "Please inspect the vehicle thoroughly",
      "createdAt": "2024-01-15T10:00:00.000Z"
    }
  }
}
```

---

### 5.2 Get User's Inspection Requests
**GET** `/api/inspection-requests?page=1&limit=10&status=pending&sortBy=createdAt&sortOrder=DESC`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `page` (optional, default: 1) - Page number
- `limit` (optional, default: 10, max: 100) - Items per page
- `status` (optional) - Filter by status: `pending`, `assigned`, `in_progress`, `completed`, `cancelled`
- `sortBy` (optional, default: `createdAt`) - Sort field: `id`, `createdAt`, `preferredDate`, `status`
- `sortOrder` (optional, default: `DESC`) - Sort order: `ASC`, `DESC`

**Note:** 
- Users can only see their own requests
- Admins can see all requests

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Inspection requests retrieved successfully",
  "data": {
    "requests": [
      {
        "id": "507f1f77bcf86cd799439040",
        "requestType": "car inspection",
        "vehicleInfo": {
          "make": "Toyota",
          "model": "Camry",
          "year": 2020
        },
        "location": {
          "address": "123 Main Street",
          "city": "New York",
          "state": "NY"
        },
        "status": "pending",
        "assignedInspectorId": null,
        "preferredDate": "2024-01-20T10:00:00.000Z",
        "createdAt": "2024-01-15T10:00:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalCount": 50,
      "limit": 10,
      "hasNextPage": true,
      "hasPreviousPage": false
    },
    "filters": {
      "status": "pending",
      "sortBy": "createdAt",
      "sortOrder": "DESC"
    }
  }
}
```

---

### 5.3 Get Inspection Request by ID
**GET** `/api/inspection-requests/{id}`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Inspection request retrieved successfully",
  "data": {
    "request": {
      "id": "507f1f77bcf86cd799439040",
      "userId": {
        "id": "507f1f77bcf86cd799439011",
        "firstName": "John",
        "lastName": "Doe",
        "email": "user@example.com"
      },
      "requestType": "car inspection",
      "vehicleInfo": {
        "make": "Toyota",
        "model": "Camry",
        "year": 2020,
        "vin": "4T1BF1FK5EU123456",
        "licensePlate": "ABC123",
        "mileage": 50000,
        "color": "Silver"
      },
      "preferredDate": "2024-01-20T10:00:00.000Z",
      "preferredTime": "10:00 AM",
      "location": {
        "address": "123 Main Street",
        "city": "New York",
        "state": "NY",
        "zipCode": "10001"
      },
      "status": "pending",
      "assignedInspectorId": null,
      "notes": "Please inspect the vehicle thoroughly",
      "createdAt": "2024-01-15T10:00:00.000Z"
    }
  }
}
```

**Note:** Users can only view their own requests. Admins can view all requests.

---

### 5.4 Get All Inspection Requests (Admin Only)
**GET** `/api/inspection-requests/admin/all?page=1&limit=10&status=pending&sortBy=createdAt&sortOrder=DESC`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Query Parameters:**
- `page` (optional, default: 1) - Page number
- `limit` (optional, default: 10, max: 100) - Items per page
- `status` (optional) - Filter by status: `pending`, `assigned`, `in_progress`, `completed`, `cancelled`
- `sortBy` (optional, default: `createdAt`) - Sort field: `id`, `createdAt`, `preferredDate`, `status`
- `sortOrder` (optional, default: `DESC`) - Sort order: `ASC`, `DESC`

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Inspection requests retrieved successfully",
  "data": {
    "requests": [...],
    "statistics": {
      "total": 500,
      "pending": 45,
      "assigned": 30,
      "inProgress": 15,
      "completed": 400,
      "cancelled": 10
    },
    "pagination": {
      "currentPage": 1,
      "totalPages": 50,
      "totalCount": 500,
      "limit": 10,
      "hasNextPage": true,
      "hasPreviousPage": false
    },
    "filters": {
      "status": "pending",
      "sortBy": "createdAt",
      "sortOrder": "DESC"
    }
  }
}
```

---

## 6. Admin Dashboard API

### 6.1 Get Admin Dashboard Data
**GET** `/api/admin/dashboard`

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Admin dashboard data retrieved successfully",
  "data": {
    "total_users": 150,
    "total_inspectors": 25,
    "total_checklist_templates": 10,
    "inspection_requests": {
      "total_requests": 500,
      "open_requests": 45,
      "latest_requests": [
        {
          "request_id": "507f1f77bcf86cd799439040",
          "request_type": "car inspection",
          "request_location": "123 Main Street, New York, NY",
          "request_status": "Pending"
        },
        {
          "request_id": "507f1f77bcf86cd799439041",
          "request_type": "car valuation",
          "request_location": "456 Oak Ave, Los Angeles, CA",
          "request_status": "Assigned"
        }
      ]
    },
    "recent_activities": [
      {
        "action": "user_registered",
        "description": "John Doe (john@example.com) registered as user"
      },
      {
        "action": "inspection_request_created",
        "description": "New car inspection request created"
      },
      {
        "action": "inspection_completed",
        "description": "Jane Smith completed inspection for Toyota Camry"
      },
      {
        "action": "template_created",
        "description": "Admin User created checklist template: Standard Inspection"
      }
    ]
  }
}
```

**Response Fields:**
- `total_users`: Total number of users (excluding admin users)
- `total_inspectors`: Total number of inspectors
- `total_checklist_templates`: Total number of checklist templates
- `inspection_requests.total_requests`: Total number of inspection requests
- `inspection_requests.open_requests`: Number of open requests (pending + assigned + in_progress)
- `inspection_requests.latest_requests`: Latest 10 requests with formatted data
- `recent_activities`: Recent 20 activities from various sources (user registrations, requests, inspections, templates)

**Request Status Values:**
- `Pending` - Request created, awaiting assignment
- `Assigned` - Request assigned to an inspector
- `In Progress` - Inspection in progress
- `Completed` - Inspection completed
- `Cancelled` - Request cancelled

---

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Email must be a valid email address"
    }
  ]
}
```

### 401 Unauthorized
```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "error": "No token provided"
}
```

### 403 Forbidden
```json
{
  "statusCode": 403,
  "message": "Forbidden - Insufficient permissions"
}
```

### 404 Not Found
```json
{
  "statusCode": 404,
  "message": "Resource not found"
}
```

### 409 Conflict
```json
{
  "statusCode": 409,
  "message": "Resource already exists"
}
```

### 500 Internal Server Error
```json
{
  "statusCode": 500,
  "message": "Internal server error"
}
```

---

## Status Code Reference

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (missing/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (resource already exists)
- `500` - Internal Server Error

---

## Notes

1. **OTP Authentication (All Roles)**: 
   - All roles (`admin`, `inspector`, `user`) use **OTP-only authentication** (no password anywhere)
   - OTP is sent via email and is valid for 10 minutes
   - Use `POST /api/auth/login` (or `POST /api/auth/send-otp`) to receive an OTP, then `POST /api/auth/verify-otp` to get the JWT token

2. **Photo/Video URLs**: Currently, the API expects URLs/paths. You'll need to integrate with S3 or your storage service to upload files and get URLs.

3. **Rating Calculation**: Ratings are automatically calculated:
   - Per-type average: Average of all checklist item ratings in that type
   - Overall rating: Average of all type ratings

4. **Video Restrictions**: Videos are only allowed for `Interior` and `Exterior` types, maximum 2 per type.

5. **Status Values**: 
   - `Excellent` = 4
   - `Good` = 3
   - `Average` = 2
   - `Poor` = 1

6. **Inspection Status**:
   - `draft` - Can be updated/deleted
   - `completed` - Inspection is complete
   - `submitted` - Inspection has been submitted (final)

7. **Inspection Request Status**:
   - `pending` - Request created, awaiting assignment
   - `assigned` - Request assigned to an inspector
   - `in_progress` - Inspection in progress
   - `completed` - Inspection completed
   - `cancelled` - Request cancelled

8. **Request Types**:
   - `car inspection` - Standard car inspection request
   - `car valuation` - Car valuation request

9. **User List Filtering**: 
   - Admin users are excluded from GET `/api/users` by default
   - To see admin users, explicitly filter by `role=admin`

10. **Template Versioning**: Template version automatically increments when types are updated.
