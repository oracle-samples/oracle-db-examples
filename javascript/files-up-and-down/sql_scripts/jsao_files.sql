create table jsao_files (
  id number generated always as identity not null,
  file_name varchar2(255) not null,
  content_type varchar2(255),
  blob_data blob,
  constraint jsao_files_pk primary key (id)
);