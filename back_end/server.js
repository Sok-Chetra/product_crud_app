const express = require('express');
const cors = require('cors');
const { pool, testConnection, initializeDatabase } = require('./config/database');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Get all products
app.get('/products', async (req, res) => {
	let connection;
	try {
		connection = await pool.getConnection();
		const [rows] = await connection.execute('SELECT * FROM PRODUCTS ORDER BY PRODUCTID');

		res.json({
			success: true,
			data: rows,
			count: rows.length
		});
	} catch (error) {
		console.error('Error fetching products:', error);
		res.status(500).json({
			success: false,
			message: 'Error fetching products'
		});
	} finally {
		if (connection) connection.release();
	}
});

// Get product by ID
app.get('/products/:id', async (req, res) => {
	let connection;
	try {
		const { id } = req.params;
		connection = await pool.getConnection();

		const [rows] = await connection.execute(
			'SELECT * FROM PRODUCTS WHERE PRODUCTID = ?',
			[id]
		);

		if (rows.length === 0) {
			return res.status(404).json({
				success: false,
				message: 'Product not found'
			});
		}

		res.json({
			success: true,
			data: rows[0]
		});
	} catch (error) {
		console.error('Error fetching product:', error);
		res.status(500).json({
			success: false,
			message: 'Error fetching product'
		});
	} finally {
		if (connection) connection.release();
	}
});

// Create product
app.post('/products', async (req, res) => {
	let connection;
	try {
		const { productName, price, stock } = req.body;

		// Validation
		if (!productName || price === undefined || stock === undefined) {
			return res.status(400).json({
				success: false,
				message: 'All fields are required'
			});
		}

		if (price <= 0 || stock < 0) {
			return res.status(400).json({
				success: false,
				message: 'Price must be positive and stock cannot be negative'
			});
		}

		connection = await pool.getConnection();

		const [result] = await connection.execute(
			'INSERT INTO PRODUCTS (PRODUCTNAME, PRICE, STOCK) VALUES (?, ?, ?)',
			[productName, price, stock]
		);

		// Get the newly created product
		const [newProduct] = await connection.execute(
			'SELECT * FROM PRODUCTS WHERE PRODUCTID = ?',
			[result.insertId]
		);

		res.status(201).json({
			success: true,
			data: newProduct[0],
			message: 'Product created successfully'
		});
	} catch (error) {
		console.error('Error creating product:', error);
		res.status(500).json({
			success: false,
			message: 'Error creating product'
		});
	} finally {
		if (connection) connection.release();
	}
});

// Update product - FIXED
app.put('/products/:id', async (req, res) => {
	let connection;
	try {
		const { id } = req.params;
		const { productName, price, stock } = req.body;

		// Validation
		if (!productName || price === undefined || stock === undefined) {
			return res.status(400).json({
				success: false,
				message: 'All fields are required'
			});
		}

		if (price <= 0 || stock < 0) {
			return res.status(400).json({
				success: false,
				message: 'Price must be positive and stock cannot be negative'
			});
		}

		connection = await pool.getConnection();

		const [result] = await connection.execute(
			'UPDATE PRODUCTS SET PRODUCTNAME = ?, PRICE = ?, STOCK = ? WHERE PRODUCTID = ?',
			[productName, price, stock, id]
		);

		if (result.affectedRows === 0) {
			return res.status(404).json({
				success: false,
				message: 'Product not found'
			});
		}

		// Get the updated product
		const [updatedProduct] = await connection.execute(
			'SELECT * FROM PRODUCTS WHERE PRODUCTID = ?',
			[id]
		);

		res.json({
			success: true,
			data: updatedProduct[0],
			message: 'Product updated successfully'
		});
	} catch (error) {
		console.error('Error updating product:', error);
		res.status(500).json({
			success: false,
			message: 'Error updating product'
		});
	} finally {
		if (connection) connection.release();
	}
});

// Delete product
app.delete('/products/:id', async (req, res) => {
	let connection;
	try {
		const { id } = req.params;
		connection = await pool.getConnection();

		const [result] = await connection.execute(
			'DELETE FROM PRODUCTS WHERE PRODUCTID = ?',
			[id]
		);

		if (result.affectedRows === 0) {
			return res.status(404).json({
				success: false,
				message: 'Product not found'
			});
		}

		res.json({
			success: true,
			message: 'Product deleted successfully'
		});
	} catch (error) {
		console.error('Error deleting product:', error);
		res.status(500).json({
			success: false,
			message: 'Error deleting product'
		});
	} finally {
		if (connection) connection.release();
	}
});

// Start server
const startServer = async () => {
	console.log('🚀 Starting server...');

	// Test database connection
	const dbConnected = await testConnection();
	if (!dbConnected) {
		console.log('❌ Cannot start server - database connection failed');
		process.exit(1);
	}

	// Initialize database
	await initializeDatabase();

	app.listen(PORT, '0.0.0.0', () => {
		console.log(`✅ Server running on http://localhost:${PORT}`);
	});
};

startServer().catch(error => {
	console.error('❌ Failed to start server:', error);
	process.exit(1);
});