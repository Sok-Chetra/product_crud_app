
const mysql = require('mysql2/promise');
require('dotenv').config();

// Database configuration
const dbConfig = {
	host: process.env.DB_HOST || 'localhost',
	port: process.env.DB_PORT || 3306,
	user: process.env.DB_USER || 'root',
	password: process.env.DB_PASSWORD || '', // Try empty if no password
	database: process.env.DB_DATABASE || 'ProductDB',
	waitForConnections: true,
	connectionLimit: 10,
	queueLimit: 0
};

// Create connection pool
const pool = mysql.createPool(dbConfig);

// Simple connection test
const testConnection = async () => {
	try {
		console.log('Wait for database connection...');
		const connection = await pool.getConnection();

		// Test basic query
		const [result] = await connection.execute('SELECT 1 + 1 AS test');
		console.log('Database connection: SUCCESS');

		connection.release();
		return true;
	} catch (error) {
		console.log('\nDatabase connection: FAILED');
		console.log('\nError:', error.message);
		console.log('\nCode:', error.code);
		return false;
	}
};

// Initialize database and tables
const initializeDatabase = async () => {
	let connection;
	try {
		console.log('\nInitializing database...');
		connection = await pool.getConnection();

		// Create products table
		await connection.execute(`
      CREATE TABLE IF NOT EXISTS PRODUCTS (
        PRODUCTID INT PRIMARY KEY AUTO_INCREMENT,
        PRODUCTNAME VARCHAR(100) NOT NULL,
        PRICE DECIMAL(10, 2) NOT NULL,
        STOCK INT NOT NULL
      )
    `);
		console.log('\nPRODUCTS table: READY');

		connection.release();
		return true;

	} catch (error) {
		console.log('Database initialization failed:', error.message);
		if (connection) connection.release();
		return false;
	}
};

module.exports = {
	pool,
	mysql,
	testConnection,
	initializeDatabase
};