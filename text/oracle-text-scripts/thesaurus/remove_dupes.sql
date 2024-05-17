delete from eloc_work where rowid in 
( select a.rowid from eloc_work a, eloc_work b
    where a.area_id = b.area_id
    and a.rowid > b.rowid
);

