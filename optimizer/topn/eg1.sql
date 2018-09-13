ELECT deptno, job, APPROX_SUM(sal),
       APPROX_RANK(partition by deptno ORDER BY APPROX_SUM(sal) desc) rk
FROM   emp
GROUP BY deptno, job
HAVING APPROX_RANK(partition by deptno ORDER BY APPROX_SUM(sal) desc) <= 10;

