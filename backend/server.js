require('dotenv').config();
require('./backup');
const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());
app.use('/api/auth', require('./routes/auth'));
app.use('/api/auth', require('./routes/reset'));
app.use('/api/resources', require('./routes/resources'));
app.use('/api/bookings', require('./routes/bookings'));
app.use('/api/users', require('./routes/users'));
app.use('/api/logs', require('./routes/logs'));
app.get('/api/health', (req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));
app.use((req, res) => res.status(404).json({ error: 'Endpoint non trovato' }));
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Errore interno del server' });
  app.use('/api/logs', require('./routes/logs'));
});
const PORT = process.env.PORT || 3001;
app.listen(PORT, '0.0.0.0', () => console.log(`Booking API running on port ${PORT}`));
