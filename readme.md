# 🛍️ Product Management System

A **Product CRUD Application** built with **Flutter** (frontend) and **Node.js + Express.js + MySQL** (backend).

---

## 📋 Table of Contents

- [Features](#-features)
- [Project Structure](#-project-structure)
- [Backend Setup](#-backend-setup)
- [Frontend Setup](#-frontend-setup)
- [API Documentation](#-api-documentation)
- [Environment Variables](#️-environment-variables)
- [Running the Application](#-running-the-application)

---

## 🚀 Features

### 🧩 Backend Features
- RESTful API built with **Express.js**
- **MySQL** database integration
- **CORS** enabled for cross-origin requests
- Centralized **error handling** and **validation**
- Full **CRUD operations** for product management

### 📱 Frontend Features
- **Add**, **edit**, **delete**, and **view** products
- **Search & Filter** with debounced search (real-time)
- **Sorting** by price and stock (ascending/descending)
- **Pagination** with infinite scroll (load more)
- **Export Data** to **PDF** and **CSV**
- **Pull-to-Refresh** for quick updates
- **Responsive Design** for mobile and desktop

---

## 📁 Project Structure:

	product_crud_app/
		├── back_end/
		│ ├── config/
		│ │ └── database.js
		│ ├── controllers/
		│ │ └── productController.js
		│ ├── routes/
		│ │ └── products.js
		│ ├── app.js
		│ └── package.json
		├── front_end/
		│ ├── lib/
		│ │ ├── models/
		│ │ │ └── product.dart
		│ │ ├── providers/
		│ │ │ └── product_provider.dart
		│ │ ├── services/
		│ │ │ └── api_service.dart
		│ │ ├── widgets/
		│ │ │ ├── search_bar.dart
		│ │ │ ├── sort_dropdown.dart
		│ │ │ └── export_button.dart
		│ │ └── screens/
		│ │ ├── product_list_screen.dart
		│ │ ├── add_product_screen.dart
		│ │ └── edit_product_screen.dart
		│ ├── pubspec.yaml
		│ └── main.dart
		└── README.md


---

##### 🛠 Backend Setup #####

	+ Prerequisites
		- **Node.js** (v14 or higher)
		- **MySQL** database

	+ Installation Steps

		1️⃣ Navigate to the backend directory
			cd back_end

		2️⃣ Install dependencies
			npm install

		3️⃣ Database Setup

			CREATE DATABASE productDB;
			USE productDB;

			CREATE TABLE products (
			PRODUCTID INT AUTO_INCREMENT PRIMARY KEY,
			PRODUCTNAME VARCHAR(255) NOT NULL,
			PRICE DECIMAL(10,2) NOT NULL,
			STOCK INT NOT NULL,
			createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
			);

		4️⃣ Configure Database
			Update config/database.js with your MySQL credentials:

				module.exports = {
				host: 'localhost',
				user: 'your_mysql_username',
				password: 'your_mysql_password',
				database: 'product_management'
				};

		5️⃣ Start the Server
			npm start
			npm run dev
			The backend will run on http://localhost:3000

##### 📱 Frontend Setup #####
	+ Prerequisites
		1. Flutter SDK (v3.0 or higher)
		2. Android Studio / VS Code with Flutter extension
		3. Physical device or emulator

	+ Installation Steps:
		cd front_end
		flutter pub get

	+ Configure API Base URL:
		In lib/services/api_service.dart:
			static const String baseUrl = 'http://127.0.0.1:3000';

	+ Run App
		flutter run

	+ Dependencies Used(pubspec.yaml):

		dependencies:
			flutter:
				sdk: flutter
			provider: ^6.1.1
			http: ^1.1.0
			pull_to_refresh: ^2.0.0
			syncfusion_flutter_pdf: ^23.1.44
			file_picker: ^5.5.0
			path_provider: ^2.1.1
			open_file: ^3.3.1

#### 📚 API Documentation #####
	base_url = http://localhost:3000

	+ Endpoints:
		- 🟢 Get All Products
		- Method GET: /products
		- Response:
			{
				"success": true,
				"data": [
					{
					"PRODUCTID": 1,
					"PRODUCTNAME": "Product Name",
					"PRICE": 29.99,
					"STOCK": 100
					}
				]
			}

		🟢 Get Single Product
		- Method GET: /products/:id

		🟠 Create Product
		- Method POST: /products
		- Fields: 
			{
				"productName": "New Product",
				"price": 19.99,
				"stock": 50
			}

		🟣 Update Product
		- Method PUT: /products/:id
		-Fields:
			{
				"productName": "Updated Product",
				"price": 22.99,
				"stock": 75
			}

		🔴 Delete Product
		- Method DELETE: /products/:id

##### ⚙️ Environment Variables #####

	DB_SERVER=localhost
	DB_DATABASE=ProductDB
	DB_USER=root
	DB_PASSWORD=YourPassword
	DB_PORT=3306
	PORT=3000

##### 🏃 Running the Application #####

	1️⃣ Start the Backend
		cd back_end
		npm install
		npm start

	2️⃣ Start the Frontend (in a new terminal)
		cd front_end
		flutter pub get
		flutter run

	3️⃣ Access the App
		Mobile: Run on device/emulator
		Web: flutter run -d chrome
