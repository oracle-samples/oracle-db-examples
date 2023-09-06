select parent.thp_phrase || '/' || this.thp_phrase 
from dr$ths_bt      rel, 
     dr$ths_phrase  this, 
     dr$ths_phrase  parent
where 
     rel.thb_thp_id = this.thp_id
     and rel.thb_bt = parent.thp_id
     and parent.thp_id not in 
     ( select sub.thb_thp_id from dr$ths_bt sub )
/
