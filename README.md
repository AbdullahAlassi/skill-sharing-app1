# 📚 Skill-Sharing App

A platform where users can **share, learn, and track skills** while accessing educational resources and participating in events.

---

## 🚀 Features

- ✅ User Authentication (Sign Up, Login, JWT Authentication)
- ✅ Skill Management (Add, Update, Delete, View)
- ✅ Learning Resources (Videos, Articles, PDFs)
- 🔄 Progress Tracking (Learning Goals, Achievements)
- 🎟️ Event & Workshop Management (Join, Organize, Track)
- 🔔 Notifications (User Updates, Reminders)
- 🛠️ Role-Based Access (Admin, Users)

---

## 🏗️ Tech Stack

| **Technology**  | **Usage** |
|----------------|----------|
| **Flutter** | Frontend (Mobile UI) |
| **Node.js (Express.js)** | Backend API |
| **MongoDB (Mongoose)** | Database |
| **JWT (JSON Web Tokens)** | Authentication |
| **Postman** | API Testing |
| **Firebase** | Push Notifications (Optional) |

---

## 🔧 Installation & Setup

### **1️⃣ Clone the Repository**
```bash
git clone https://github.com/yourusername/Skill-Sharing-App.git
cd Skill-Sharing-App
```

### **2️⃣ Install Backend Dependencies**
```bash
cd backend
npm install
```

### **3️⃣ Setup Environment Variables**
Create a `.env` file inside `backend/` and add:
```plaintext
PORT=5001
DB_URI=mongodb+srv://your-mongodb-uri
JWT_SECRET=your-secret-key
```

### **4️⃣ Start Backend Server**
```bash
npm run dev
```

### **5️⃣ Install Flutter Dependencies**
```bash
cd frontend
flutter pub get
```

### **6️⃣ Run the Flutter App**
```bash
flutter run
```

---

## 📄 API Endpoints (Backend)

| **Method** | **Endpoint** | **Description** |
|------------|------------|----------------|
| `POST` | `/api/auth/signup` | User Registration |
| `POST` | `/api/auth/login` | User Login (JWT) |
| `POST` | `/api/skills/add` | Add a Skill (Auth Required) |
| `GET` | `/api/skills` | Get User Skills |
| `POST` | `/api/resources/add` | Add Learning Resource |
| `GET` | `/api/resources` | Get Learning Resources |
| `DELETE` | `/api/resources/:id` | Delete Resource |

---

## 👨‍💻 Contributing

Want to contribute? Follow these steps:

1. **Fork** the repo.
2. **Create a feature branch** (`git checkout -b feature-branch`).
3. **Commit your changes** (`git commit -m "Added a new feature"`).
4. **Push** to GitHub (`git push origin feature-branch`).
5. **Open a Pull Request**.

---

## 📜 License

This project is licensed under the **MIT License**.

---

## 📞 Contact

For support or feedback, contact me:

📧 **Email:** abdullah.alassi123@gmail.com  
📌 **GitHub:** [Abdullah Alassi](https://github.com/AbdullahAlassi)
