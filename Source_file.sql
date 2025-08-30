-- ==========================
-- Changes over time analysis (Line Chart)
-- ==========================

-- Finding the sales over time 

select 
		datetrunc(month,order_date) Order_date,
		sum(sales_amount) Total_sales,
		sum(quantity) Total_quantitiy,
		count(distinct customer_key) as New_customers
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)
order by datetrunc(month,order_date);

-- ==========================
-- Cummulative Analysis (Waterfall Chart)
-- ==========================

-- Finding cummulative sales

select 
		Order_date,
		Total_sales,
		--window function
		sum(total_sales) over(order by order_date) Running_total,
		avg(Average_Price) over(order by order_date) Moving_Average
from
		(
		select 
				datetrunc(YEAR,order_date) Order_date,
				sum(sales_amount) Total_Sales,
				avg(sales_amount) Average_Price
		from gold.fact_sales
		where order_date is not null
		group by datetrunc(YEAR,order_date)
		)t;

-- ===========================
-- Performance Analysis (Bar chart with line)
-- ===========================

-- Comparing the product sales with the average

-- CTE
with yearly_sales as(					
select
		year(f.order_date) Order_Year,
		p.product_name,
		sum(f.sales_amount) Current_sales
from gold.fact_sales f
join gold.dim_products p on
		f.product_key= p.product_key
where order_date is not null
group by  year(f.order_date),p.product_name
);

select 
		Product_name,
		Order_Year,
		Current_sales,
		avg(current_sales) over(partition by product_name) Avg_Sales,
		Current_sales - avg(current_sales) over(partition by product_name) as Progress,
		case
			when Current_sales - avg(current_sales) over(partition by product_name) >0
					then 'Below Avg'
			when Current_sales - avg(current_sales) over(partition by product_name) <0
					then 'Above Avg'
			else 
					 'Equal to Avg'
		end Status,
		lag(current_sales) over(partition by product_name order by Order_year) [Prev year Sales],
		Current_sales - lag(current_sales) over(partition by product_name order by Order_year)
		as Sales_Boost,
		case	
				when  Current_sales - lag(current_sales) over(partition by product_name order by Order_year) > 0
						then 'Increased'
				when Current_sales - lag(current_sales) over(partition by product_name order by Order_year) <0
						then 'Decreased'
				else 'No Change'
			end Pro_of_Product_Sales
from yearly_sales;

-- ========================
-- Part to Whole analysis (Donut Chart)
-- ========================

-- Category which providing highest revenue

select
		*,
		sum(Total_sales_cat) over() Total_sales,
		round((cast(Total_sales_cat as float)/sum(Total_sales_cat) over() )*100,2) as Share 
from(
		select
				p.category,
				sum(sales_amount) Total_sales_cat
		from gold.fact_sales f
		join gold.dim_products p on
				f.product_key=p.product_key
		group by p.category 
)t
order by Total_sales_cat desc;

-- =====================
-- Data Segmenting (Scatter Chart)
-- =====================

-- Segmenting the products by their cost range

select 
		Cost_Range,
		count(product_key) Total_customers
from (
		select
				product_key,
				product_name,
				cost,
				case when cost < 100 then 'Below 100'
						when cost between 100 and 500 then '100 to 500'
						when cost between 500 and 1000 then '500 to 1000'
						when cost between 1000 and 1500 then '1000 to 1500'
				else 'Above 1500'
				end Cost_Range
		from gold.dim_products
)t
group by Cost_Range
order by count(product_key) desc;

/* Couting the customers who are spending more than 5000 as vip and 
less than 5000 from 1 year as Regular and the new customers who ordering from an year as new
Segment them like a group each*/

select
		count(customer_key) Total_Customers,
		Cader
from
(
		select 
				customer_key,
				case when Total_amount > 5000 and Life_span >= 12
						then 'VIP'
						when Total_amount <=5000 and Life_span >= 12
						then 'Regular'
				else 'New'
				end Cader
		from
		(
				select 
						c.customer_key,
						sum(f.sales_amount) Total_amount,
						min(f.order_date) First_Order,
						max(f.order_date) Last_Order,
						datediff(month,min(f.order_date),max(f.order_date)) Life_span
				from gold.fact_sales f
				left join gold.dim_customers c
						on f.customer_key=c.customer_key
				group by c.customer_key
		)t
)t
group by Cader