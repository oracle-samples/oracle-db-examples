create unique index p_emp_pk on p_employees(id) local;
create unique index p_task_pk on p_tasks(id) local;
create index p_task_emp_fk on p_tasks(emp_id) local;
