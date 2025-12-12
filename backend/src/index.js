// Server setup for feedback API
const express = require('express');
const cors = require('cors');

// Load dotenv so PORT and other env vars can be set from .env
try {
  require('dotenv').config();
} catch (e) { }

const db = require('./firestore');

const app = express();
// Allow CORS from local dev origins; adjust as needed for production
app.use(cors());
app.use(express.json());

const FEEDBACK_COLLECTION = 'feedbacks';

app.get('/ping', (req, res) => res.json({ ok: true, time: new Date().toISOString() }));

// Create feedback (simple example)
app.post('/feedback', async (req, res) => {
  try {
    const payload = req.body;
    if (!payload || Object.keys(payload).length === 0) {
      return res.status(400).json({ error: 'Empty payload' });
    }

    const docRef = await db.collection(FEEDBACK_COLLECTION).add({
      ...payload,
      createdAt: new Date(),
    });
    const saved = await docRef.get();
    return res.status(201).json({ id: docRef.id, data: saved.data() });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'failed to save feedback' });
  }
});

// Get a feedback by id
app.get('/feedback/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const doc = await db.collection(FEEDBACK_COLLECTION).doc(id).get();
    if (!doc.exists) return res.status(404).json({ error: 'not found' });
    return res.json({ id: doc.id, data: doc.data() });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'failed to read feedback' });
  }
});

// List recent feedbacks
app.get('/feedback', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit || '20', 10);
    const snapshot = await db.collection(FEEDBACK_COLLECTION)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();
    const items = snapshot.docs.map(d => ({ id: d.id, data: d.data() }));
    return res.json({ count: items.length, items });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'failed to list feedbacks' });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Backend listening on http://localhost:${PORT}`));

