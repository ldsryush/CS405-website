const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
    origin: [
        'https://autoreportform.click',
        'https://www.autoreportform.click',
        'http://localhost:3000'
    ],
    credentials: true
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Serve static files (HTML, CSS, JS)
app.use(express.static('.'));

// MySQL Connection Pool
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'autoreportai',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Test database connection
pool.getConnection((err, connection) => {
    if (err) {
        console.error('Error connecting to MySQL database:', err.message);
        console.log('Please check your .env file and ensure MySQL is running.');
    } else {
        console.log('Successfully connected to MySQL database');
        connection.release();
    }
});

// API endpoint to submit contact form
app.post('/api/contact', (req, res) => {
    const { firstName, lastName, email, phone, company, message } = req.body;

    // Validate required fields
    if (!firstName || !lastName || !email) {
        return res.status(400).json({ 
            success: false, 
            error: 'First name, last name, and email are required' 
        });
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({ 
            success: false, 
            error: 'Invalid email format' 
        });
    }

    // Insert into database
    const query = `
        INSERT INTO contacts (first_name, last_name, email, phone, company, message, submitted_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    `;

    pool.query(
        query, 
        [firstName, lastName, email, phone || null, company || null, message || null],
        (error, results) => {
            if (error) {
                console.error('Database error:', error);
                return res.status(500).json({ 
                    success: false, 
                    error: 'Failed to save contact information' 
                });
            }

            res.json({ 
                success: true, 
                message: 'Contact information saved successfully',
                contactId: results.insertId
            });
        }
    );
});

// API endpoint to get all contacts (optional - for admin use)
app.get('/api/contacts', (req, res) => {
    const query = 'SELECT * FROM contacts ORDER BY submitted_at DESC';
    
    pool.query(query, (error, results) => {
        if (error) {
            console.error('Database error:', error);
            return res.status(500).json({ 
                success: false, 
                error: 'Failed to retrieve contacts' 
            });
        }

        res.json({ 
            success: true, 
            contacts: results 
        });
    });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    pool.getConnection((err, connection) => {
        if (err) {
            return res.status(500).json({ 
                status: 'error', 
                database: 'disconnected',
                error: err.message
            });
        }
        connection.release();
        res.json({ 
            status: 'ok', 
            database: 'connected' 
        });
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
    console.log(`API endpoint: http://localhost:${PORT}/api/contact`);
});
