const oracledb = require('oracledb');
const database = require('../services/database.js');

const createSql =
 `insert into jsao_files (
    file_name,
    content_type,
    blob_data
  ) values (
    :file_name,
    :content_type,
    :content_buffer
  ) returning id into :id`;

async function create(fileName, contentType, contentBuffer) {
  const binds = {
    file_name: fileName,
    content_type: contentType,
    content_buffer: contentBuffer,
    id: {
      type: oracledb.NUMBER,
      dir: oracledb.BIND_OUT
    }
  };
  
  result = await database.simpleExecute(createSql, binds);
  
  return result.outBinds.id[0];
}

module.exports.create = create;

const getSql =
 `select file_name "file_name",
    dbms_lob.getlength(blob_data) "file_length",
    content_type "content_type",
    blob_data "blob_data"
  from jsao_files
  where id = :id`;

async function get(id) {
  const binds = {
    id: id
  };
  const opts = {
    fetchInfo: {
      blob_data: {
        type: oracledb.BUFFER
      }
    }
  };

  const result = await database.simpleExecute(getSql, binds, opts);

  return result.rows;
}

module.exports.get = get;

const deleteSql =
 `delete from jsao_files
  where id = :id`;

async function del(id) {
  const binds = {
    id: id
  };

  const result = await database.simpleExecute(deleteSql, binds);

  return result.rowsAffected === 1;
}

module.exports.delete = del;
