const oracledb = require('oracledb');
const database = require('../services/database.js');

const baseQuery =
 `select id "id",
    file_name "file_name",
    dbms_lob.getlength(blob_data) "file_length",
    content_type "content_type"
  from jsao_files
  where 1 = 1`;

async function find(context) {
  let query = baseQuery;
  const binds = {};

  if (context.id) {
    binds.id = context.id;
 
    query += '\nand id = :id';
  }

  const result = await database.simpleExecute(query, binds);

  return result.rows;
}

module.exports.find = find;
