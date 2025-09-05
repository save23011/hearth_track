const express = require('express');

const router = express.Router();

// Placeholder routes for journal
router.get('/', (req, res) => {
  res.json({ message: 'Journal routes - to be implemented' });
});

module.exports = router;
