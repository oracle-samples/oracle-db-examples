const files = require('../db_apis/files.js');

async function post(req, res, next) {
  try {
    const maxFileSize = 1024 * 1024 * 50; // 50 MB
    let contentBuffer = [];
    let totalBytesInBuffer = 0;
    let contentType = req.headers['content-type'] || 'application/octet';
    let fileName = req.headers['x-file-name'];

    if (fileName === '') {
      res.status(400).json({error: 'The file name must be passed in the via x-file-name header'});
      return;
    }

    req.on('data', chunk => {
      contentBuffer.push(chunk);
      totalBytesInBuffer += chunk.length;

      // Look to see if the file size is too large.
      if (totalBytesInBuffer > maxFileSize) {
        req.pause();

        res.header('Connection', 'close');
        res.status(413).json({error: `The file size exceeded the limit of ${maxFileSize} bytes`});

        req.connection.destroy();
      }
    });

    // Could happen if the client cancels the upload.
    req.on('aborted', function() {
      // Nothing to do with buffering, garbage collection will clean everything up.
    });

    req.on('end', async function() {
      contentBuffer = Buffer.concat(contentBuffer, totalBytesInBuffer);
      
      try {
        const fileId = await files.create(fileName, contentType, contentBuffer);

        res.status(201).json({fileId: fileId});
      } catch (err) {
        console.error(err);

        res.header('Connection', 'close');
        res.status(500).json({error: 'Oops, something broke!'});

        req.connection.destroy();
      }
    });
  } catch (err) {
    next(err);
  }
}

module.exports.post = post;

async function get(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);

    if (isNaN(id)) {
      res.status(400).json({error: 'Missing or invalid file id'});
      return;
    }

    const rows = await files.get(id);

    if (rows.length === 1) {
      res.status(200);

      res.set({
        'Cache-Control': 'no-cache',
        'Content-Type': rows[0].content_type,
        'Content-Length': rows[0].file_length,
        'Content-Disposition': 'attachment; filename=' + rows[0].file_name
      });

      res.send(rows[0].blob_data);
    } else {
      res.status(404).end();
    }
  } catch (err) {
    next(err);
  }
}

module.exports.get = get;

async function del(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);

    if (isNaN(id)) {
      res.status(400).json({error: 'Missing or invalid file id'});
      return;
    }

    const success = await files.delete(id);

    if (success) {
      res.status(204).end();
    } else {
      res.status(404).end();
    }
  } catch (err) {
    next(err);
  }
}

module.exports.delete = del;
