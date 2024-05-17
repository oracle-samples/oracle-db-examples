SMALL R rows are an optimization for indexes which suffer from contention
on the $R row. It reduces the chunk size in the $R table.
In 19c this problem is eliminated by using FAST_IO (default for new indexes)
which eliminates the $R table.

In earlier versions the 'official' solution to move to small R rows was to
rebuild the index. However, we developed unofficial scripts which would 
rewrite the $R table into smaller chunks without a complete rebuild -
which was very much faster.
