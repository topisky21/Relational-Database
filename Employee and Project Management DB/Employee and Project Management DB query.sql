## Create employee_project_managementdb
create database employee_project_managementdb;

## Switch to employee_project_managementdb
use employee_project_managementdb;

## Create the Department Table
create table Departments(
	department_id int auto_increment Primary Key,
    department_name varchar(25) not null unique
);

## Create the Employees Table
create table employees(
	employee_id int auto_increment primary key,
    employee_name varchar(25) NOT NULL,
    email varchar(25),
	salary	decimal(10,2) CHECK(salary>0),
    department_id INT NOT NULL,
    hire_date DATE
);

## Create the Projects Table
create table Projects(
	project_id int auto_increment primary key,
    project_name varchar(25) NOT NULL,
    budget	decimal(10,2) CHECK(budget>0)    
);

## Create the Employee_Project Table
create table Employee_Project(
	employee_id int,
	project_id int,
    role varchar(40) default "Developer",
    primary key(employee_id,project_id),
    foreign key (employee_id) REFERENCES employees(employee_id),
    foreign key (project_id) REFERENCES Projects(project_id)   
);


## Add Foreign key in the employees table to the column  department_id
alter table employees
add constraint fk_department_id
foreign key (department_id)
REFERENCES Departments(department_id);


## Show the list of tables 
show tables;

## Show the columns in the following tables created:
select * from departments limit 10;
select * from employees limit 100;
select * from projects limit 100;
select * from employee_project limit 100;

## Q1. Find the total salary cost per department”
select d.department_id, d.department_name, sum(e.salary) as Total_Departmental_Salary
from departments d
join employees e
on d.department_id=e.department_id
group by d.department_name
order by Total_Departmental_Salary desc;

## Q2. List employees earning above their department average
select *
from(
	select 
		e.employee_name, 
        e.department_id,
		e.salary,
		avg(e.salary) over(partition by e.department_id) as avg_salary
    from employees e    
) t
where salary > avg_salary
order by salary desc;

## Q3. Find the top 3 highest-paid employees in each department
select * 
from (
	select 
		e.employee_name,
        d.department_name,
		e.salary,
		rank() over(partition by e.department_id order by e.salary desc)as rank_position
	from employees e
    join departments d
		on e.department_id = d.department_id
) ranked
where rank_position<=3;

## Q4. Find employees working on more than 3 projects
Select e.employee_name, count(ep.project_id) as number_of_projects
from employees e
join employee_project ep
	on e.employee_id = ep.employee_id
group by e.employee_name
having count(ep.project_id)>3
order by number_of_projects desc;

## Q5. Find total project budget handled by each employee
call projects();
call employee_table();
call employee_project_table();

select e.employee_name, sum(p.budget) as Total_budget
	from employees e
	join employee_project ep
		on e.employee_id=ep.employee_id
	join projects p
		on ep.project_id=  p.project_id
group by e.employee_name
order by Total_budget desc;

## Q6. Find employees assigned to non-existent projects
select * 
from employee_project ep
join projects p
	on ep.project_id = p.project_id
where p.project_id is null;

## Q7. Which department has the highest average salary?
select *
from(
	select 
		d.department_id, 
		d.department_name,
        avg(e.salary),
		rank() over(order by avg(e.salary)) as rnk
	from employees e
	join departments d
		on e.department_id = d.department_id
	group by d.department_id, d.department_name
)t
where rnk=1;

## Q8. Write a procedure to count employees in a department”
DELIMITER //
create PROCEDURE CountEmployeesByDept(
	IN dept_id INT,
    OUT total int
    )
Begin
	select count(*) INTO total
	from employees
	WHERE department_id = dept_id;
End //

DELIMITER ;

set @total=0;
call CountEmployeesByDept(9,@total);
select @total;

## 9. Find employees who earn more than the overall company average
select 
	employee_name, 
    salary
from employees
where salary > (
	select 
		avg(salary)
	from employees
    )
group by employee_name, salary
order by salary desc;

## 10. Find the department with the highest total project budget
call employee_table();
call employee_project_table();
call projects();

select d.department_id, d.department_name, sum(p.budget) as Total_Budget 
from departments d
join employees e
	on d.department_id = e.department_id
join employee_project ep
	on e.employee_id = ep.employee_id
join projects p
	on ep.project_id = p.project_id
group by d.department_id, d.department_name
order by Total_Budget desc
limit 1;