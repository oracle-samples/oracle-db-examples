begin
  for csr1 in (select clusterid, label from clu_clusters) loop
     dbms_output.put_line('Cluster ID : '||csr1.clusterid||', Label: '||csr1.label);
     for csr2 in (select n.title, c.score 
                  from news n, clu_restab c
                  where n.pk = c.docid
                  and c.clusterid = csr1.clusterid
                  and c.score > 0.01 
                  order by score desc) loop
        dbms_output.put_line('Clust:'||csr1.clusterid||' Score:'||csr2.score||': '||csr2.title);
     end loop;
  end loop;
end;
/
