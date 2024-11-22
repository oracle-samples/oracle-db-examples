begin
  ctx_output.add_trace(1);
  ctx_output.add_trace(2);
  ctx_output.add_trace(3);
  ctx_output.add_trace(4);
  ctx_output.add_trace(5);
  ctx_output.add_trace(6);
  ctx_output.add_trace(7);
  ctx_output.add_trace(8);
  ctx_output.add_trace(9);
  ctx_output.add_trace(10);
  ctx_output.add_trace(11);
  ctx_output.add_trace(12);
  ctx_output.add_trace(13);
  ctx_output.add_trace(14);
  ctx_output.add_trace(15);
end;
/

-- run your query here --
select * from foo where contains (x, 'xx') > 0;

-- get stats
select * from ctx_trace_values;
