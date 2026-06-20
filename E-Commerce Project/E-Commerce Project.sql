#create the e_commerce database
Create database E_Commercedb;

#swich to the e_commerce database
use E_Commercedb;

#create the customers table
create table customers(
	customer_id int unique Primary Key,
    first_name varchar(100),
    last_name varchar(100),
    email varchar(100) default "N/A",
    country varchar(100) default "N/A",
    signup_date datetime,
    customer_segment varchar(100)
);

#create the orders table
create table orders(
	order_id int unique Primary Key,
    customer_id int,
    order_date date,
    order_status varchar(40) default "N/A",
    payement_method varchar(20) default "N/A",
    shipping_city datetime,
    total_amount decimal(12,2),
    foreign key (customer_id) REFERENCES customers(customer_id)
);

#create the order_items table
create table order_items(
	order_item_id int unique Primary Key,
    order_id int,
    product_id int,
    quantity int, 
    unit_price decimal(5,2),
    discount decimal(5,2),
    foreign key (order_id) references orders(order_id)    
);

#create the products table
create table products(
	product_id int unique Primary Key,
    product_name varchar(30),
    category_id int,
    brand varchar(30), 
    cost_price decimal(5,2) check(cost_price>0),
    selling_price decimal(5,2) check(selling_price>0),
    stock_quantity int    
);

#create the categories table
create table categories(
	category_id int unique Primary Key,
    category_name varchar(30)
);

#create the website_events table
create table website_events(
	event_id int unique,
    customer_id int,
    session_id int,
    event_type varchar(30), 
    page_url varchar(100), 
    event_timestamp datetime,
    device_type varchar(100),
    foreign key (customer_id) references customers(customer_id)
);

#create the payments table
create table payments (
payment_id int unique primary key,	
order_id int,
payment_status varchar(10),
payment_date date,
payment_amount decimal(10,2),
foreign key (order_id) references orders(order_id)
);

#create the returns table
create table returns (
return_id int unique primary key,	
order_id int,
return_reason varchar(10),
return_date date,
refund_amount decimal(10,2),
foreign key (order_id) references orders(order_id)
);

#show the list of table in the e_commerce database
show tables;

# add constraints
alter table order_items
add constraint fk_product_id_order_items
foreign key (product_id) 
references products(product_id);

alter table products
add constraint fk_category_id_products
foreign key (category_id) 
references categories(category_id);

ALTER TABLE orders
rename column payement_method to payment_method;

alter table returns
rename column return_amount to refund_amount;
SHOW TABLES;


# Create store procedure
delimiter \\
CREATE PROCEDURE returns()
begin	
	select *
	from returns;
end \\
delimiter ;

call returns();

update returns
set refund_amount = trim(refund_amount);

call returns();

SET GLOBAL local_infile = 0;

SHOW VARIABLES LIKE 'secure_file_priv';

SELECT CURRENT_USER();

ALTER TABLE returns
MODIFY return_reason VARCHAR(255);

# Load Excel Files into MySql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/returns.csv'
INTO TABLE returns_staging
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER table orders
	modify column order_date text,
	modify column shipping_city text;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/E_commerce DB Files/orders.csv"
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY "\n"
IGNORE 1 ROWS;

Alter table order_items
add constraint fk_product_id_order_items
FOREIGN KEY (product_id)
REFERENCES products(product_id);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/E_commerce DB Files/order_items.csv"
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

Alter table order_items
add constraint fk_product_id_order_items
FOREIGN KEY (product_id)
REFERENCES products(product_id);

alter table products
modify column selling_price decimal(10,2);

load data infile "C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/E_commerce DB Files/products.csv"
into table products
fields terminated by ','
ENCLOSED BY '"'
lines terminated by '\n'
ignore 1 rows;

select
	constraint_name,
    table_name,
    column_name,
    referenced_table_name,
    referenced_column_name
from information_schema.key_column_usage
where table_name='payments'
AND REFERENCED_TABLE_NAME IS NOT NULL
AND REFERENCED_TABLE_NAME IS NOT NULL;

alter table website_events
modify column session_id varchar(150);

load data infile "C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/E_commerce DB Files/website_events.csv"
into table website_events
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * 
from  website_events;

with session_count_table as (
	select 	
		device_type,
		event_type,
		count(session_id) as session_count
	from website_events
	group by device_type, event_type	
)

SELECT 
    device_type,
    event_type,
    session_count,
    ROW_NUMBER() OVER (
        PARTITION BY event_type
        ORDER BY session_count DESC
    ) AS session_rank
FROM session_count_table
WHERE event_type in ('add_to_cart', 'checkout') ;

USE e_commercedb;


#1. Find the most recent order for every customer.

select * from orders;
 
with recent_order_date as(
select 
	order_id,
	customer_id,
	order_status,
    order_date,
	total_amount,
	row_number() over (partition by customer_id order by order_date desc) as rn
from orders
)

select *
from recent_order_date
where rn =1;

#2 Find top-selling products in each category.
SELECT
    c.category_name,
    p.product_name,
    SUM(oi.quantity) AS total_units_sold,

    RANK() OVER (
        PARTITION BY c.category_name
        ORDER BY SUM(oi.quantity) DESC
    ) AS product_rank,

    DENSE_RANK() OVER (
        PARTITION BY c.category_name
        ORDER BY SUM(oi.quantity) DESC
    ) AS dense_product_rank

FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id

JOIN categories c
ON p.category_id = c.category_id

GROUP BY
    c.category_name,
    p.product_name;

#3 Track month-over-month revenue growth
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(total_amount) AS revenue
    FROM orders
    GROUP BY 1
)

SELECT
    month,
    revenue,
    LAG(revenue) OVER (
        ORDER BY month
    ) AS previous_month,

    revenue -
    LAG(revenue) OVER (
        ORDER BY month
    ) AS revenue_growth

FROM monthly_sales;

#5.  Running Total 
SELECT
    order_date,
    total_amount,

    SUM(total_amount) OVER (
        ORDER BY order_date
    ) AS cumulative_revenue

FROM orders;


#6.  Moving Average
with order_per_day as(
	select
		order_date,
        day(order_date) as order_day,
		sum(total_amount) as total_order_amount
	from orders
    group by order_date
)

select
    order_date,
    total_order_amount,
	SUM(total_order_amount) OVER (
        ORDER BY order_date
		ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS six_days_moving_average

FROM order_per_day;


#7. Detect suspicious repeat payments within 5 minutes

WITH payment_check AS (
    SELECT
        customer_id,
        payment_amount,
        payment_date,

        LAG(payment_date) OVER (
            PARTITION BY customer_id
            ORDER BY payment_date
        ) AS previous_payment_time

    FROM payments p
    JOIN orders o
    ON p.order_id = o.order_id
    group by customer_id
)

SELECT *
FROM payment_check
WHERE DATEDIFF(MINUTE, previous_payment_time, payment_date) <= 5;


#8. Find inactive customers
SELECT
    customer_id,
    MAX(order_date) AS last_order_date
FROM orders
GROUP BY customer_id
HAVING MAX(order_date) < CURRENT_DATE - INTERVAL 90 DAY
order by last_order_date desc;
