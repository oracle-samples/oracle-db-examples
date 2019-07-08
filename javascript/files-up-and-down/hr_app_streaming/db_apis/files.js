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
    empty_blob()
  ) returning
    id,
    blob_data
  into :id,
    :blob_data`;

async function create(fileName, contentType, contentStream) {
  return new Promise(async (resolve, reject) => {
    let conn;

    try {
      conn = await oracledb.getConnection();

      let result = await conn.execute(
        createSql,
        {
          file_name: fileName,
          content_type: contentType,
          id: {
            type: oracledb.NUMBER,
            dir: oracledb.BIND_OUT
          },
          blob_data: {
            type: oracledb.BLOB,
            dir: oracledb.BIND_OUT
          }
        }
      );

      const lob = result.outBinds.blob_data[0];

      contentStream.pipe(lob);

      contentStream.on('error', err => {
        // Forward error along to handler on lob instance
        lob.emit('error', err);
      });

      lob.on('error', async err => {
        try {
          await conn.close();
        } catch (err) {
          console.error(err);
        }

        reject(err);
      });

      lob.on('finish', async () => {
        try {
          await conn.commit();
          resolve(result.outBinds.id[0]);
        } catch (err) {
          console.log(err);
          reject(err);
        } finally {
          try {
            await conn.close();
          } catch (err) {
            console.error(err);
          }
        }
      });
    } catch (err) {
      reject(err);
    }
  });
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

  let conn;

  try {
    conn = await oracledb.getConnection();

    const result = await conn.execute(getSql, binds, {outFormat: oracledb.OBJECT});

    if (result.rows[0]) {
      result.rows[0].blob_data.on('close', async () => {
        try {
          await conn.close();
        } catch (err) {
          console.log(err);
        }
      });

      result.rows[0].blob_data.on('error', (err) => {
        // destory will trigger a 'close' event when it's done
        result.rows[0].blob_data.destroy();
      });
    }

    return result.rows[0];
  } catch (err) {
    console.log(err);

    if (conn) {
      try {
        await conn.close();
      } catch (err) {
        console.log(err);
      }
    }
  }
}

module.exports.get = get;

const deleteSql =
 `delete from jsao_files
  where id = :id`

async function del(id) {
  const binds = {
    id: id
  };

  const result = await database.simpleExecute(deleteSql, binds);

  return result.rowsAffected === 1;
}

module.exports.delete = del;