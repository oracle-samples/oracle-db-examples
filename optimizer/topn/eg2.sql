connect scott/tiger 

SELECT deptno, job, APPROX_SUM(sal), APPROX_COUNT(*)
FROM   emp
GROUP BY deptno, job
HAVING APPROX_RANK(partition by deptno ORDER BY APPROX_SUM(sal) desc) <= 2
AND    APPROX_RANK(partition by deptno ORDER BY APPROX_COUNT(*) desc) <= 3;

