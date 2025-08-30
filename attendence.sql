use MyDatabase;

create table A_section(
		id int,
		name varchar(10)
)

select * from A_section;

create table A_attendence(
		id int,
		date date,
		day varchar(10),
		status varchar(10)
)

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

select * from A_attendence

insert into A_section (id,name) values
											 (11,'Gymmer'),
											 (2,'Nobita'),
											 (3,'Doremon'),
											 (4,'Captain'),
											 (5,'Superman'),
											 (6,'Spong boob'),
											 (7,'Batman'),
											 (13,'Tenkai'),
											 (14,'Dhruva'),
											 (15,'Sensation');

create procedure attend_percent as
begin


		select
				*,
				cast((Days_attended/Total_days)as float) * 100 [percentage %]
		from(
				select
						id,
						count(*) over(partition by id order by id) as Days_attended,
						cast (datediff(day,GETDATE(),min(date)over())as float) +2 as Total_days
				from A_attendence
				)t
end

exec attend_percent

create procedure attend_percent2 as
begin

declare
		@tdays int = 0,
		@start date 

				select
						@start = min(date)
				from A_attendence;

		while @start <= getdate()
		begin
				if exists(select datename(weekday,@start) from A_section where datename(weekday,@start) != 'Sunday')
					begin
						set @tdays  = @tdays +1;
					end
		end
		
		select 
				id,
				Days_attended,
				(Days_attended/@tdays)*100 as percentage
		from(
				select
						id,
						count(*) over(partition by id order by id) as Days_attended,
						cast (datediff(day,GETDATE(),min(date)over())as float) +2 as Total_days
				from  A_attendence
				)t
end

exec attend_percent2;

create procedure attend_percent3 as
begin

declare
		@tdays int = 0,
		@start date 

				select
						@start = min(date)
				from A_attendence;

		while @start <= getdate()
		begin
				if exists(select datename(weekday,@start) from A_section where datename(weekday,@start) != 'Sunday')
					begin
						set @tdays  = @tdays +1;
					end
		end
		
		select 
				id,
				Days_attended,
				(Days_attended/@tdays)*100 as percentage
		from(
				select
						id,
						count(*) over(partition by id order by id) as Days_attended
						--cast (datediff(day,GETDATE(),min(date)over())as float) +2 as Total_days
				from  A_attendence
				)t;
				select 
						id,
						count(*) over(partition by id order by id) as Days_attended,
						 (count(*) over(partition by id order by id)/@tdays)*100 as [percetage]
						from A_attendence;

end

exec attend_percent3;

CREATE PROCEDURE attend_percent4
AS
BEGIN
    -- Declare a variable to hold the total number of working days
    DECLARE @totalWorkingDays INT;

    -- Get the minimum attendance date from the table
    DECLARE @minDate DATE;
    SELECT @minDate = MIN(date) FROM A_attendance;

    -- Calculate the total number of working days (excluding Sundays) from the min date to today
    -- This is much more efficient than using a WHILE loop.
    SELECT @totalWorkingDays = COUNT(date)
    FROM (
        -- Generate a list of all dates between the minimum attendance date and today
        SELECT TOP (DATEDIFF(day, @minDate, GETDATE()) + 1)
               DATEADD(day, ROW_NUMBER() OVER(ORDER BY a.object_id) - 1, @minDate) AS date
        FROM sys.all_objects a
    ) AS AllDates
    WHERE DATENAME(weekday, AllDates.date) <> 'Sunday';

    -- Check if the total working days is zero to avoid division by zero errors
    IF @totalWorkingDays = 0
    BEGIN
        SELECT 'No working days in the specified range.' AS Message;
        RETURN;
    END

    -- Final query to calculate attendance percentage for each student
    SELECT
        id,
        Days_attended,
        CAST((Days_attended * 100.0 / @totalWorkingDays) AS DECIMAL(5, 2)) AS percentage
    FROM (
        -- Inner query to count the days attended by each student
        SELECT
            id,
            COUNT(*) AS Days_attended
        FROM A_attendance
        GROUP BY id
    ) AS t;
END;


exec attend_percent4

exec attend_percent