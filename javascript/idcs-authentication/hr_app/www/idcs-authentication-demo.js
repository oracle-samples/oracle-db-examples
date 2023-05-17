(function() {

  $(document).ready(init);

  function init() {
    fetch('/user')
      .then(response => {
        return response.json();
      })
      .then(user => {
        if (user.authenticated) {
          handleAuthenticated();
        } else {
          handleUnauthenticated();
        }
      });
  }

  function handleAuthenticated() {
    $('#logout-btn').parent().removeAttr('hidden');

    fetch('/api/employees')
      .then(response => {
        return response.json();
      })
      .then(employees => {
        let newRowsHtml = '';

        employees.forEach(function(employee) {
          newRowsHtml +=
            '<tr>' +
            `<td>${employee.id}</td>` +
            `<td>${employee.first_name} ${employee.last_name}</td>` +
            `<td>${employee.email}</td>` +
            `<td>${employee.phone_number}</td>` +
            `<td>${employee.job_id}</td>` +
            `<td>${employee.salary}</td>` +
            `<td>${(employee.commission_pct === null ? '-' : employee.commission_pct)}</td>` +
            '</tr>\n';
        });

        $('#employees-tbl').children('tbody').html(newRowsHtml);
      });
  }

  function handleUnauthenticated() {
    $('#login-btn').parent().removeAttr('hidden');
    $('#unauthenticated-msg').removeAttr('hidden');
  }

}());