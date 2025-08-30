use MyDatabase;

-- ==========
-- The main table
-- ==========

create table A_section(
		id int,
		name varchar(10)
)

select * from A_section;  -- Main table Select Statement

-- ==========
-- Triggering table
-- ==========

create table A_attendence(
		id int,
		date date,
		day varchar(10),
		status varchar(10)
)

-- ========
-- The Trigger
-- ========

create trigger add_status on A_section 
		after insert as

		begin
				insert into A_attendence(id,date,day,status)
						select
								id,
								getdate(),
								DATENAME(weekday,Getdate()),
								'Attended'
						from inserted
		end

select * from A_attendence  -- Trigger table Select statement

-- ====================
-- Inserting values to Main table
-- ====================

insert into A_section (id,name) values
											 (1,'Shin Chan'),
											 (2,'Nobita'),
											 (3,'Doremon'),
											 (4,'Captain'),
											 (5,'Superman'),
											 (6,'Spong boob'),
											 (7,'Batman'),
											 (8,'MoonKnight'),
											 (9,'Ran Vijay'),
											 (10,'Chari'),
											 (11,'Gymmer'),
											 (12,'Ben'),
											 (13,'Tenkai'),
											 (14,'Dhruva'),
											 (15,'Sensation');

-- ============
-- Stored Procedure
-- ============

alter procedure a_cal as
	begin
		drop table cta_table;

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
			@total_days AS [Total Days],
			concat(round((cast(Days_attendend as float) /
				cast(@total_days as float) )*100,2),' % ') as [Percent]
		from
			(select
						id as ID,
						count(*) /*over(partition by id) */as Days_attendend
			from A_attendence 
			group by id)t
			order by Days_attendend asc

end

select * from cta_table		-- Select statement for cta_table

-- ==============
-- Executing Procedure
-- ==============

exec a_cal;

-- ======
-- The End
-- ======