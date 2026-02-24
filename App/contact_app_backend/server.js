require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const User = require('./models/user');
const Contact = require('./models/contact');
const auth = require('./middleware/auth');

const app = express();
app.use(cors());
app.use(express.json());

// Config
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI;
const JWT_SECRET = process.env.JWT_SECRET;

// Connect to MongoDB
mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('✅ MongoDB Connected'))
  .catch(err => {
    console.error('MongoDB connection error:', err.message);
    process.exit(1);
  });

// Health route
app.get('/', (req, res) => {
  res.send('📞 Contact Keeper API is running');
});

// Register user
app.post('/register', async (req, res) => {
  try {
    const { name, email, password, confirmPassword } = req.body;
    if (!email || !password || !confirmPassword)
      return res.status(400).json({ message: 'Email & password required' });
    if (password !== confirmPassword)
      return res.status(400).json({ message: 'Passwords do not match' });

    if (await User.findOne({ email }))
      return res.status(400).json({ message: 'Email already registered' });

    const hashed = await bcrypt.hash(password, 10);
    const user = new User({ name, email, password: hashed });
    await user.save();

    res.json({ message: 'Registered successfully' });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Login user
app.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ message: 'Email & password required' });

    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(400).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ message: 'Login successful', token });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create Contact
app.post('/contacts', auth, async (req, res) => {
  try {
    const { name, phone, email, address } = req.body;
    if (!name || !phone)
      return res.status(400).json({ message: 'Name and phone required' });

    const contact = new Contact({ userId: req.userId, name, phone, email, address });
    await contact.save();
    res.json(contact);
  } catch (err) {
    console.error('Create contact error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all Contacts
app.get('/contacts', auth, async (req, res) => {
  try {
    const contacts = await Contact.find({ userId: req.userId }).sort({ createdAt: -1 });
    res.json(contacts);
  } catch (err) {
    console.error('Get contacts error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update Contact
app.put('/contacts/:id', auth, async (req, res) => {
  try {
    const contact = await Contact.findById(req.params.id);
    if (!contact || contact.userId !== req.userId)
      return res.status(404).json({ message: 'Contact not found' });

    Object.assign(contact, req.body);
    await contact.save();
    res.json(contact);
  } catch (err) {
    console.error('Update contact error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete Contact
app.delete('/contacts/:id', auth, async (req, res) => {
  try {
    const contact = await Contact.findById(req.params.id);
    if (!contact || contact.userId !== req.userId)
      return res.status(404).json({ message: 'Contact not found' });

    await contact.deleteOne();
    res.json({ message: 'Deleted successfully' });
  } catch (err) {
    console.error('Delete contact error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// Start Server
app.listen(PORT, '0.0.0.0', () =>
  console.log(`🚀 Server running on port ${PORT}`)
);
