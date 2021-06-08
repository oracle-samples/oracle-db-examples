const express = require('express');
const router = new express.Router();
const authentication = require('./authentication.js');
const employees = require('../controllers/employees.js');

router.route('/employees/:id?')
  .all(authentication.ensureAuthenticated())
  .get(employees.get)
  .post(employees.post)
  .put(employees.put)
  .delete(employees.delete);

module.exports = router;
