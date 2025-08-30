/*
===============================================================
Customer Report
===============================================================

Purpose 
			- The report consolidate customer merits and behaviour

Highlights:-
# Gather essential fields like:- Name, age and Transaction details.
# Segmentng customers into 3 categories (Vip, Regular, New) and their age groups.
# Aggregations.
			- Total Orders
			- Total Sales
			- Total quantity purchases
			- Total Products
			- Lifespan (in months)
# Calculates valuable KPIs.
			- Recency (months since last order)
			- Average order value
			- Average monthly spend
===============================================================
*/

create view gold.Customer_report as
with base as 
(
/*----------------------------------------------------------------------------------------------------------
Base Query: Retrive base columns from the tables.
----------------------------------------------------------------------------------------------------------*/
		select 
				f.order_number,
				f.product_key,
				f.order_date,
				f.sales_amount,
				f.quantity,
				c.customer_key,
				c.customer_number,
				CONCAT(c.first_name, ' ',c.last_name) as Name,
				datediff(year,c.birthdate,'2014-12-31') as Age
		from gold.fact_sales f
				left join gold.dim_customers c on
				f.customer_key = c.customer_key
		where f.order_date is not null
)
, cust_agg as
(
/*----------------------------------------------------------------------------------------------------------
Aggregate Query: Aggregations will done on table.
----------------------------------------------------------------------------------------------------------*/
		select
				customer_key,
				customer_number,
				Name,
				Age,
				COUNT(distinct order_number ) Total_orders,
				sum(Sales_amount) Total_sales,
				sum(quantity) Total_quantity,
				sum(distinct product_key) Total_products,
				max(order_date) Last_order_date,
				datediff(MONTH,min(order_date),max(order_date)) Life_span
		from base
		group by customer_key,customer_number,Name,Age
)

/*----------------------------------------------------------------------------------------------------------
Main Query: Final Transformation of the table.
----------------------------------------------------------------------------------------------------------*/

select
		customer_key,
				customer_number,
				Name,
				Age,
				case when age <= 29 then '20s'
						when age <= 39 then '30s'
						when age <= 49 then '40s'
						when age <= 59 then '50s'
				else 'Above 60 '
				end Age_group,
				 case when Life_span>= 12 and Total_sales > 5000
						 then 'Vip'
						 when Life_span>= 12 and Total_sales < 5000
						 then 'Regular'
						 else 'New'
				end as Cust_Segment,
				Last_order_date,
				datediff(month, last_order_date, '2014-12-31') Recency,
				Total_orders,
				Total_sales,
				Total_quantity,
				Total_products,
				Life_span,

				-- Computing average order value
				Total_sales/total_orders Avg_order_value,

				-- Computing Monthly Spending
				case when life_span = 0 then Total_sales
				else Total_sales/Life_span
				end Avg_monthly_spend
from cust_agg