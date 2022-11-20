select emp_id, lastname --если бы ФИО было в одном поле, то использовали бы substr   
from (
select emp_id, lastname, firstname, rank() over (order by salary desc ) rnk
from employee
) as t1
where rnk =1;


select  lastname 
from employee
order by lastname asc;

select emp_level, avg( current_date - hiring_date) as avg_work_exg
from employee
group by emp_level;

select emp.lastname, dep.name
from employee emp
left join department dep
on emp.department_id = dep.dep_id  ;

select name, lastname, salary
from (
select dep.name, emp.lastname, salary, rank() over (partition by dep_id order by salary desc ) rnk   
from employee emp
left join department dep
on emp.department_id = dep.dep_id
) t1
where rnk =1;

select name
from (
select dep.name, rank( ) over (order by sum(salary * coalesce(bonus_coef, 1)) desc) rnk    
from employee emp
left join department dep
on emp.department_id = dep.dep_id
group by dep.name
) t1 
where rank = 1;

update employee
set salary = case when coalesce(bonus_coef, 1) > 1.2 then salary * 1.2 when coalesce(bonus_coef, 1) between 1 and 1.2 then salary * 1.1 else salary end;



with chief as (
select dep_id,name as dep_name,lastname as chief_lastname
from department dep  
left join employee emp
	on chief_id = emp.emp_id 
),
marks as (
select emp.emp_id,
sum( case when grade = 'A' then 1 else 0 end ) cnt_mark_A,
sum( case when grade = 'B' then 1 else 0 end ) cnt_mark_B,	
sum( case when grade = 'C' then 1 else 0 end ) cnt_mark_C,	
sum( case when grade = 'D' then 1 else 0 end ) cnt_mark_D,
sum( case when grade = 'E' then 1 else 0 end ) cnt_mark_E
from employee emp
left join rating rt
	on emp.emp_id = rt.emp_id
group by emp.emp_id
),
stats as (
select
dep.dep_id,
count(*)   as count_emp,
avg(current_date - hiring_date)   as avg_work_exg,
avg(salary::numeric)   as avg_salary,
sum( case when emp_level = 'jun' then 1 else 0 end )   as jun_cnt,
sum( case when emp_level = 'middle' then 1 else 0 end )  as middle_cnt,
sum( case when emp_level = 'senior' then 1 else 0 end )   as senior_cnt,
sum( case when emp_level = 'lead' then 1 else 0 end )  as lead_cnt,
sum(case when coalesce(bonus_coef, 1) > 1.2 then salary / 1.2 when coalesce(bonus_coef, 1) between 1 and 1.2 then salary / 1.1 else salary end) as sum_before_indexation,
sum( salary )   as sum_after_indexation,
sum(cnt_mark_A ) cnt_mark_A,
sum(cnt_mark_B) cnt_mark_B,	
sum(cnt_mark_C ) cnt_mark_C,	
sum(cnt_mark_D ) cnt_mark_D,
sum(cnt_mark_E ) cnt_mark_E,	
avg(coalesce(bonus_coef, 1)) as avg_bonus_coef,
sum(salary * coalesce(bonus_coef, 1)) as full_bonus,
sum((case when coalesce(bonus_coef, 1) > 1.2 then salary / 1.2 when coalesce(bonus_coef, 1) between 1 and 1.2 then salary / 1.1 else salary end) + (case when coalesce(bonus_coef, 1) > 1.2 then salary / 1.2 when coalesce(bonus_coef, 1) between 1 and 1.2 then salary / 1.1 else salary end) * coalesce(bonus_coef, 1) ) as sum_bonus_before_indexation,
sum(salary + salary * coalesce(bonus_coef, 1))  as sum_bonus_after_indexation,
(sum(salary +  salary * coalesce(bonus_coef, 1))  
-
 sum(case when coalesce(bonus_coef, 1) > 1.2 then salary / 1.2 when coalesce(bonus_coef, 1) between 1 and 1.2 then salary / 1.1 else salary end + case when coalesce(bonus_coef, 1) > 1.2 then salary / 1.2 when coalesce(bonus_coef, 1) between 1 and 1.2 then salary / 1.1 else salary end * coalesce(bonus_coef, 1) ))
/ (sum(salary +   salary * coalesce(bonus_coef, 1)))
* 100 as delta
from department dep  
left join employee emp
	on emp.department_id = dep.dep_id
left join marks mr
	on emp.emp_id = mr.emp_id
group by dep.dep_id
)
select 
stats.dep_id,
dep_name,
chief_lastname,
count_emp,
avg_work_exg,
avg_salary,
jun_cnt,
middle_cnt,
senior_cnt,
lead_cnt,
sum_before_indexation,
sum_after_indexation,
cnt_mark_A,
cnt_mark_B,	
cnt_mark_C,	
cnt_mark_D,
cnt_mark_E,	
avg_bonus_coef,
full_bonus,
sum_bonus_before_indexation,
sum_bonus_after_indexation,
delta
from stats
inner join 	chief
on stats.dep_id = chief.dep_id;
