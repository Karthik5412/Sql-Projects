--create view gold.final_copy as

with Core_cte as(
		select
				f.order_date,
				year(f.order_date) Order_Year,
				c.customer_key,
				f.product_key,
				p.product_name,
				p.category,
				p.cost,
				f.sales_amount,
				f.quantity
		from gold.fact_sales f
				left join gold.dim_customers c on
				f.customer_key = c.customer_key
				left join gold.dim_products p on
				f.product_key = p.product_key
),

Sales_trend as(
-- Sales Trend
select 
		customer_key,
		datetrunc(month,order_date) Month,
		sum(sales_amount) Total_sales,
		sum(quantity) Total_quantity,
		count(distinct product_key) New_customers
from Core_cte
where order_date is not null
group by datetrunc(month,order_date),customer_key
),

Lable_cte as(
select
		customer_key,
		datediff(month,min(order_date),max(order_date)) Life_span,
		case when sum(sales_amount) > 5000 and 
								datediff(month,min(order_date),max(order_date)) >= 12
						then 'VIP'
						when sum(sales_amount) <=5000 and 
								datediff(month,min(order_date),max(order_date)) >= 12
						then 'Regular'
				else 'New'
				end Cader
from Core_cte 
group by customer_key
),

Cost_range_cte as(
select
				cost,
				product_key,
				case when cost < 100 then 'Below 100'
						when cost between 100 and 500 then '100 to 500'
						when cost between 500 and 1000 then '500 to 1000'
						when cost between 1000 and 1500 then '1000 to 1500'
				else 'Above 1500'
				end Cost_Range
		from gold.dim_products
),

agg_cte as(
select
		customer_key,
		order_date,
		sum(sales_amount) Total_Sales,
		avg(sales_amount) Average_Price
from Core_cte
where order_date is not null
group by customer_key,order_date
)

select
		datetrunc(month,o.order_date) Month,
		o.order_date,
		o.product_name,
		o.category,
		c.cost,
		c.Cost_Range,
		s.Total_quantity,
		s.Total_sales,
		avg(a.Total_sales) over(partition by o.product_name) Avg_total,
		a.Average_Price,
		l.Cader,
		s.New_customers,
		l.Life_span,
		sum(a.total_sales) over(order by a.order_date) Running_total,
		avg(a.Average_Price) over(order by a.order_date) Moving_Average,
		a.Total_Sales - avg(a.Total_sales) over(partition by o.product_name) Progress,
		case
			when a.Total_sales - avg(a.Total_sales) over(partition by o.product_name) >0
					then 'Below Avg'
			when a.Total_sales - avg(a.Total_sales) over(partition by o.product_name) <0
					then 'Above Avg'
			else 
					 'Equal to Avg'
		end Status,
		lag(a.Total_sales) over(partition by o.product_name order by o.Order_year) [Prev year Sales],
		a.Total_sales - lag(a.Total_sales) over(partition by o.product_name order by o.Order_year)
		as Sales_Boost,
		case	
				when  a.Total_sales - lag(a.Total_sales) over(partition by product_name order by o.Order_year) > 0
						then 'Increased'
				when a.Total_sales - lag(a.Total_sales) over(partition by product_name order by o.Order_year) <0
						then 'Decreased'
				else 'No Change'
			end Pro_of_Product_Sales
into new_ctas
from Core_cte o
		left join Sales_trend s on
		o.customer_key=s.customer_key
		left join Lable_cte l on
		o.customer_key = l.customer_key
		left join Cost_range_cte c on
		o.product_key=c.product_key
		left join agg_cte a on
		o.customer_key =a.customer_key
where a.order_date is not null


select * from new_ctas