create unique index emp_pk on employees(id);
create unique index task_pk on tasks(id);
create index task_emp_fk on tasks(emp_id);
