const express = require('express');
const router = new express.Router();
const employees = require('../controllers/employees.js');
const files = require('../controllers/files.js');
const fileDetails = require('../controllers/file_details.js');

router.route('/employees/:id?')
  .get(employees.get)
  .post(employees.post)
  .put(employees.put)
  .delete(employees.delete);

// End point for file content
router.route('/files/:id?')
  .get(files.get)
  .post(files.post)
  .delete(files.delete);

// End point for metadata/attributes related to files, not their content
router.route('/file_details/:id?')
  .get(fileDetails.get);

module.exports = router;
