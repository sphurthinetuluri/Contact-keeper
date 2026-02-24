# 📇 Contact Keeper

A full-stack Contact Management Application built using **Node.js (Express)** for the backend and **Flutter** for the frontend.

This application allows users to securely manage personal and professional contacts with authentication and database integration.

---

## 🚀 Features

- User Registration & Login
- Secure Authentication (JWT)
- Add New Contacts
- Update Existing Contacts
- Delete Contacts
- RESTful API Integration
- MongoDB Database
- Cross-platform Flutter UI

---

## 🛠️ Tech Stack

### 🔹 Backend
- Node.js
- Express.js
- MongoDB
- Mongoose
- JSON Web Token (JWT)
- dotenv

### 🔹 Frontend
- Flutter
- Dart

---

## 📂 Project Structure

```
contact-keeper/
│
├── contact_app_backend/
│   ├── models/
│   ├── middleware/
│   ├── server.js
│   ├── package.json
│   └── .env (not pushed)
│
├── contact_app_frontend/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── web/
│   └── pubspec.yaml
│
├── .gitignore
└── README.md
```

---

## ⚙️ Installation & Setup

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/your-username/contact-keeper.git
cd contact-keeper
```

---

### 2️⃣ Backend Setup

```bash
cd contact_app_backend
npm install
npm start
```

Create a `.env` file inside `contact_app_backend`:

```
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_secret_key
```

---

### 3️⃣ Frontend Setup

```bash
cd contact_app_frontend
flutter pub get
flutter run
```

---

## 🔐 Environment Variables

The backend requires the following environment variables:

| Variable     | Description |
|-------------|------------|
| MONGO_URI   | MongoDB connection string |
| JWT_SECRET  | Secret key for JWT authentication |

---

## 📌 Future Improvements

- Contact search functionality
- Profile image upload
- Deployment (Render / Firebase)
- Role-based authentication
- API documentation (Swagger)

---

## 👩‍💻 Author

**Sphurthi**

---

## ⭐ If You Like This Project

Give it a star on GitHub ⭐