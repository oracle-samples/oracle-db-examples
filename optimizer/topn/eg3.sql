SELECT deptno, job, APPROX_SUM(sal) sum_sal,
       APPROX_SUM(sal,'MAX_ERROR') sum_sal_err
FROM   emp
GROUP BY deptno, job
HAVING APPROX_RANK(partition by deptno ORDER BY APPROX_SUM(sal) desc) <= 2;
