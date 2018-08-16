const express = require('express');
const router = new express.Router();
const employees = require('../controllers/employees.js');

router.route('/employees/:id?')
  .get(employees.get)
  .post(employees.post)
  .put(employees.put)
  .delete(employees.delete);

module.exports = router;
