(function() {
  var $filesToUploadTbl,
    $filesToUpload,
    $fileInput,
    $fileUploadBtn,
    $filesInDb,
    fileIdMap;

  $(document).ready(init);

  function init() {
    $filesToUploadTbl = $('#files-to-upload');
    $filesToUpload = $filesToUploadTbl.find('tbody');
    $fileInput = $('#file-input');
    $fileUploadBtn = $('#file-upload');

    $fileUploadBtn.on('click', handleUploadClick);

    $filesInDb = $('#files-in-db').find('tbody');

    $filesInDb.on('click', '.delete', deleteFile);

    if (window.File && window.FileReader && window.FileList && window.Blob) {
      $fileInput.on('change', handleFileSelect);
    } else {
      $('#browser-support-warning').show();
    }

    refreshFilesInDatabase();
  }

  function handleFileSelect(event) {
    var idx,
      newFilesHtml = '',
      selectedFiles = event.target.files;

    fileIdMap = {};

    $filesToUpload.empty();

    if (selectedFiles.length) {
      for (idx = 0; idx < selectedFiles.length; idx += 1) {
        fileIdMap[selectedFiles[idx].name] = idx;

        newFilesHtml +=
          '<tr id="file-id-' + fileIdMap[selectedFiles[idx].name] + '">' +
          '<td>' + selectedFiles[idx].name + '</td>' +
          '<td>' + selectedFiles[idx].type + '</td>' +
          '<td>' + selectedFiles[idx].size + '</td>' +
          '<td>' + selectedFiles[idx].lastModifiedDate.toISOString() + '</td>' +
          '<td>' +
            '<div class="progress mb-1">\n' +
              '<div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 0%">\n' +
                '<span class="sr-only">0%</span>\n' +
              '</div>\n' +
            '</div>' +
          '</td></tr>\n';
      }

      $filesToUpload.html(newFilesHtml);

      $fileUploadBtn.prop('disabled', false);
      $fileUploadBtn.parent().show();
      $filesToUploadTbl.show();
    } else {
      $fileUploadBtn.parent().hide();
      $fileUploadBtn.prop('disabled', true);
      $filesToUploadTbl.hide();
    }
  }

  function handleUploadClick() {
    var selectedFiles,
      maxSyncUploads = 3;

    $fileUploadBtn.prop('disabled', true);

    selectedFiles = $fileInput[0].files;

    async.eachLimit(
      selectedFiles,
      maxSyncUploads,
      uploadFile,
      reset
    );
  }

  function uploadFile(file, callback) {
    var xhr = new XMLHttpRequest();
    var $row = $filesToUpload.find('#file-id-' + fileIdMap[file.name]);
    var $progressBar = $row.find('.progress-bar');

    xhr.open('POST', '/api/files', true);

    xhr.setRequestHeader('x-file-name', file.name);
    xhr.setRequestHeader('x-content-type', file.type);

    xhr.onload = function(e) {
      if (e.currentTarget.status === 201) {
        $row.remove();
        refreshFilesInDatabase();
      } else if (e.currentTarget.status >= 400 && e.currentTarget.status <= 505) {
        var errorHtml = '<span class="label label-warning" data-placement="auto" title="' +
          JSON.parse(e.currentTarget.responseText).error +
          '"><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> Error</span>';

        $row.find('.progress').closest('td')
          .empty()
          .html(errorHtml)
            .find('.label')
            .tooltip();
      }

      callback();
    };

    xhr.upload.onprogress = function(e) {
      var percentComplete;

      if (e.lengthComputable) {
        percentComplete = (e.loaded / e.total) * 100;

        $progressBar
          .attr('aria-valuenow', percentComplete)
          .css('width', percentComplete + '%')
          .html('<span class="sr-only">' + percentComplete + '%</span>');
      }
    };

    xhr.send(file);
  }

  function reset(err) {
    $fileInput = $('#file-input');
    $fileInput.val(null);
    $fileInput.on('change', handleFileSelect);
  }
  
  function refreshFilesInDatabase() {
    fetch('/api/file_details')
      .then(response => {
        return response.json();
      })
      .then(files => {
        let newRowsHtml = '';

        files.forEach(function(file) {
          newRowsHtml +=
            '<tr>' +
            `<td data-id="${file.id}">${file.file_name}</td>` +
            `<td>${file.content_type}</td>` +
            `<td>${file.file_length}</td>` +
            `<td><a class="btn btn-primary btn-xs" href="/api/files/${encodeURIComponent(file.id)}" role="button">` +
            '    <span class="glyphicon glyphicon-download" aria-hidden="true"></span> Download</a>' +
            '</td>' +
            '<td>' +
            '    <button id="file-upload" class="btn btn-danger delete btn-xs" type="button">' +
            '        <span class="glyphicon glyphicon-trash" aria-hidden="true"></span> Delete' +
            '    </button>' +
            '</td>' +
            '</tr>\n';
        });

        $filesInDb.html(newRowsHtml);
      });
  }

  function deleteFile() {
    var $tr,
      fileName;

    $tr = $(this).closest('tr');
    fileId = parseInt($tr.find('td:first').data('id'));

    fetch(
      '/api/files/' + fileId,
      {
        method: 'DELETE'
      }
    ).then(() => {
      $tr.remove();
    });
  }
}());
