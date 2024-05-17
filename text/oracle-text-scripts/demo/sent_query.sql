select review_text,
 	    ctx_doc.sentiment_aggregate('shoeindex', rowid)
 from shoe_reviews
 where contains (review_text, 'adidas') > 0
 and ctx_doc.sentiment_aggregate('shoeindex', rowid) > 20;
