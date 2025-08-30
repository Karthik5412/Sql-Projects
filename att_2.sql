--use MyDatabase;

alter procedure a_cal as
	begin
		--if OBJECT_ID('cta_table','u') is not null  -- Condition used in updation
					drop table cta_table;
		--go
				select
						date,
						count(*) as Total_Present
				into cta_table
				from A_attendence
				group by date;
		declare 
			@total_days int
		select
			@total_days = count(*)
		from cta_table;

		print('Total days : ' + cast(@total_days as varchar));

		select
				*,
			   ( cast(Days_attendend/@total_days as float))*100 as [percent] from
				(select
						id,
						count(*) over(partition by id) as Days_attendend
				from A_attendence)t

				print('Totoal shit: ' + Da
end

--select * from cta_table

exec a_cal