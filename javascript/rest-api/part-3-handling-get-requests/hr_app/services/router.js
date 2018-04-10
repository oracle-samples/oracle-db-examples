const express = require('express');
const router = new express.Router();
const employees = require('../controllers/employees.js');

router.route('/employees/:id?')
  .get(employees.get);

module.exports = router;
