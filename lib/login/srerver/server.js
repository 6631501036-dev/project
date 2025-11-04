const express = require("express");
const cors = require("cors");
const con = require("./db.js"); // Import the database connection

const app = express();
const port = 4400; // You can change this port if needed

// === Middleware ===
// Enable Cross-Origin Resource Sharing (CORS)
// This is necessary for your Flutter app to communicate with the server
app.use(cors());

// Enable parsing of JSON request bodies
app.use(express.json());

// === Routes ===

/**
 * POST /login
 * Handles the login request from the Flutter app.
 * Expects a JSON body with "username" and "password".
 */
app.post("/login", (req, res) => {
  const { username, password } = req.body;

  // 1. Basic validation
  if (!username || !password) {
    return res
      .status(400)
      .json({ status: "fail", message: "Username and password are required" });
  }

  // 2. Query the database
  const sql = "SELECT * FROM users WHERE username = ?";
  
  con.query(sql, [username], (err, results) => {
    if (err) {
      console.error("Database query error:", err);
      return res
        .status(500)
        .json({ status: "fail", message: "Server error" });
    }

    // 3. Check if user was found
    if (results.length > 0) {
      const user = results[0];

      // 4. Compare passwords
      // !! SECURITY WARNING !!
      // This code compares plain text passwords.
      // In a real application, you MUST hash passwords using bcrypt.
      // Your flutter_app.users table's password column should store the hash.
      // Then you would use: bcrypt.compare(password, user.password, (err, isMatch) => { ... })
      if (password === user.password) {
        // Passwords match - Login successful
        console.log(`Login success for user: ${username}`);
        res.json({ status: "success", userId: user.id, role: user.role }); // Sending back user info
      } else {
        // Passwords do not match
        console.log(`Login failed (wrong password) for user: ${username}`);
        res.json({ status: "fail", message: "Invalid username or password" });
      }
    } else {
      // No user found with that username
      console.log(`Login failed (user not found): ${username}`);
      res.json({ status: "fail", message: "Invalid username or password" });
    }
  });
});

// === Start the server ===
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
