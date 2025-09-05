const express = require('express');

const router = express.Router();

// Placeholder routes for tasks
router.get('/', (req, res) => {
  res.json({ message: 'Task routes - to be implemented' });
});

module.exports = router;
