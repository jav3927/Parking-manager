USE [master]
GO
/****** Object:  Database [Parking]    Script Date: 17.05.2020 18:56:37 ******/
CREATE DATABASE [Parking]
ALTER DATABASE [Parking] SET COMPATIBILITY_LEVEL = 140
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Parking].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Parking] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Parking] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Parking] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Parking] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Parking] SET ARITHABORT OFF 
GO
ALTER DATABASE [Parking] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [Parking] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Parking] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Parking] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Parking] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Parking] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Parking] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Parking] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Parking] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Parking] SET  ENABLE_BROKER 
GO
ALTER DATABASE [Parking] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Parking] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Parking] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Parking] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Parking] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Parking] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Parking] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Parking] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Parking] SET  MULTI_USER 
GO
ALTER DATABASE [Parking] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Parking] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Parking] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Parking] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [Parking] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [Parking] SET QUERY_STORE = OFF
GO
USE [Parking]
GO
/****** Object:  UserDefinedFunction [dbo].[CarInsertValidation]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[CarInsertValidation](@idU uniqueidentifier, @number nvarchar(20))--функция проверки при попытке добавить машину(не должно быть повторов)
returns int
as
	begin
	declare @ret int = 0
	if((select count(*) from Cars where userId=@idU and number=@number) > 0)
	begin
		set @ret=1
	end
	return @ret
end
GO
/****** Object:  UserDefinedFunction [dbo].[getCarsAll]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[getCarsAll](@idU uniqueidentifier)--функция получения списка всех автомобилей определённого пользователя
returns @ret table (id uniqueidentifier, userId uniqueidentifier, mark nvarchar(30), model nvarchar(100), number nvarchar(20)) as
	begin
	declare @id uniqueidentifier, @userId uniqueidentifier, @mark nvarchar(30), @model nvarchar(100), @number nvarchar(20),
		@counter int, @departureDate datetime
	declare cursF cursor for select * from Cars where userId = @idU
	open cursF
	fetch next from cursF into @id,@userId,@mark,@model,@number
	while @@FETCH_STATUS=0
	begin
		insert into @ret values(@id,@userId,@mark,@model,@number)
		fetch next from cursF into @id,@userId,@mark,@model,@number
	end
	close cursF
	deallocate cursF
	return
end
GO
/****** Object:  UserDefinedFunction [dbo].[getCarsFree]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[getCarsFree](@idU uniqueidentifier, @start datetime, @end datetime)--функция получения списка свободных автомобилей определённого пользователя на определённый промежуток времени
returns @ret table (id uniqueidentifier, userId uniqueidentifier, mark nvarchar(30), model nvarchar(100), number nvarchar(20)) as
	begin
	declare @id uniqueidentifier, @userId uniqueidentifier, @mark nvarchar(30), @model nvarchar(100), @number nvarchar(20),
		@counter int, @arrivalDate datetime,@departureDate datetime
	declare cursT cursor for select * from Cars where userId = @idU
	open cursT
	fetch next from cursT into @id,@userId,@mark,@model,@number
	while @@FETCH_STATUS=0
	begin
		set @counter = 0
		if((select count(*) from Books where carId = @id) > 0)
		begin
			declare cursC cursor for select arrivalDate,departureDate from Books where carId = @id
			open cursC
			fetch next from cursC into @arrivalDate,@departureDate
			while @@FETCH_STATUS=0
			begin
				if((@arrivalDate between @start and @end) or (@departureDate between @start and @end))
				begin
					set @counter+=1
				end
				fetch next from cursC into @arrivalDate,@departureDate
			end
			close cursC
			deallocate cursC
			if(@counter>0)
			begin					
				fetch next from cursT into @id,@userId,@mark,@model,@number
			end
			else
			begin
				insert into @ret values(@id,@userId,@mark,@model,@number)
				fetch next from cursT into @id,@userId,@mark,@model,@number
			end
		end
		else
		begin				
			insert into @ret values(@id,@userId,@mark,@model,@number)
			fetch next from cursT into @id,@userId,@mark,@model,@number
		end			
	end
	close cursT
	deallocate cursT
	return
end
GO
/****** Object:  UserDefinedFunction [dbo].[getParkingPlacesByDate]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getParkingPlacesByDate](@pakringId uniqueidentifier, @beginDate datetime, @endDate datetime)--функция получения списка парковочных мест опрееделённой парковки
returns @ret table(id uniqueidentifier, parkId uniqueidentifier, x float, y float, width float, 
	height float,state bit,path nvarchar(200), angle float, number nvarchar(8))
as 
begin
	declare @id uniqueidentifier, @parkId uniqueidentifier, @x float, @y float, @width float, @height float,
		 @state bit, @path nvarchar(200), @angle float, @number nvarchar(8), @counter int = 0
	declare @idB uniqueidentifier, @idCar uniqueidentifier, @idPP uniqueidentifier, @arDate datetime, @depDate datetime
	declare cursPPD cursor for select * from ParkingPlaces where ParkingId = @pakringId
	open cursPPD
	fetch next from cursPPD into @id, @parkId, @x, @y, @width, @height, @state, @path, @angle, @number
	while @@FETCH_STATUS=0
	begin
		set @counter = 0
		declare cursPPDB cursor for select Id,carId,parkingPlaceId,arrivalDate,departureDate from Books where parkingPlaceId = @id
		open cursPPDB
		fetch next from cursPPDB into @idB, @idCar, @idPP, @arDate, @depDate
		while @@FETCH_STATUS=0
		begin
			if((@arDate between @beginDate and @endDate) or (@depDate between @beginDate and @endDate))
			begin
				set @counter+=1
				break
			end
			fetch next from cursPPDB into @idB, @idCar, @idPP, @arDate, @depDate
		end
		close cursPPDB
		deallocate cursPPDB
		if(@counter > 0)
		begin
			set @state = 1

		end
		else
		begin
			set @state = 0			
		end
		insert into @ret values(@id, @parkId, @x, @y, @width, @height, @state, @path, @angle, @number)
		fetch next from cursPPD into @id, @parkId, @x, @y, @width, @height, @state, @path, @angle, @number
	end
	close cursPPD
	deallocate cursPPD
	return
end
GO
/****** Object:  UserDefinedFunction [dbo].[getReservationsById]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getReservationsById](@userId uniqueidentifier, @parkingId uniqueidentifier) --получить спиок броней определённого пользователя
returns @ret table(id uniqueidentifier, mark nvarchar(30), model nvarchar(100), number nvarchar(20), date1 datetime,
	date2 datetime, placeId uniqueidentifier, price float)
as 
begin
	declare @id uniqueidentifier, @mark nvarchar(30), @model nvarchar(100), @number nvarchar(20), @date1 datetime,
		@date2 datetime, @placeId uniqueidentifier, @price float
	declare cursGRI cursor for select Books.id, mark, model, Cars.number, arrivalDate, departureDate, parkingPlaceId, Books.price from Books 
		inner join Cars on carId = Cars.Id inner join Users on userId = Users.Id inner join ParkingPlaces on parkingPlaceId=ParkingPlaces.Id
	open cursGRI
	fetch next from cursGRI into @id,@mark,@model,@number,@date1 ,@date2,@placeId,@price 
	while @@FETCH_STATUS=0
	begin
		insert into @ret values(@id,@mark,@model,@number,@date1 ,@date2,@placeId,@price )
		fetch next from cursGRI into @id,@mark,@model,@number,@date1 ,@date2,@placeId,@price 
	end
	close cursGRI
	deallocate cursGRI
	return
end
GO
/****** Object:  UserDefinedFunction [dbo].[getUserByEmail]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[getUserByEmail](@email nvarchar(max)) -- получение данные о пользователе по email
returns @ret table(id uniqueidentifier, name nvarchar(20), surname nvarchar(30), password nvarchar(max), number nvarchar(max),
	email nvarchar(max))
as 
begin
	declare @id uniqueidentifier, @name nvarchar(20), @surname nvarchar(30), @password nvarchar(max), @number nvarchar(max),
		@email1 nvarchar(max)
	declare cursUBM cursor for select id,userName,Surname,password,userPhone,email from Users where email=@email
	open cursUBM
	fetch next from cursUBM into @id, @name,@surname,@password,@number,@email1
	insert into @ret values(@id, @name,@surname,@password,@number,@email1)
	return
end
GO
/****** Object:  UserDefinedFunction [dbo].[LogInValidation]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[LogInValidation](@login nvarchar(20), @pass nvarchar(25), @type nvarchar(10))--функция проверки корректности данных при логине
returns @ret table (id uniqueidentifier null, name nvarchar(20) null, surname nvarchar(30) null, password nvarchar(max) null, 
	number nvarchar(max) null,email nvarchar(max) null,errorCode int)
as 
begin
	declare @idU uniqueidentifier,
			@name nvarchar(20),
			@surname nvarchar(30), @email nvarchar(max), @number nvarchar(max)
	if(@type = 'email')
	begin
		if((select count(*) from Users where email = @login) = 0 or (select count(*) from Users where password = @pass) = 0 or 
			((select count(*) from Users where email = @login) = 0 and (select count(*) from Users where password = @pass) = 0))	
		begin
			insert into @ret values(null,null,null,null,null,null,1)
		end
		else
		begin
			set @idU = (select Id from Users where email = @login and password = @pass)
			set	@name = (select userName from Users where email = @login and password = @pass)
			set	@surname = (select Surname from Users where email = @login and password = @pass)
			set	@email = (select email from Users where email = @login and password = @pass)
			set	@number = (select userPhone from Users where email = @login and password = @pass)
			insert into @ret values(@idU,@name,@surname,@pass,@number,@email,0)
		end
		
	end
	if(@type = 'phone')
	begin		
		if((select count(*) from Users where email = @login) = 0 or (select count(*) from Users where password = @pass) = 0 or 
			((select count(*) from Users where email = @login) = 0 and (select count(*) from Users where password = @pass) = 0))	
		begin
			insert into @ret values(null,null,null,null,null,null,1)
		end
		else
		begin
			set @idU = (select Id from Users where userPhone = @login and password = @pass)
			set @name = (select userName from Users where userPhone = @login and password = @pass)
			set @surname = (select Surname from Users where userPhone = @login and password = @pass)
			set	@email = (select email from Users where userPhone = @login and password = @pass)
			set	@number = (select userPhone from Users where userPhone = @login and password = @pass)
			insert into @ret values(@idU,@name,@surname,@pass,@number,@email,0)
		end
	end
	return
end
GO
/****** Object:  Table [dbo].[Books]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Books](--таблица броней
	[Id] [uniqueidentifier] NOT NULL,
	[carId] [uniqueidentifier] NOT NULL,
	[parkingPlaceId] [uniqueidentifier] NOT NULL,
	[arrivalDate] [datetime] NOT NULL,
	[departureDate] [datetime] NOT NULL,
	[price] [float] NOT NULL,
 CONSTRAINT [BooksPK] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [Books_Unique] UNIQUE NONCLUSTERED 
(
	[carId] ASC,
	[parkingPlaceId] ASC,
	[arrivalDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [Books_UniqueDD] UNIQUE NONCLUSTERED 
(
	[carId] ASC,
	[parkingPlaceId] ASC,
	[departureDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Cars]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cars](--таблица автомобилей
	[Id] [uniqueidentifier] NOT NULL,
	[userId] [uniqueidentifier] NOT NULL,
	[mark] [nvarchar](30) NOT NULL,
	[model] [nvarchar](100) NOT NULL,
	[number] [nvarchar](20) NOT NULL,
 CONSTRAINT [CarsPK] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Parking]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Parking](--таблица парковок
	[Id] [uniqueidentifier] NOT NULL,
	[mapX] [float] NOT NULL,
	[mapY] [float] NOT NULL,
	[width] [float] NOT NULL,
	[height] [float] NOT NULL,
 CONSTRAINT [Parking_PK] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ParkingPlaces]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ParkingPlaces](--таблица парковочных мест
	[Id] [uniqueidentifier] NOT NULL,
	[ParkingId] [uniqueidentifier] NOT NULL,
	[X] [float] NOT NULL,
	[Y] [float] NOT NULL,
	[width] [float] NOT NULL,
	[height] [float] NOT NULL,
	[ParkingPlaceState] [bit] NULL,
	[ParkingPlacePath] [nvarchar](200) NOT NULL,
	[Angle] [float] NOT NULL,
	[number] [nvarchar](8) NOT NULL,
 CONSTRAINT [ParkingPlaces_PK] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PriceList]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PriceList](--таблица с ценами за минуту парковок
	[parkingId] [uniqueidentifier] NOT NULL,
	[price] [float] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](--таблица с пользователями
	[Id] [uniqueidentifier] NOT NULL,
	[userName] [nvarchar](20) NOT NULL,
	[Surname] [nvarchar](30) NOT NULL,
	[email] [nvarchar](max) NULL,
	[userPhone] [nvarchar](max) NULL,
	[password] [nvarchar](max) NOT NULL,
 CONSTRAINT [UsersPK] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[Books] ADD  DEFAULT (newid()) FOR [Id]
GO
ALTER TABLE [dbo].[Cars] ADD  DEFAULT (newid()) FOR [Id]
GO
ALTER TABLE [dbo].[Parking] ADD  DEFAULT (newid()) FOR [Id]
GO
ALTER TABLE [dbo].[ParkingPlaces] ADD  DEFAULT (newid()) FOR [Id]
GO
ALTER TABLE [dbo].[Users] ADD  DEFAULT (newid()) FOR [Id]
GO
ALTER TABLE [dbo].[Books]  WITH CHECK ADD  CONSTRAINT [BooksCars_FK] FOREIGN KEY([carId])
REFERENCES [dbo].[Cars] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Books] CHECK CONSTRAINT [BooksCars_FK]
GO
ALTER TABLE [dbo].[Books]  WITH CHECK ADD  CONSTRAINT [BooksPakingPlace_FK] FOREIGN KEY([parkingPlaceId])
REFERENCES [dbo].[ParkingPlaces] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Books] CHECK CONSTRAINT [BooksPakingPlace_FK]
GO
ALTER TABLE [dbo].[Cars]  WITH CHECK ADD  CONSTRAINT [Cars_FK] FOREIGN KEY([userId])
REFERENCES [dbo].[Users] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Cars] CHECK CONSTRAINT [Cars_FK]
GO
ALTER TABLE [dbo].[ParkingPlaces]  WITH CHECK ADD  CONSTRAINT [ParkingPlaces_FK] FOREIGN KEY([ParkingId])
REFERENCES [dbo].[Parking] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ParkingPlaces] CHECK CONSTRAINT [ParkingPlaces_FK]
GO
ALTER TABLE [dbo].[PriceList]  WITH CHECK ADD  CONSTRAINT [PriceList_FK] FOREIGN KEY([parkingId])
REFERENCES [dbo].[Parking] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PriceList] CHECK CONSTRAINT [PriceList_FK]
GO
/****** Object:  StoredProcedure [dbo].[userUpdate]    Script Date: 17.05.2020 18:56:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[userUpdate] @userId uniqueidentifier,@username nvarchar(20), @surname nvarchar(30),
	@userphone nvarchar(max), @email nvarchar(max) -- процедура обновления данных пользователя
as
begin
	update Users set userName = @username, surname=@surname, email=@email, userPhone=@userphone where Id = @userId
end
GO
USE [master]
GO
ALTER DATABASE [Parking] SET  READ_WRITE 
GO
