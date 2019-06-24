const files = require('../db_apis/files.js');
const { Transform } = require('stream');

// Create a new transform stream class that can validate files.
class FileValidator extends Transform {
  constructor(options) {
    super(options.streamOptions);

    this.maxFileSize = options.maxFileSize;
    this.totalBytesInBuffer = 0;
  }

  _transform (chunk, encoding, callback) {
    this.totalBytesInBuffer += chunk.length;

    // Look to see if the file size is too large.
    if (this.totalBytesInBuffer > this.maxFileSize) {
      const err = new Error(`The file size exceeded the limit of ${this.maxFileSize} bytes`);
      err.code = 'MAXFILESIZEEXCEEDED';
      callback(err);
      return;
    }

    this.push(chunk);

    callback(null);
  }

  _flush (done) {
    done();
  }
}

async function post(req, res, next) {
  try {
    // Get a new instance of the transform stream class.
    const fileValidator = new FileValidator({
      maxFileSize: 1024 * 1024 * 5000 // 50 MB
    });
    let contentType = req.headers['content-type'] || 'application/octet';
    let fileName = req.headers['x-file-name'];

    if (fileName === '') {
      res.status(400).json({error: 'The file name must be passed in the via x-file-name header'});
      return;
    }

    // Pipe the request stream into the transform stream.
    req.pipe(fileValidator);

    // Could happen if the client cancels the upload. Forward upstream as an error.
    req.on('aborted', function() {
      fileValidator.emit('error', new Error('Upload aborted.'));
    });

    try {
      const fileId = await files.create(fileName, contentType, fileValidator);

      res.status(201).json({fileId: fileId});
    } catch (err) {
      console.error(err);

      res.header('Connection', 'close');

      if (err.code === 'MAXFILESIZEEXCEEDED') {
        res.status(413).json({error: err.message});
      } else {
        res.status(500).json({error: 'Oops, something broke!'});
      }

      req.connection.destroy();
    }
  } catch (err) {
    next(err);
  }
}

module.exports.post = post;

async function get(req, res, next) {
  try {
    let aborted = false;
    let row;
    const id = parseInt(req.params.id, 10);

    if (isNaN(id)) {
      res.status(400).json({error: 'Missing or invalid file id'});
      return;
    }

    // Could happen if the client cancels the download. Forward upstream as an error.
    req.on('aborted', function() {
      aborted = true;

      if (row) {
        row.blob_data.emit('error', new Error('Download aborted.'));
      }
    });

    row = await files.get(id);

    // It's possible the aborted event happened before the readable stream was
    // obtained. Reemit the event to handle the error.
    if (aborted) {
      row.blob_data.emit('aborted');
    } 

    if (row) {
      res.status(200);

      res.set({
        'Cache-Control': 'no-cache',
        'Content-Type': row.content_type,
        'Content-Length': row.file_length,
        'Content-Disposition': 'attachment; filename=' + row.file_name
      });

      row.blob_data.pipe(res);
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