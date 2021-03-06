USE [master]
GO
/****** Object:  Database [u_ploszczy]    Script Date: 20.01.2021 21:27:50 ******/
CREATE DATABASE [u_ploszczy]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'u_ploszczy', FILENAME = N'/var/opt/mssql/data/u_ploszczy.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'u_ploszczy_log', FILENAME = N'/var/opt/mssql/data/u_ploszczy_log.ldf' , SIZE = 66048KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [u_ploszczy] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [u_ploszczy].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [u_ploszczy] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [u_ploszczy] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [u_ploszczy] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [u_ploszczy] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [u_ploszczy] SET ARITHABORT OFF 
GO
ALTER DATABASE [u_ploszczy] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [u_ploszczy] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [u_ploszczy] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [u_ploszczy] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [u_ploszczy] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [u_ploszczy] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [u_ploszczy] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [u_ploszczy] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [u_ploszczy] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [u_ploszczy] SET  ENABLE_BROKER 
GO
ALTER DATABASE [u_ploszczy] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [u_ploszczy] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [u_ploszczy] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [u_ploszczy] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [u_ploszczy] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [u_ploszczy] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [u_ploszczy] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [u_ploszczy] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [u_ploszczy] SET  MULTI_USER 
GO
ALTER DATABASE [u_ploszczy] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [u_ploszczy] SET DB_CHAINING OFF 
GO
ALTER DATABASE [u_ploszczy] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [u_ploszczy] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [u_ploszczy] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [u_ploszczy] SET QUERY_STORE = OFF
GO
USE [u_ploszczy]
GO
/****** Object:  UserDefinedFunction [dbo].[AverageDiscount]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[AverageDiscount]
(
	@startDate AS DATE,
	@endDate AS DATE,
	@restaurantID AS INT
)
RETURNS FLOAT
AS
BEGIN
	RETURN ISNULL((SELECT AVG(d.discount_value) FROM dbo.Discounts AS d
	INNER JOIN dbo.Discount_dictionary dd ON d.discount_type_ID = dd.Discount_type_ID
	WHERE @restaurantID = dd.Restaurant_ID AND @startDate <= d.start_date AND d.end_date <= @endDate),0)
END
GO
/****** Object:  UserDefinedFunction [dbo].[AverageMenuPositions]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[AverageMenuPositions]
(
	@startDate AS DATE,
	@endDate AS DATE,
	@restaurantID AS INT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @daysCount AS INT;
	DECLARE @sumOfCountMenu AS INT;
	DECLARE @dayIter AS DATE;
	SET @daysCount = DATEDIFF(DAY, @startDate, @endDate) + 1;
	SET @sumOfCountMenu = 0;
	SET @dayIter = @startDate;

	WHILE @dayIter <= @endDate
	BEGIN
		SET @sumOfCountMenu = @sumOfCountMenu + (SELECT COUNT(*) FROM dbo.Menu WHERE @restaurantID = restaurant_ID AND Add_date <= @dayIter AND @dayIter <= Remove_date);
		SET @dayIter = DATEADD(DAY, 1, @dayIter);
	END

	RETURN CAST(@sumOfCountMenu AS FLOAT)/@daysCount
END
GO
/****** Object:  UserDefinedFunction [dbo].[AverageOrderCost]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[AverageOrderCost]
(
	@startDate AS DATE,
	@endDate AS DATE,
	@restaurantID AS INT
)
RETURNS MONEY
AS
BEGIN
	RETURN ISNULL((SELECT AVG(dbo.SumOrder(o.order_ID)) FROM dbo.Orders AS o
	INNER JOIN dbo.Employees e ON e.employee_ID = o.employee_ID
	INNER JOIN dbo.Restaurants r ON r.restaurant_ID = e.restaurant_ID
	WHERE @startDate <= o.order_date AND o.order_date <= @endDate AND @restaurantID = e.restaurant_ID),0);
END
GO
/****** Object:  UserDefinedFunction [dbo].[AverageOrders]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[AverageOrders]
(
	@startDate AS DATE,
	@endDate AS DATE,
	@restaurantID AS INT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @differenceDate AS INT;
	SET @differenceDate =DATEDIFF(DAY, @startDate, @endDate)+1;

	RETURN CAST((SELECT COUNT(*) FROM dbo.Orders AS o
	INNER JOIN dbo.Employees e ON e.employee_ID = o.employee_ID
	INNER JOIN dbo.Restaurants r ON r.restaurant_ID = e.restaurant_ID
	WHERE @startDate <= o.order_date AND o.order_date <= @endDate AND @restaurantID = e.restaurant_ID) AS FLOAT )/@differenceDate
END
GO
/****** Object:  UserDefinedFunction [dbo].[AverageReservations]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[AverageReservations]
(
	@startDate AS DATE,
	@endDate AS DATE,
	@restaurantID AS INT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @days AS INT;
	SET @days = DATEDIFF(DAY, @startDate, @endDate) + 1

	RETURN (SELECT CAST(COUNT(*) AS FLOAT)/@days FROM dbo.Reservations AS r
	INNER JOIN dbo.Restrictions res ON res.restriction_ID = r.restriction_ID
	INNER JOIN dbo.Tables t ON t.table_ID = res.table_ID
	WHERE r.reservation_date <= @startDate AND r.reservation_date <= @endDate AND @restaurantID = t.restaurant_ID)

END
GO
/****** Object:  UserDefinedFunction [dbo].[CanIndyvidualMakeReservation]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CanIndyvidualMakeReservation]
(
	@clientID AS INT,
	@clientsOrderID AS INT
)
RETURNS BIT 
AS
BEGIN
	IF dbo.SumOrder(@clientsOrderID) >= 50 AND (
	SELECT COUNT(order_ID) FROM dbo.Orders
	WHERE dbo.SumOrder(order_ID) >= 200) >= 5 AND @clientID IN (SELECT client_ID FROM dbo.Indyvidual_clients)

	BEGIN
		RETURN 1;
	END

	RETURN 0;
END
GO
/****** Object:  UserDefinedFunction [dbo].[CanOrderSeafood]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CanOrderSeafood]
(
	@pickUpDate AS DATETIME,
	@orderDate AS DATE
)
RETURNS BIT
AS
BEGIN
	IF DATEPART(WEEKDAY, @pickUpDate) >= 5 AND DATEPART(WEEKDAY, @pickUpDate) <= 7 AND DATEDIFF(DAY, @orderDate, @pickUpDate) >= DATEPART(WEEKDAY, @pickUpDate) -2
	BEGIN
		RETURN 1;
	END

	RETURN 0;

END
GO
/****** Object:  UserDefinedFunction [dbo].[CheckIfCompanyShoudGetFirstTypeOfDiscount]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CheckIfCompanyShoudGetFirstTypeOfDiscount]
(
	@clientID AS INT,
	@countOfOrders AS INT,
	@allSumOfOrders AS FLOAT,
	@endDate AS DATE
)
RETURNS BIT
AS
BEGIN
	DECLARE @startDate AS DATE;

	SET @startDate = DATEADD(MONTH, -1, @endDate);

	IF (SELECT COUNT(*) FROM dbo.Orders WHERE @clientID = client_ID AND @startDate <= order_date AND order_date <= @endDate) >= @countOfOrders
	AND (SELECT SUM(dbo.SumOrder(order_ID)) FROM dbo.Orders WHERE @clientID = client_ID AND @startDate <= order_date AND order_date <= @endDate) >= @allSumOfOrders
	AND @clientID IN (SELECT client_ID FROM dbo.Companies)
	BEGIN
		RETURN 1;
	END

	RETURN 0;

	
END
GO
/****** Object:  UserDefinedFunction [dbo].[CheckIndyvidualDiscount]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CheckIndyvidualDiscount]
(
	@clientID AS INT,
	@countOfOrders AS INT,
	@valueOfOrder AS MONEY,
	@allOrderValue AS MONEY,
	@lastDiscountDate AS DATE
)
RETURNS BIT
AS
BEGIN
	IF @clientID NOT IN (SELECT client_ID FROM dbo.Indyvidual_clients)
	BEGIN
		RETURN 0;
	END
	IF (SELECT COUNT(*) FROM dbo.Orders WHERE @clientID = client_ID AND dbo.SumOrder(order_ID) > @valueOfOrder AND order_date > @lastDiscountDate) > @countOfOrders
	AND
	(SELECT SUM(dbo.SumOrder(order_ID)) FROM dbo.Orders WHERE @clientID = client_ID AND order_date > @lastDiscountDate) > @allOrderValue
	BEGIN
		RETURN 1;
	END

	RETURN 0;
END
GO
/****** Object:  UserDefinedFunction [dbo].[CountReservationInOneDay]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CountReservationInOneDay]
(
	@reservationDate AS DATE,
	@restaurantID AS INT
)
RETURNS INT
AS
BEGIN
	RETURN (SELECT COUNT(*) FROM dbo.Reservations AS r
	INNER JOIN dbo.Restrictions res ON res.restriction_ID = r.restriction_ID
	INNER JOIN dbo.Tables t ON t.table_ID = res.table_ID
	WHERE @reservationDate = r.reservation_date AND @restaurantID = t.restaurant_ID)
END
GO
/****** Object:  UserDefinedFunction [dbo].[DayWithMaxOrderCount]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[DayWithMaxOrderCount]
(
	@startDate AS DATE,
	@endDate AS DATE,
	@restaurantID AS INT
)
RETURNS DATE
AS
BEGIN
	DECLARE @iterDate AS DATE;
	DECLARE @maxCount AS INT
	DECLARE @maxDayCount AS DATE;
	DECLARE @tmpCount AS INT;

	SET @iterDate = @startDate;
	SET @maxCount = 0;
	SET @maxDayCount = @startDate;

	WHILE @iterDate <= @endDate
	BEGIN
		SET @tmpCount = dbo.AverageOrders(@iterDate, @iterDate, @restaurantID);

		IF @tmpCount > @maxCount
		BEGIN
		    SET @maxCount = @tmpCount;
			SET @maxDayCount = @iterDate;
		END

		SET @iterDate = DATEADD(DAY, 1, @iterDate);
	END

	RETURN @maxDayCount;
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetCompanyFirstDiscountValue]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetCompanyFirstDiscountValue]
(
	@clientID AS INT,
	@startDate AS DATE
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @endDate AS DATE;
	DECLARE @discountTypeID AS INT;
	DECLARE @valueOfLastDiscount AS FLOAT;
	DECLARE @maxDiscountTypeValue AS FLOAT;
	DECLARE @valueOfDiscount AS FLOAT;


	SET @endDate = DATEADD(MONTH, -1, @startDate);
	SET @discountTypeID = (SELECT Discount_type_ID FROM dbo.Discount_dictionary WHERE Max_Discount_Value IS NOT NULL AND One_Time_Discount = 0 AND Count_Of_Days IS NULL AND @startDate > From_date AND @startDate < To_date );
	SET @valueOfLastDiscount = (SELECT Discount_Value FROM dbo.Discounts WHERE Discount_type_ID = @discountTypeID AND @endDate = [start_date] AND @clientID = client_ID);
	SET @valueOfLastDiscount = ISNULL(@valueOfLastDiscount, 0);
	SET @maxDiscountTypeValue = (SELECT Max_Discount_Value FROM dbo.Discount_dictionary WHERE Discount_type_ID = @discountTypeID);
	SET @valueOfDiscount = (SELECT Discount_Value FROM dbo.Discount_dictionary WHERE Discount_type_ID = @discountTypeID);

	IF dbo.CheckIfCompanyShoudGetFirstTypeOfDiscount(@clientID, (SELECT Count_Of_Orders FROM dbo.Discount_dictionary WHERE Discount_type_ID = @discountTypeID), (SELECT Value_Orders FROM dbo.Discount_dictionary WHERE Discount_type_ID = @discountTypeID), @startDate) = 0
	BEGIN
		RETURN 0;
	END
	

	IF @maxDiscountTypeValue < @valueOfLastDiscount + @valueOfDiscount
	BEGIN
		RETURN @maxDiscountTypeValue;
	END

	RETURN @valueOfLastDiscount + @valueOfDiscount;

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetCompanySecondDiscountID]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetCompanySecondDiscountID]
(
	@clientID AS INT,
	@startDate AS DATE
)
RETURNS INT
AS
BEGIN
	DECLARE @endDate AS DATE;
	DECLARE @discountTypeID AS INT;
	DECLARE @orderCostFromDiscount AS FLOAT;

	SET @endDate = DATEADD(MONTH, -3, @startDate);
	SET @discountTypeID = (SELECT Discount_type_ID FROM dbo.Discount_dictionary WHERE Max_Discount_Value IS NOT NULL AND One_Time_Discount = 0 AND Count_Of_Days IS NULL AND Count_Of_Orders IS NULL AND @startDate > From_date AND @startDate < To_date );
	SET @orderCostFromDiscount = (SELECT Value_Orders FROM dbo.Discount_dictionary WHERE @discountTypeID = Discount_type_ID);

	IF (SELECT SUM(dbo.SumOrder(order_ID)) FROM dbo.Orders WHERE @clientID = client_ID AND @startDate <= order_date AND order_date <= @endDate) >= @orderCostFromDiscount
	BEGIN
		RETURN @discountTypeID;
	END

	RETURN -1;
	

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetFirstOrSecondDiscountValue]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetFirstOrSecondDiscountValue]
(
	@clientID AS INT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @countOfOrders AS INT;
	DECLARE @valueOfOrder AS MONEY;
	DECLARE @lastDiscountDate AS DATE;
	DECLARE @lastDiscountValue AS FLOAT;

	SET @countOfOrders = (SELECT Count_Of_Orders FROM dbo.Discount_dictionary WHERE From_date <= GETDATE() AND GETDATE() <= To_date AND Count_Of_Orders IS NOT NULL);
	SET @valueOfOrder = (SELECT Value_Orders FROM dbo.Discount_dictionary WHERE From_date <= GETDATE() AND GETDATE() <= To_date AND Count_Of_Orders IS NOT NULL);
	SET @lastDiscountDate = (SELECT MAX(start_date) FROM dbo.Discounts AS d
		INNER JOIN dbo.Discount_dictionary dd ON dd.Discount_type_ID = d.discount_type_ID
		WHERE @clientID = client_ID AND GETDATE() <= d.end_date AND dd.Count_Of_Orders = @countOfOrders AND dd.Value_Orders = @valueOfOrder);
	SET @lastDiscountValue = (SELECT d.discount_value FROM dbo.Discounts AS d
		INNER JOIN dbo.Discount_dictionary dd ON dd.Discount_type_ID = d.discount_type_ID
		WHERE @clientID = client_ID AND GETDATE() <= end_date AND start_date = @lastDiscountDate AND dd.Count_Of_Orders = @countOfOrders AND dd.Value_Orders = @valueOfOrder);

	IF @lastDiscountDate IS NULL AND dbo.CheckIndyvidualDiscount(@clientID, @countOfOrders, @valueOfOrder, -1, DATEADD(YEAR, -100, GETDATE())) = 1
	BEGIN
		RETURN (SELECT Discount_Value FROM dbo.Discount_dictionary WHERE From_date <= GETDATE() AND GETDATE() <= To_date AND Count_Of_Orders IS NOT NULL)
	END

	IF @lastDiscountDate IS NOT NULL AND dbo.CheckIndyvidualDiscount(@clientID, @countOfOrders, @valueOfOrder, -1, @lastDiscountDate) = 1
	BEGIN
		RETURN (SELECT Discount_Value FROM dbo.Discount_dictionary WHERE From_date <= GETDATE() AND GETDATE() <= To_date AND Count_Of_Orders IS NOT NULL) + @lastDiscountValue;
	END

	RETURN 0;
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetThirdAndFourthDiscountID]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetThirdAndFourthDiscountID]
(
	@clientID AS INT
)
RETURNS INT
AS
BEGIN
	DECLARE @discounTypeID AS INT;
	DECLARE @sumOfOrders AS INT;

	SET @sumOfOrders = (SELECT SUM(dbo.SumOrder(order_ID)) FROM dbo.Orders WHERE @clientID = client_ID);
	SET @discounTypeID = (SELECT MAX(Value_Orders) FROM dbo.Discount_dictionary WHERE Count_Of_Days IS NULL AND Value_Orders <= @sumOfOrders );

	IF @discounTypeID NOT IN (SELECT discount_type_ID FROM dbo.Discounts WHERE @clientID = client_ID)
	BEGIN
		RETURN @discounTypeID;
	END

	RETURN -1;

END
GO
/****** Object:  UserDefinedFunction [dbo].[SumOrder]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[SumOrder]
(
	@orderIndex int
)
RETURNS MONEY
AS
BEGIN
	RETURN(
		SELECT ROUND(SUM(od.Price*od.Quantity*(1-ISNULL(d.discount_value, 0))),2) FROM Order_details AS od
		INNER JOIN Orders o ON od.Order_ID = o.order_ID
		INNER JOIN dbo.Clients c ON c.client_ID = o.client_ID
		LEFT OUTER JOIN dbo.Discounts d ON d.discount_ID = o.discount_ID
		WHERE @orderIndex = od.Order_ID 
	)

END
GO
/****** Object:  Table [dbo].[Menu]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Menu](
	[Menu_ID] [int] NOT NULL,
	[Dish_ID] [int] NOT NULL,
	[Add_date] [date] NOT NULL,
	[Remove_date] [date] NOT NULL,
	[restaurant_ID] [int] NOT NULL,
 CONSTRAINT [PK_Menu] PRIMARY KEY CLUSTERED 
(
	[Menu_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Dishes]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dishes](
	[dish_ID] [int] NOT NULL,
	[category_ID] [int] NOT NULL,
	[dish_name] [varchar](30) NOT NULL,
	[price] [money] NOT NULL,
	[execution_time] [int] NOT NULL,
	[locked_date] [date] NULL,
	[unlocked_date] [date] NULL,
	[restaurant_ID] [int] NOT NULL,
 CONSTRAINT [PK_Dishes_1] PRIMARY KEY CLUSTERED 
(
	[dish_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[MenuToday]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[MenuToday]
(	
	@companyID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Dishes.dish_ID AS 'Numer dania', dish_name AS 'Nazwa dania' FROM Dishes
	INNER JOIN Menu
	ON Dishes.dish_ID = Menu.Dish_ID
	WHERE CAST(GETDATE() AS DATE) >= Add_date AND CAST(GETDATE() AS DATE) <= Remove_date
	AND Menu.restaurant_ID = @companyID
)
GO
/****** Object:  UserDefinedFunction [dbo].[DishesInMenuOverTwoWeeks]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[DishesInMenuOverTwoWeeks]
(	
	@restaurantID AS INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT m.Menu_ID FROM dbo.MenuToday(@restaurantID) AS mt
	INNER JOIN dbo.Menu m ON mt.[Numer dania] = m.Dish_ID
	WHERE DATEDIFF(DAY, m.Add_date, GETDATE()) > 14 AND m.Remove_date > GETDATE()
)
GO
/****** Object:  UserDefinedFunction [dbo].[Report]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[Report]
(	
	@restaurantID AS INT,
	@startDate AS DATE,
	@endDate AS DATE
)
RETURNS TABLE 
AS
RETURN(
	SELECT dbo.AverageDiscount(@startDate, @endDate, @restaurantID) AS 'Średni rabat',
	dbo.AverageOrderCost(@startDate, @endDate, @restaurantID) AS 'Średnia wartość zamówień',
	dbo.AverageOrders(@startDate, @endDate, @restaurantID) AS 'Średnia liczba zamówień na dzień',
	dbo.DayWithMaxOrderCount(@startDate, @endDate, @restaurantID) AS 'Dzień z największą liczbą zamówień',
	dbo.AverageReservations(@startDate, @endDate, @restaurantID) AS 'Średnia liczba rezerwacji',
	dbo.AverageMenuPositions(@startDate, @endDate, @restaurantID) AS 'Średnia liczba pozycji w menu'
)

GO
/****** Object:  UserDefinedFunction [dbo].[WeeklyReport]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[WeeklyReport]
(	
	@startDate AS DATE,
	@restaurantID AS INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT * FROM dbo.Report(@restaurantID, @startDate, DATEADD(DAY, 7, @startDate))
)
GO
/****** Object:  UserDefinedFunction [dbo].[MonthlyReport]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[MonthlyReport]
(	
	@startDate AS DATE,
	@restaurantID AS INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT * FROM dbo.Report(@restaurantID, @startDate, DATEADD(DAY, 30, @startDate))
)
GO
/****** Object:  Table [dbo].[Discounts]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Discounts](
	[discount_ID] [int] NOT NULL,
	[client_ID] [int] NOT NULL,
	[discount_value] [float] NOT NULL,
	[start_date] [date] NOT NULL,
	[end_date] [date] NOT NULL,
	[discount_type_ID] [int] NOT NULL,
 CONSTRAINT [PK_Discounts_1] PRIMARY KEY CLUSTERED 
(
	[discount_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Towns]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Towns](
	[town_ID] [int] NOT NULL,
	[town_name] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Towns_1] PRIMARY KEY CLUSTERED 
(
	[town_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Orders]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Orders](
	[order_ID] [int] NOT NULL,
	[client_ID] [int] NOT NULL,
	[employee_ID] [int] NOT NULL,
	[takeaway] [bit] NOT NULL,
	[order_date] [date] NOT NULL,
	[pickup_time] [datetime] NOT NULL,
	[discount_ID] [int] NULL,
 CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED 
(
	[order_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Order_details]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Order_details](
	[Order_ID] [int] NOT NULL,
	[Menu_ID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[Price] [money] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Clients]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Clients](
	[client_ID] [int] NOT NULL,
	[phone_number] [varchar](10) NULL,
	[e_mail] [varchar](50) NOT NULL,
	[restaurant_ID] [int] NOT NULL,
 CONSTRAINT [PK_Clients_1] PRIMARY KEY CLUSTERED 
(
	[client_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [EMAIL] UNIQUE NONCLUSTERED 
(
	[e_mail] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [phone] UNIQUE NONCLUSTERED 
(
	[phone_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Companies]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Companies](
	[client_ID] [int] NOT NULL,
	[company_name] [varchar](20) NOT NULL,
	[NIP] [varchar](10) NOT NULL,
	[address] [varchar](50) NOT NULL,
	[town_ID] [int] NOT NULL,
	[postal_code] [varchar](10) NOT NULL,
 CONSTRAINT [PK_Companies_1] PRIMARY KEY CLUSTERED 
(
	[client_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [Company_name] UNIQUE NONCLUSTERED 
(
	[company_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [NIP_companies] UNIQUE NONCLUSTERED 
(
	[NIP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Invoice]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[Invoice]
(	
	@clientID AS INT,
	@startDate AS DATE,
	@endDate AS DATE,
	@orderID AS INT
)
RETURNS TABLE
AS

RETURN 
(
	(SELECT
	CONCAT('Nazwa firmy: ', c.company_name, ' Adres firmy: ', c.address, ' ', t.town_name, ' ', c.postal_code ,' NIP: ', c.NIP, ' Data utworzenia faktury: ', GETDATE()) AS 'Name'
	FROM dbo.Companies AS c
	INNER JOIN dbo.Towns t ON t.town_ID = c.town_ID
	WHERE c.client_ID = @clientID)

	UNION ALL
	SELECT
	CONCAT('Numer zamówienia: ', o.order_ID, ' Data zamówienia: ',o.order_date, ' Nazwa zamówionej pozycji: ', d.dish_name, ' Ilość: ', od.Quantity, ' Cena detaliczna: ', od.Price, 'zł Rabat: ', ISNULL(disc.discount_value,0)*100, '% Suma: ', od.Price*od.Quantity*(1-ISNULL(disc.discount_value,0)))
	FROM dbo.Orders AS o 
	INNER JOIN dbo.Order_details od  ON od.Order_ID = o.order_ID
	INNER JOIN dbo.Menu m ON m.Menu_ID = od.Menu_ID
	INNER JOIN dbo.Dishes d ON d.dish_ID = m.Dish_ID
	INNER JOIN dbo.Clients c ON c.client_ID = o.client_ID
	LEFT OUTER JOIN dbo.Discounts disc ON disc.discount_ID = o.discount_ID
	WHERE @startDate <= o.order_date AND o.order_date <= @endDate AND @clientID = o.client_ID AND ISNULL(@orderID, o.order_ID) = o.order_ID

	UNION ALL
	SELECT
	CONCAT('Sumaryczna kwota: ', SUM(dbo.SumOrder(o.order_ID)), 'zł')
	FROM dbo.Orders AS o 
	WHERE @startDate <= o.order_date AND o.order_date <= @endDate AND @clientID = o.client_ID
)

GO
/****** Object:  UserDefinedFunction [dbo].[OrderInvoice]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[OrderInvoice]
(	
	@orderID AS INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT * FROM dbo.Invoice((SELECT client_ID FROM Orders WHERE @orderID = order_ID), (SELECT order_date FROM Orders WHERE @orderID = order_ID), (SELECT order_date FROM Orders WHERE @orderID = order_ID), @orderID)
)
GO
/****** Object:  UserDefinedFunction [dbo].[MonthInvoice]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[MonthInvoice]
(	
	@clientID AS INT,
	@endDate AS DATE
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT * FROM dbo.Invoice(@clientID, DATEADD(DAY, -30, @endDate) , @endDate, NULL)
)
GO
/****** Object:  Table [dbo].[Towns_connections]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Towns_connections](
	[town_ID] [int] NOT NULL,
	[country_ID] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Countries]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Countries](
	[country_ID] [int] NOT NULL,
	[country_name] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Countries_1] PRIMARY KEY CLUSTERED 
(
	[country_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [Country_name] UNIQUE NONCLUSTERED 
(
	[country_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Restaurants]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Restaurants](
	[restaurant_ID] [int] NOT NULL,
	[restaurant_name] [varchar](20) NOT NULL,
	[town_ID] [int] NOT NULL,
	[adress] [varchar](30) NOT NULL,
	[NIP] [varchar](10) NOT NULL,
	[phone_number] [varchar](15) NOT NULL,
	[e_mail] [varchar](20) NOT NULL,
 CONSTRAINT [PK_Restaurants] PRIMARY KEY CLUSTERED 
(
	[restaurant_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Restaurants_email] UNIQUE NONCLUSTERED 
(
	[e_mail] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Restaurants_name] UNIQUE NONCLUSTERED 
(
	[restaurant_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Restaurants_NIP] UNIQUE NONCLUSTERED 
(
	[NIP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Restaurants_phone] UNIQUE NONCLUSTERED 
(
	[phone_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[RestaurantsInformations]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[RestaurantsInformations]
AS
SELECT        r.restaurant_name, r.adress + ',' + t.town_name + ',' + c.country_name AS Adress, r.phone_number
FROM            dbo.Restaurants AS r INNER JOIN
                         dbo.Towns AS t ON t.town_ID = r.town_ID INNER JOIN
                         dbo.Towns_connections AS tc ON tc.town_ID = t.town_ID INNER JOIN
                         dbo.Countries AS c ON c.country_ID = tc.country_ID
GO
/****** Object:  View [dbo].[TownsAndCountriesNames]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[TownsAndCountriesNames]
AS
SELECT        TOP (100) PERCENT dbo.Countries.country_name, dbo.Towns.town_name
FROM            dbo.Towns INNER JOIN
                         dbo.Towns_connections ON dbo.Towns.town_ID = dbo.Towns_connections.town_ID INNER JOIN
                         dbo.Countries ON dbo.Towns_connections.country_ID = dbo.Countries.country_ID
ORDER BY dbo.Countries.country_name, dbo.Towns.town_name
GO
/****** Object:  Table [dbo].[Categories]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Categories](
	[category_ID] [int] NOT NULL,
	[category_name] [varchar](15) NOT NULL,
	[category_description] [varchar](40) NULL,
 CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED 
(
	[category_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [U_Categories] UNIQUE NONCLUSTERED 
(
	[category_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[CategoriesInformations]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CategoriesInformations]
AS
SELECT        category_name, category_description
FROM            dbo.Categories
GO
/****** Object:  Table [dbo].[Company_Members]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Company_Members](
	[Company_ID] [int] NOT NULL,
	[Indyvidual_Client_ID] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Indyvidual_clients]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Indyvidual_clients](
	[client_ID] [int] NOT NULL,
	[first_name] [varchar](30) NOT NULL,
	[last_name] [varchar](30) NOT NULL,
 CONSTRAINT [PK_Indyvidual_clients_1] PRIMARY KEY CLUSTERED 
(
	[client_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[CustomersBelongToCompany]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CustomersBelongToCompany]
(	
	@companyID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT ic.client_ID, ic.first_name, ic.last_name FROM Company_Members AS cm
	INNER JOIN Indyvidual_clients ic ON cm.Indyvidual_Client_ID = ic.client_ID
	WHERE cm.Company_ID = @companyID
)
GO
/****** Object:  UserDefinedFunction [dbo].[GetClientOrderHistory]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetClientOrderHistory]
(	
	@clientID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT o.order_ID, o.order_date, o.pickup_time, d.dish_name, od.price, od.Quantity, disc.discount_value FROM Orders AS o
	INNER JOIN Order_details od ON o.order_ID = od.Order_ID
	INNER JOIN Menu m ON m.Menu_ID = od.Menu_ID
	INNER JOIN Dishes d ON d.dish_ID = m.Dish_ID
	INNER JOIN dbo.Clients c ON c.client_ID = o.client_ID
	LEFT OUTER JOIN dbo.Discounts disc ON disc.discount_ID = o.discount_ID
	WHERE o.client_ID = @clientID
)
GO
/****** Object:  Table [dbo].[Dish_Details]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dish_Details](
	[dish_ID] [int] NOT NULL,
	[ingredient_ID] [int] NOT NULL,
	[Quantity] [float] NOT NULL,
	[Price] [money] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[MissingIngredientsForOrder]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[MissingIngredientsForOrder]
(	
	@orderID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT i.ingredient_ID as 'ID Składnika', i.ingredient_name as 'Nazwa', (dd.Quantity*od.Quantity) -  i.ingredient_in_stock as 'Brakująca ilość' FROM Order_details AS od
	INNER JOIN Menu m ON od.Menu_ID = m.Menu_ID
	INNER JOIN Dishes d ON d.dish_ID = m.Dish_ID
	INNER JOIN Dish_Details dd ON d.dish_ID = dd.dish_ID
	INNER JOIN Igredients i ON dd.ingredient_ID = i.ingredient_ID
	WHERE od.Order_ID = @orderID AND i.ingredient_in_stock - (dd.Quantity*od.Quantity) < 0
)
GO
/****** Object:  Table [dbo].[Ingredients]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Ingredients](
	[ingredient_ID] [int] NOT NULL,
	[supplier_ID] [int] NOT NULL,
	[ingredient_name] [varchar](20) NOT NULL,
	[ingredient_in_stock] [int] NOT NULL,
	[ingredient_price] [money] NOT NULL,
	[ingredient_quantity] [varchar](20) NOT NULL,
	[safe_amout] [int] NOT NULL,
	[extra_informations] [varchar](50) NULL,
	[locked_date] [date] NULL,
	[unlocked_date] [date] NULL,
	[restaurant_ID] [int] NOT NULL,
 CONSTRAINT [PK_Igredients_1] PRIMARY KEY CLUSTERED 
(
	[ingredient_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Igredients_name] UNIQUE NONCLUSTERED 
(
	[ingredient_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[DishIngredients]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[DishIngredients]
(	
	@dishID int,
	@restaurantID int = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT DISTINCT i.ingredient_ID, i.ingredient_name, dd.Quantity as 'Ilość do dania', i.ingredient_quantity, i.extra_informations
	FROM Dish_Details AS dd
	INNER JOIN Ingredients i ON dd.ingredient_ID = i.ingredient_ID
	WHERE dd.dish_ID = @dishID AND ISNULL(@restaurantID, i.restaurant_ID) = i.restaurant_ID
)
GO
/****** Object:  Table [dbo].[Positions]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Positions](
	[position_ID] [int] NOT NULL,
	[position_name] [varchar](20) NOT NULL,
 CONSTRAINT [PK_Positions] PRIMARY KEY CLUSTERED 
(
	[position_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Employees]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Employees](
	[employee_ID] [int] NOT NULL,
	[position_ID] [int] NOT NULL,
	[first_name] [varchar](40) NOT NULL,
	[last_name] [varchar](40) NOT NULL,
	[part_time] [varchar](15) NOT NULL,
	[rate_per_hour] [money] NOT NULL,
	[phone_number] [varchar](12) NOT NULL,
	[email] [varchar](50) NULL,
	[hire_date] [date] NOT NULL,
	[photo_path] [varchar](50) NULL,
	[job_quit_date] [date] NULL,
	[restaurant_ID] [int] NOT NULL,
 CONSTRAINT [PK_Employee_1] PRIMARY KEY CLUSTERED 
(
	[employee_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Employees] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Employees_1] UNIQUE NONCLUSTERED 
(
	[phone_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[CurrentEmployees]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[CurrentEmployees]
(	
	@restaurantID int = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT e.employee_ID, e.first_name, e.last_name, p.position_name, e.part_time, e.rate_per_hour, e.restaurant_ID, e.phone_number, e.email,
	e.hire_date
	FROM Employees AS e
	INNER JOIN Positions p ON p.position_ID = e.position_ID
	WHERE ISNULL(@restaurantID, restaurant_ID) = restaurant_ID AND e.hire_date <= GETDATE() AND e.job_quit_date IS NULL
)
GO
/****** Object:  UserDefinedFunction [dbo].[CurrentOrdersToMake]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[CurrentOrdersToMake]
(	
	@companyID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT order_ID AS 'Numer zamowienia',pickup_time AS 'Godzina zamowienia',Orders.client_ID AS 'Numer klienta', IIF(Orders.client_ID IN (SELECT client_ID FROM Indyvidual_clients),'Indyvidual Client','Company') AS 'Typ klienta'
	FROM Orders
	INNER JOIN Clients
	ON Orders.client_ID = Clients.client_ID
	WHERE order_date = GETDATE() AND restaurant_ID = @companyID
	AND DATEDIFF(minute,GETDATE(),pickup_time) > 0
)
GO
/****** Object:  UserDefinedFunction [dbo].[SpecificDayOrders]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[SpecificDayOrders]
(	
	@companyID int,
	@specificDay date
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT order_ID AS 'Numer zamowienia', CAST(pickup_time AS TIME(0)) AS 'Godzina zamowienia',Orders.client_ID AS 'Numer klienta', IIF(Orders.client_ID IN (SELECT client_ID FROM Indyvidual_clients),'Klient indywidualny','Firma') AS 'Typ klienta'
	FROM Orders
	INNER JOIN Clients
	ON Orders.client_ID = Clients.client_ID
	WHERE CAST(pickup_time AS DATE) = @specificDay AND restaurant_ID = @companyID
)
GO
/****** Object:  Table [dbo].[Discount_dictionary]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Discount_dictionary](
	[Discount_type_ID] [int] NOT NULL,
	[Count_Of_Orders] [int] NULL,
	[Value_Orders] [money] NOT NULL,
	[Count_Of_Days] [int] NULL,
	[Discount_Value] [float] NOT NULL,
	[Max_Discount_Value] [float] NULL,
	[Discount_description] [varchar](50) NOT NULL,
	[One_Time_Discount] [bit] NOT NULL,
	[From_date] [date] NOT NULL,
	[To_date] [date] NOT NULL,
	[Restaurant_ID] [int] NOT NULL,
 CONSTRAINT [PK_Discount_dictionary] PRIMARY KEY CLUSTERED 
(
	[Discount_type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[ClientsDiscount]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ClientsDiscount]
(	
	@client_ID int,
	@restaurant_ID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT discount_ID AS 'Numer rabatu', Discounts.discount_value AS 'Wartosc rabatu',
	[start_date] AS 'Od kiedy', end_date AS 'Do kiedy' FROM Discounts
	INNER JOIN Discount_dictionary
	ON Discounts.discount_type_ID = Discount_dictionary.Discount_type_ID
	WHERE Restaurant_ID = @restaurant_ID AND client_ID = @client_ID
	AND DATEDIFF(DAY,[start_date],GETDATE()) >= 0 AND DATEDIFF(DAY,GETDATE(),end_date) >= 0
)
GO
/****** Object:  Table [dbo].[Orders_Unpaid]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Orders_Unpaid](
	[order_ID] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[UnpaidOrders]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[UnpaidOrders]
(	
	@restaurantID AS INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Orders_Unpaid.order_ID,Orders.client_ID,
	IIF(Orders.client_ID IN (SELECT client_ID FROM Indyvidual_clients),'Klient Indywidualny','Firma') AS 'Typ klienta',
	IIF(Orders.client_ID IN (SELECT client_ID FROM Indyvidual_clients),(SELECT first_name + ' ' + last_name FROM Indyvidual_clients WHERE Orders.client_ID = Indyvidual_clients.client_ID), (SELECT company_name FROM Companies WHERE Orders.client_ID = Companies.client_ID)) AS 'Klient' FROM Orders_Unpaid
	INNER JOIN ORDERS
	ON Orders_Unpaid.order_ID = Orders.order_ID
	INNER JOIN Clients
	ON Clients.client_ID = Orders.client_ID
	WHERE @restaurantID = restaurant_ID
)
GO
/****** Object:  UserDefinedFunction [dbo].[AllClients]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[AllClients]
(	
	@restaurant_ID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Clients.client_ID AS 'Numer klienta',
	IIF(Clients.client_ID IN (SELECT client_ID FROM Indyvidual_clients),'Klient Indywidualny','Firma') AS 'Typ klienta',
	IIF(Clients.client_ID IN (SELECT client_ID FROM Indyvidual_clients),(SELECT first_name + ' ' + last_name FROM Indyvidual_clients WHERE Clients.client_ID = Indyvidual_clients.client_ID), (SELECT company_name FROM Companies WHERE Clients.client_ID = Companies.client_ID)) AS 'Klient' FROM Clients
	WHERE restaurant_ID = @restaurant_ID
)
GO
/****** Object:  UserDefinedFunction [dbo].[AllUnlockedDishes]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[AllUnlockedDishes]
(	
	@restaurant_ID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT dish_ID, dish_name FROM Dishes
	WHERE (DATEDIFF(DAY,GETDATE(), locked_date) > 0 OR DATEDIFF(DAY,unlocked_date, GETDATE()) >= 0)
	AND restaurant_ID = @restaurant_ID
)
GO
/****** Object:  UserDefinedFunction [dbo].[DishesThatCanBeAddedToMenu]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[DishesThatCanBeAddedToMenu]
(	
	@restaurant_ID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Menu.dish_ID AS 'Numer dania', dish_name AS 'Nazwa dania', MAX(Remove_date) AS 'Ostatnia data usuniecia z menu'
	FROM Menu
	INNER JOIN Dishes
	ON Menu.Dish_ID = Dishes.dish_ID
	WHERE Menu.restaurant_ID = @restaurant_ID AND (GETDATE() < locked_date OR GETDATE() >= unlocked_date) 
	GROUP BY Menu.Dish_ID, dish_name
	HAVING DATEDIFF(DAY,MAX(Remove_date),GETDATE()) > 30
)
GO
/****** Object:  Table [dbo].[Reservations]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Reservations](
	[reservation_ID] [int] NOT NULL,
	[client_ID] [int] NOT NULL,
	[reservation_date] [date] NOT NULL,
	[reservation_time] [time](7) NOT NULL,
	[restriction_ID] [int] NOT NULL,
 CONSTRAINT [PK_Reservation] PRIMARY KEY CLUSTERED 
(
	[reservation_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Restrictions]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Restrictions](
	[restriction_ID] [int] NOT NULL,
	[table_ID] [int] NOT NULL,
	[start_date] [date] NOT NULL,
	[end_date] [date] NOT NULL,
	[limit_chairs] [int] NOT NULL,
 CONSTRAINT [PK_Restrictions] PRIMARY KEY CLUSTERED 
(
	[restriction_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[TodaysReservations]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[TodaysReservations]
(	
	@restaurant_ID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT reservation_ID AS 'Numer rezerwacji', Reservations.client_ID AS 'Numer klienta',
	IIF( Reservations.client_ID IN (SELECT client_ID FROM Indyvidual_clients),'Klient Indywidualny','Firma') AS 'Typ klienta',
	IIF( Reservations.client_ID IN (SELECT client_ID FROM Indyvidual_clients),(SELECT first_name + ' ' + last_name FROM Indyvidual_clients WHERE Clients.client_ID = Indyvidual_clients.client_ID), (SELECT company_name FROM Companies WHERE Clients.client_ID = Companies.client_ID)) AS 'Klient',
	table_ID AS 'Numer stolika', limit_chairs AS 'Liczba miejsc', reservation_time AS 'Godzina rezerwacji' 
	FROM Reservations
	INNER JOIN Restrictions
	ON Restrictions.restriction_ID = Reservations.restriction_ID
	INNER JOIN Clients
	ON Clients.client_ID = Reservations.client_ID
	WHERE Clients.restaurant_ID = @restaurant_ID AND CAST(GETDATE() AS DATE) = reservation_date
)
GO
/****** Object:  UserDefinedFunction [dbo].[OrdersDetails]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[OrdersDetails] 
(	
	@OrderID int 
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT dish_name AS 'Nazwa dania',
	quantity AS 'Liczebnosc',
	Order_Details.Price AS 'Cena' FROM Order_details
	INNER JOIN Menu
	ON Menu.Menu_ID = Order_details.Menu_ID
	INNER JOIN Dishes
	ON Dishes.dish_ID = Menu.Dish_ID
	WHERE Order_ID = @OrderID

)
GO
/****** Object:  Table [dbo].[Tables]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tables](
	[table_ID] [int] NOT NULL,
	[chairs_ammount] [int] NOT NULL,
	[restaurant_ID] [int] NOT NULL,
 CONSTRAINT [PK_Tables] PRIMARY KEY CLUSTERED 
(
	[table_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[SpecificDaysFreeTables]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[SpecificDaysFreeTables]
(	
	@restaurant_ID int,
	@date date,
	@time time
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Restrictions.table_ID as 'Numer stolika', limit_chairs AS 'Liczba miejsc'
	FROM restrictions
	INNER JOIN [Tables] 
	ON [Tables].table_ID = Restrictions.table_ID
	WHERE restriction_ID not in 
	(SELECT restriction_ID FROM Reservations 
	WHERE reservation_date = @date AND (DATEDIFF(MINUTE, reservation_time,@time) BETWEEN -180 AND 180))
	AND (DATEDIFF(DAY,[start_date],@date) >= 0 AND DATEDIFF(DAY,@date,end_date) >= 0)
	AND restaurant_ID = @restaurant_ID
)
GO
/****** Object:  UserDefinedFunction [dbo].[CurrentRestaurantDiscountTypes]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[CurrentRestaurantDiscountTypes]
(	
	@restaurantID int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT * FROM dbo.Discount_dictionary
	WHERE Restaurant_ID = @restaurantID AND From_date <= GETDATE() AND GETDATE() <= To_date
)
GO
/****** Object:  Table [dbo].[Company_Name_Reservation]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Company_Name_Reservation](
	[reservation_ID] [int] NOT NULL,
	[client_ID] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Company_Reservations]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Company_Reservations](
	[resevervation_ID] [int] NOT NULL,
 CONSTRAINT [PK_Company_Reservations] PRIMARY KEY CLUSTERED 
(
	[resevervation_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Personal_Reservations]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Personal_Reservations](
	[reservation_ID] [int] NOT NULL,
	[order_ID] [int] NOT NULL,
 CONSTRAINT [PK_Personal_Reservation] PRIMARY KEY CLUSTERED 
(
	[reservation_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Suppliers]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Suppliers](
	[supplier_ID] [int] NOT NULL,
	[town_ID] [int] NOT NULL,
	[NIP_number] [varchar](10) NOT NULL,
	[supplier_name] [varchar](30) NOT NULL,
	[supplier_phone] [varchar](12) NOT NULL,
	[supplier_email] [varchar](20) NULL,
	[street] [varchar](20) NOT NULL,
	[postal_code] [varchar](10) NOT NULL,
	[bank_account] [varchar](26) NULL,
 CONSTRAINT [PK_Suppliers] PRIMARY KEY CLUSTERED 
(
	[supplier_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Suppliers_bank_account] UNIQUE NONCLUSTERED 
(
	[bank_account] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Suppliers_nip] UNIQUE NONCLUSTERED 
(
	[NIP_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Suppliers_phone_number] UNIQUE NONCLUSTERED 
(
	[supplier_phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Suppliers_supplier_email] UNIQUE NONCLUSTERED 
(
	[supplier_email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_Suppliers_supplier_name] UNIQUE NONCLUSTERED 
(
	[supplier_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Discount_dictionary] ADD  CONSTRAINT [DF_Discount_dictionary_From_date]  DEFAULT (CONVERT([date],getdate())) FOR [From_date]
GO
ALTER TABLE [dbo].[Discounts] ADD  CONSTRAINT [DF_Discounts_start_date]  DEFAULT (CONVERT([date],getdate())) FOR [start_date]
GO
ALTER TABLE [dbo].[Dishes] ADD  CONSTRAINT [DF_Dishes_locked_date]  DEFAULT (CONVERT([date],getdate())) FOR [locked_date]
GO
ALTER TABLE [dbo].[Employees] ADD  CONSTRAINT [DF_Employees_hire_date]  DEFAULT (CONVERT([date],getdate())) FOR [hire_date]
GO
ALTER TABLE [dbo].[Ingredients] ADD  CONSTRAINT [DF_Igredients_locked_date]  DEFAULT (CONVERT([date],getdate())) FOR [locked_date]
GO
ALTER TABLE [dbo].[Menu] ADD  CONSTRAINT [DF_Menu_Add_date]  DEFAULT (CONVERT([date],getdate())) FOR [Add_date]
GO
ALTER TABLE [dbo].[Menu] ADD  CONSTRAINT [DF_Menu_Remove_date]  DEFAULT (CONVERT([date],dateadd(day,(14),getdate()))) FOR [Remove_date]
GO
ALTER TABLE [dbo].[Orders] ADD  CONSTRAINT [DF_Orders_order_date]  DEFAULT (CONVERT([date],getdate())) FOR [order_date]
GO
ALTER TABLE [dbo].[Orders] ADD  CONSTRAINT [DF_Orders_pickup_time]  DEFAULT (CONVERT([time],getdate())) FOR [pickup_time]
GO
ALTER TABLE [dbo].[Restrictions] ADD  CONSTRAINT [DF_Restrictions_start_date]  DEFAULT (CONVERT([date],getdate())) FOR [start_date]
GO
ALTER TABLE [dbo].[Clients]  WITH CHECK ADD  CONSTRAINT [FK_Clients_Restaurants] FOREIGN KEY([restaurant_ID])
REFERENCES [dbo].[Restaurants] ([restaurant_ID])
GO
ALTER TABLE [dbo].[Clients] CHECK CONSTRAINT [FK_Clients_Restaurants]
GO
ALTER TABLE [dbo].[Companies]  WITH CHECK ADD  CONSTRAINT [FK_Companies_Clients] FOREIGN KEY([client_ID])
REFERENCES [dbo].[Clients] ([client_ID])
GO
ALTER TABLE [dbo].[Companies] CHECK CONSTRAINT [FK_Companies_Clients]
GO
ALTER TABLE [dbo].[Companies]  WITH CHECK ADD  CONSTRAINT [FK_Companies_Towns] FOREIGN KEY([town_ID])
REFERENCES [dbo].[Towns] ([town_ID])
GO
ALTER TABLE [dbo].[Companies] CHECK CONSTRAINT [FK_Companies_Towns]
GO
ALTER TABLE [dbo].[Company_Members]  WITH CHECK ADD  CONSTRAINT [FK_Company_Members_Companies] FOREIGN KEY([Company_ID])
REFERENCES [dbo].[Companies] ([client_ID])
GO
ALTER TABLE [dbo].[Company_Members] CHECK CONSTRAINT [FK_Company_Members_Companies]
GO
ALTER TABLE [dbo].[Company_Members]  WITH CHECK ADD  CONSTRAINT [FK_Company_Members_Indyvidual_clients] FOREIGN KEY([Indyvidual_Client_ID])
REFERENCES [dbo].[Indyvidual_clients] ([client_ID])
GO
ALTER TABLE [dbo].[Company_Members] CHECK CONSTRAINT [FK_Company_Members_Indyvidual_clients]
GO
ALTER TABLE [dbo].[Company_Name_Reservation]  WITH CHECK ADD  CONSTRAINT [FK_Company_Name_Reservation_Company_Reservations] FOREIGN KEY([reservation_ID])
REFERENCES [dbo].[Company_Reservations] ([resevervation_ID])
GO
ALTER TABLE [dbo].[Company_Name_Reservation] CHECK CONSTRAINT [FK_Company_Name_Reservation_Company_Reservations]
GO
ALTER TABLE [dbo].[Company_Name_Reservation]  WITH CHECK ADD  CONSTRAINT [FK_Company_Name_Reservation_Indyvidual_clients] FOREIGN KEY([client_ID])
REFERENCES [dbo].[Indyvidual_clients] ([client_ID])
GO
ALTER TABLE [dbo].[Company_Name_Reservation] CHECK CONSTRAINT [FK_Company_Name_Reservation_Indyvidual_clients]
GO
ALTER TABLE [dbo].[Company_Reservations]  WITH CHECK ADD  CONSTRAINT [FK_Company_Reservations_Reservations] FOREIGN KEY([resevervation_ID])
REFERENCES [dbo].[Reservations] ([reservation_ID])
GO
ALTER TABLE [dbo].[Company_Reservations] CHECK CONSTRAINT [FK_Company_Reservations_Reservations]
GO
ALTER TABLE [dbo].[Discount_dictionary]  WITH CHECK ADD  CONSTRAINT [FK_Discount_dictionary_Restaurants] FOREIGN KEY([Restaurant_ID])
REFERENCES [dbo].[Restaurants] ([restaurant_ID])
GO
ALTER TABLE [dbo].[Discount_dictionary] CHECK CONSTRAINT [FK_Discount_dictionary_Restaurants]
GO
ALTER TABLE [dbo].[Discounts]  WITH CHECK ADD  CONSTRAINT [FK_Discounts_Clients] FOREIGN KEY([client_ID])
REFERENCES [dbo].[Clients] ([client_ID])
GO
ALTER TABLE [dbo].[Discounts] CHECK CONSTRAINT [FK_Discounts_Clients]
GO
ALTER TABLE [dbo].[Discounts]  WITH CHECK ADD  CONSTRAINT [FK_Discounts_Discount_dictionary] FOREIGN KEY([discount_type_ID])
REFERENCES [dbo].[Discount_dictionary] ([Discount_type_ID])
GO
ALTER TABLE [dbo].[Discounts] CHECK CONSTRAINT [FK_Discounts_Discount_dictionary]
GO
ALTER TABLE [dbo].[Dish_Details]  WITH CHECK ADD  CONSTRAINT [FK_Dish_Details_Dishes] FOREIGN KEY([dish_ID])
REFERENCES [dbo].[Dishes] ([dish_ID])
GO
ALTER TABLE [dbo].[Dish_Details] CHECK CONSTRAINT [FK_Dish_Details_Dishes]
GO
ALTER TABLE [dbo].[Dish_Details]  WITH CHECK ADD  CONSTRAINT [FK_Dish_Details_Igredients] FOREIGN KEY([ingredient_ID])
REFERENCES [dbo].[Ingredients] ([ingredient_ID])
GO
ALTER TABLE [dbo].[Dish_Details] CHECK CONSTRAINT [FK_Dish_Details_Igredients]
GO
ALTER TABLE [dbo].[Dishes]  WITH CHECK ADD  CONSTRAINT [FK_Dishes_Categories] FOREIGN KEY([category_ID])
REFERENCES [dbo].[Categories] ([category_ID])
GO
ALTER TABLE [dbo].[Dishes] CHECK CONSTRAINT [FK_Dishes_Categories]
GO
ALTER TABLE [dbo].[Dishes]  WITH CHECK ADD  CONSTRAINT [FK_Dishes_Restaurants] FOREIGN KEY([restaurant_ID])
REFERENCES [dbo].[Restaurants] ([restaurant_ID])
GO
ALTER TABLE [dbo].[Dishes] CHECK CONSTRAINT [FK_Dishes_Restaurants]
GO
ALTER TABLE [dbo].[Employees]  WITH CHECK ADD  CONSTRAINT [FK_Employee_Positions] FOREIGN KEY([position_ID])
REFERENCES [dbo].[Positions] ([position_ID])
GO
ALTER TABLE [dbo].[Employees] CHECK CONSTRAINT [FK_Employee_Positions]
GO
ALTER TABLE [dbo].[Employees]  WITH CHECK ADD  CONSTRAINT [FK_Employees_Restaurants] FOREIGN KEY([restaurant_ID])
REFERENCES [dbo].[Restaurants] ([restaurant_ID])
GO
ALTER TABLE [dbo].[Employees] CHECK CONSTRAINT [FK_Employees_Restaurants]
GO
ALTER TABLE [dbo].[Indyvidual_clients]  WITH CHECK ADD  CONSTRAINT [FK_Indyvidual_clients_Clients] FOREIGN KEY([client_ID])
REFERENCES [dbo].[Clients] ([client_ID])
GO
ALTER TABLE [dbo].[Indyvidual_clients] CHECK CONSTRAINT [FK_Indyvidual_clients_Clients]
GO
ALTER TABLE [dbo].[Ingredients]  WITH CHECK ADD  CONSTRAINT [FK_Igredients_Restaurants] FOREIGN KEY([restaurant_ID])
REFERENCES [dbo].[Restaurants] ([restaurant_ID])
GO
ALTER TABLE [dbo].[Ingredients] CHECK CONSTRAINT [FK_Igredients_Restaurants]
GO
ALTER TABLE [dbo].[Ingredients]  WITH CHECK ADD  CONSTRAINT [FK_Igredients_Suppliers] FOREIGN KEY([supplier_ID])
REFERENCES [dbo].[Suppliers] ([supplier_ID])
GO
ALTER TABLE [dbo].[Ingredients] CHECK CONSTRAINT [FK_Igredients_Suppliers]
GO
ALTER TABLE [dbo].[Menu]  WITH CHECK ADD  CONSTRAINT [FK_Menu_Dishes] FOREIGN KEY([Dish_ID])
REFERENCES [dbo].[Dishes] ([dish_ID])
GO
ALTER TABLE [dbo].[Menu] CHECK CONSTRAINT [FK_Menu_Dishes]
GO
ALTER TABLE [dbo].[Menu]  WITH CHECK ADD  CONSTRAINT [FK_Menu_Restaurants] FOREIGN KEY([restaurant_ID])
REFERENCES [dbo].[Restaurants] ([restaurant_ID])
GO
ALTER TABLE [dbo].[Menu] CHECK CONSTRAINT [FK_Menu_Restaurants]
GO
ALTER TABLE [dbo].[Order_details]  WITH CHECK ADD  CONSTRAINT [FK_Order_details_Menu] FOREIGN KEY([Menu_ID])
REFERENCES [dbo].[Menu] ([Menu_ID])
GO
ALTER TABLE [dbo].[Order_details] CHECK CONSTRAINT [FK_Order_details_Menu]
GO
ALTER TABLE [dbo].[Order_details]  WITH CHECK ADD  CONSTRAINT [FK_Order_details_Orders] FOREIGN KEY([Order_ID])
REFERENCES [dbo].[Orders] ([order_ID])
GO
ALTER TABLE [dbo].[Order_details] CHECK CONSTRAINT [FK_Order_details_Orders]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Clients] FOREIGN KEY([client_ID])
REFERENCES [dbo].[Clients] ([client_ID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Clients]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Employee] FOREIGN KEY([employee_ID])
REFERENCES [dbo].[Employees] ([employee_ID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Employee]
GO
ALTER TABLE [dbo].[Orders_Unpaid]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Unpaid_Orders] FOREIGN KEY([order_ID])
REFERENCES [dbo].[Orders] ([order_ID])
GO
ALTER TABLE [dbo].[Orders_Unpaid] CHECK CONSTRAINT [FK_Orders_Unpaid_Orders]
GO
ALTER TABLE [dbo].[Personal_Reservations]  WITH CHECK ADD  CONSTRAINT [FK_Personal_Reservation_Orders] FOREIGN KEY([order_ID])
REFERENCES [dbo].[Orders] ([order_ID])
GO
ALTER TABLE [dbo].[Personal_Reservations] CHECK CONSTRAINT [FK_Personal_Reservation_Orders]
GO
ALTER TABLE [dbo].[Personal_Reservations]  WITH CHECK ADD  CONSTRAINT [FK_Personal_Reservations_Reservations] FOREIGN KEY([reservation_ID])
REFERENCES [dbo].[Reservations] ([reservation_ID])
GO
ALTER TABLE [dbo].[Personal_Reservations] CHECK CONSTRAINT [FK_Personal_Reservations_Reservations]
GO
ALTER TABLE [dbo].[Reservations]  WITH CHECK ADD  CONSTRAINT [FK_Reservation_Restrictions] FOREIGN KEY([restriction_ID])
REFERENCES [dbo].[Restrictions] ([restriction_ID])
GO
ALTER TABLE [dbo].[Reservations] CHECK CONSTRAINT [FK_Reservation_Restrictions]
GO
ALTER TABLE [dbo].[Restaurants]  WITH CHECK ADD  CONSTRAINT [FK_Restaurants_Towns] FOREIGN KEY([town_ID])
REFERENCES [dbo].[Towns] ([town_ID])
GO
ALTER TABLE [dbo].[Restaurants] CHECK CONSTRAINT [FK_Restaurants_Towns]
GO
ALTER TABLE [dbo].[Restrictions]  WITH CHECK ADD  CONSTRAINT [FK_Restrictions_Tables] FOREIGN KEY([table_ID])
REFERENCES [dbo].[Tables] ([table_ID])
GO
ALTER TABLE [dbo].[Restrictions] CHECK CONSTRAINT [FK_Restrictions_Tables]
GO
ALTER TABLE [dbo].[Suppliers]  WITH CHECK ADD  CONSTRAINT [FK_Suppliers_Towns] FOREIGN KEY([town_ID])
REFERENCES [dbo].[Towns] ([town_ID])
GO
ALTER TABLE [dbo].[Suppliers] CHECK CONSTRAINT [FK_Suppliers_Towns]
GO
ALTER TABLE [dbo].[Tables]  WITH CHECK ADD  CONSTRAINT [FK_Tables_Restaurants] FOREIGN KEY([restaurant_ID])
REFERENCES [dbo].[Restaurants] ([restaurant_ID])
GO
ALTER TABLE [dbo].[Tables] CHECK CONSTRAINT [FK_Tables_Restaurants]
GO
ALTER TABLE [dbo].[Towns_connections]  WITH CHECK ADD  CONSTRAINT [FK_TownsConnections_Countries] FOREIGN KEY([country_ID])
REFERENCES [dbo].[Countries] ([country_ID])
GO
ALTER TABLE [dbo].[Towns_connections] CHECK CONSTRAINT [FK_TownsConnections_Countries]
GO
ALTER TABLE [dbo].[Towns_connections]  WITH CHECK ADD  CONSTRAINT [FK_TownsConnections_Towns] FOREIGN KEY([town_ID])
REFERENCES [dbo].[Towns] ([town_ID])
GO
ALTER TABLE [dbo].[Towns_connections] CHECK CONSTRAINT [FK_TownsConnections_Towns]
GO
ALTER TABLE [dbo].[Clients]  WITH CHECK ADD  CONSTRAINT [CK_Clients] CHECK  (([e_mail] like '%@%'))
GO
ALTER TABLE [dbo].[Clients] CHECK CONSTRAINT [CK_Clients]
GO
ALTER TABLE [dbo].[Clients]  WITH CHECK ADD  CONSTRAINT [phone_numeric] CHECK  ((isnumeric([phone_number])=(1)))
GO
ALTER TABLE [dbo].[Clients] CHECK CONSTRAINT [phone_numeric]
GO
ALTER TABLE [dbo].[Companies]  WITH CHECK ADD  CONSTRAINT [NIP] CHECK  ((isnumeric([NIP])=(1)))
GO
ALTER TABLE [dbo].[Companies] CHECK CONSTRAINT [NIP]
GO
ALTER TABLE [dbo].[Companies]  WITH CHECK ADD  CONSTRAINT [Postal_code] CHECK  (([postal_code] like '[0-9][0-9]-[0-9][0-9][0-9]' OR [postal_code] like '[0-9][0-9][0-9][0-9][0-9]' OR [postal_code] like '[0-9][0-9][0-9][0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Companies] CHECK CONSTRAINT [Postal_code]
GO
ALTER TABLE [dbo].[Discount_dictionary]  WITH CHECK ADD  CONSTRAINT [CK_Discount_dictionary] CHECK  (([Discount_Value]>=(0) AND [Discount_Value]<=isnull([Max_Discount_Value],(1))))
GO
ALTER TABLE [dbo].[Discount_dictionary] CHECK CONSTRAINT [CK_Discount_dictionary]
GO
ALTER TABLE [dbo].[Discount_dictionary]  WITH CHECK ADD  CONSTRAINT [Dates] CHECK  (([From_date]<=[To_date]))
GO
ALTER TABLE [dbo].[Discount_dictionary] CHECK CONSTRAINT [Dates]
GO
ALTER TABLE [dbo].[Discount_dictionary]  WITH CHECK ADD  CONSTRAINT [Days] CHECK  (([Count_Of_Days]>=(0)))
GO
ALTER TABLE [dbo].[Discount_dictionary] CHECK CONSTRAINT [Days]
GO
ALTER TABLE [dbo].[Discount_dictionary]  WITH CHECK ADD  CONSTRAINT [Max_discount] CHECK  (([Max_Discount_Value]>=(0) AND [Max_Discount_Value]<=(1)))
GO
ALTER TABLE [dbo].[Discount_dictionary] CHECK CONSTRAINT [Max_discount]
GO
ALTER TABLE [dbo].[Discount_dictionary]  WITH CHECK ADD  CONSTRAINT [Orders_dictionary] CHECK  (([Count_Of_Orders]>=(0)))
GO
ALTER TABLE [dbo].[Discount_dictionary] CHECK CONSTRAINT [Orders_dictionary]
GO
ALTER TABLE [dbo].[Discounts]  WITH CHECK ADD  CONSTRAINT [CK_Discounts] CHECK  (([discount_value]<=(1) AND [discount_value]>=(0)))
GO
ALTER TABLE [dbo].[Discounts] CHECK CONSTRAINT [CK_Discounts]
GO
ALTER TABLE [dbo].[Discounts]  WITH CHECK ADD  CONSTRAINT [Discounts_dates] CHECK  (([start_date]<=[end_date]))
GO
ALTER TABLE [dbo].[Discounts] CHECK CONSTRAINT [Discounts_dates]
GO
ALTER TABLE [dbo].[Dish_Details]  WITH CHECK ADD  CONSTRAINT [Dish_Details_Price] CHECK  (([Price]>(0)))
GO
ALTER TABLE [dbo].[Dish_Details] CHECK CONSTRAINT [Dish_Details_Price]
GO
ALTER TABLE [dbo].[Dish_Details]  WITH CHECK ADD  CONSTRAINT [Dish_Details_Quantity] CHECK  (([Quantity]>(0)))
GO
ALTER TABLE [dbo].[Dish_Details] CHECK CONSTRAINT [Dish_Details_Quantity]
GO
ALTER TABLE [dbo].[Dishes]  WITH CHECK ADD  CONSTRAINT [Dishes_dates] CHECK  (([locked_date]<=[unlocked_date]))
GO
ALTER TABLE [dbo].[Dishes] CHECK CONSTRAINT [Dishes_dates]
GO
ALTER TABLE [dbo].[Dishes]  WITH CHECK ADD  CONSTRAINT [Dishes_execution_time] CHECK  (([execution_time]>(0)))
GO
ALTER TABLE [dbo].[Dishes] CHECK CONSTRAINT [Dishes_execution_time]
GO
ALTER TABLE [dbo].[Dishes]  WITH CHECK ADD  CONSTRAINT [Dishes_Price] CHECK  (([price]>(0)))
GO
ALTER TABLE [dbo].[Dishes] CHECK CONSTRAINT [Dishes_Price]
GO
ALTER TABLE [dbo].[Employees]  WITH CHECK ADD  CONSTRAINT [CK_Employees] CHECK  (([hire_date]<=isnull([job_quit_date],getdate())))
GO
ALTER TABLE [dbo].[Employees] CHECK CONSTRAINT [CK_Employees]
GO
ALTER TABLE [dbo].[Employees]  WITH CHECK ADD  CONSTRAINT [Employees_email] CHECK  (([email] like '%@%'))
GO
ALTER TABLE [dbo].[Employees] CHECK CONSTRAINT [Employees_email]
GO
ALTER TABLE [dbo].[Employees]  WITH CHECK ADD  CONSTRAINT [Employees_names] CHECK  (([first_name] like '[A-Z]%' AND [last_name] like '[A-Z]%'))
GO
ALTER TABLE [dbo].[Employees] CHECK CONSTRAINT [Employees_names]
GO
ALTER TABLE [dbo].[Employees]  WITH CHECK ADD  CONSTRAINT [Employees_part_time] CHECK  (([part_time]='Full_time' OR [part_time]='Half_time' OR [part_time]='Quarter_time'))
GO
ALTER TABLE [dbo].[Employees] CHECK CONSTRAINT [Employees_part_time]
GO
ALTER TABLE [dbo].[Employees]  WITH CHECK ADD  CONSTRAINT [Employees_phone] CHECK  ((isnumeric([phone_number])=(1)))
GO
ALTER TABLE [dbo].[Employees] CHECK CONSTRAINT [Employees_phone]
GO
ALTER TABLE [dbo].[Employees]  WITH CHECK ADD  CONSTRAINT [Employees_rate] CHECK  (([rate_per_hour]>=(0)))
GO
ALTER TABLE [dbo].[Employees] CHECK CONSTRAINT [Employees_rate]
GO
ALTER TABLE [dbo].[Indyvidual_clients]  WITH CHECK ADD  CONSTRAINT [CK_Indyvidual_clients_first_name] CHECK  (([first_name] like '[A-Z]%'))
GO
ALTER TABLE [dbo].[Indyvidual_clients] CHECK CONSTRAINT [CK_Indyvidual_clients_first_name]
GO
ALTER TABLE [dbo].[Indyvidual_clients]  WITH CHECK ADD  CONSTRAINT [CK_Indyvidual_clients_last_name] CHECK  (([last_name] like '[A-Z]%'))
GO
ALTER TABLE [dbo].[Indyvidual_clients] CHECK CONSTRAINT [CK_Indyvidual_clients_last_name]
GO
ALTER TABLE [dbo].[Ingredients]  WITH CHECK ADD  CONSTRAINT [Igredients_dates] CHECK  (([locked_date]<=[unlocked_date]))
GO
ALTER TABLE [dbo].[Ingredients] CHECK CONSTRAINT [Igredients_dates]
GO
ALTER TABLE [dbo].[Ingredients]  WITH CHECK ADD  CONSTRAINT [Igredients_price] CHECK  (([ingredient_price]>(0)))
GO
ALTER TABLE [dbo].[Ingredients] CHECK CONSTRAINT [Igredients_price]
GO
ALTER TABLE [dbo].[Ingredients]  WITH CHECK ADD  CONSTRAINT [Igredients_safe] CHECK  (([safe_amout]>=(0)))
GO
ALTER TABLE [dbo].[Ingredients] CHECK CONSTRAINT [Igredients_safe]
GO
ALTER TABLE [dbo].[Ingredients]  WITH CHECK ADD  CONSTRAINT [Igredients_stock] CHECK  (([ingredient_in_stock]>=(0)))
GO
ALTER TABLE [dbo].[Ingredients] CHECK CONSTRAINT [Igredients_stock]
GO
ALTER TABLE [dbo].[Menu]  WITH CHECK ADD  CONSTRAINT [CK_Menu] CHECK  (([Add_date]<=[Remove_date]))
GO
ALTER TABLE [dbo].[Menu] CHECK CONSTRAINT [CK_Menu]
GO
ALTER TABLE [dbo].[Order_details]  WITH CHECK ADD  CONSTRAINT [CK_Order_details_price] CHECK  (([price]>(0)))
GO
ALTER TABLE [dbo].[Order_details] CHECK CONSTRAINT [CK_Order_details_price]
GO
ALTER TABLE [dbo].[Order_details]  WITH CHECK ADD  CONSTRAINT [CK_Order_details_quantity] CHECK  (([quantity]>(0)))
GO
ALTER TABLE [dbo].[Order_details] CHECK CONSTRAINT [CK_Order_details_quantity]
GO
ALTER TABLE [dbo].[Positions]  WITH CHECK ADD  CONSTRAINT [CK_Positions_name] CHECK  (([position_name]='Cleaner' OR [position_name]='Dishwasher' OR [position_name]='Chef' OR [position_name]='Manager' OR [position_name]='Cook' OR [position_name]='Waiter'))
GO
ALTER TABLE [dbo].[Positions] CHECK CONSTRAINT [CK_Positions_name]
GO
ALTER TABLE [dbo].[Restaurants]  WITH CHECK ADD  CONSTRAINT [CK_Restaurants_email] CHECK  (([e_mail] like '%@%'))
GO
ALTER TABLE [dbo].[Restaurants] CHECK CONSTRAINT [CK_Restaurants_email]
GO
ALTER TABLE [dbo].[Restaurants]  WITH CHECK ADD  CONSTRAINT [CK_Restaurants_NIP] CHECK  ((isnumeric([NIP])=(1)))
GO
ALTER TABLE [dbo].[Restaurants] CHECK CONSTRAINT [CK_Restaurants_NIP]
GO
ALTER TABLE [dbo].[Restaurants]  WITH CHECK ADD  CONSTRAINT [CK_Restaurants_phone] CHECK  ((isnumeric([phone_number])=(1)))
GO
ALTER TABLE [dbo].[Restaurants] CHECK CONSTRAINT [CK_Restaurants_phone]
GO
ALTER TABLE [dbo].[Restrictions]  WITH CHECK ADD  CONSTRAINT [CK_Restrictions_dates] CHECK  (([start_date]<=[end_date]))
GO
ALTER TABLE [dbo].[Restrictions] CHECK CONSTRAINT [CK_Restrictions_dates]
GO
ALTER TABLE [dbo].[Restrictions]  WITH CHECK ADD  CONSTRAINT [CK_Restrictions_limit] CHECK  (([limit_chairs]>=(0)))
GO
ALTER TABLE [dbo].[Restrictions] CHECK CONSTRAINT [CK_Restrictions_limit]
GO
ALTER TABLE [dbo].[Suppliers]  WITH CHECK ADD  CONSTRAINT [CK_Suppliers_bank_account] CHECK  ((isnumeric([bank_account])=(1)))
GO
ALTER TABLE [dbo].[Suppliers] CHECK CONSTRAINT [CK_Suppliers_bank_account]
GO
ALTER TABLE [dbo].[Suppliers]  WITH CHECK ADD  CONSTRAINT [CK_Suppliers_email] CHECK  (([supplier_email] like '%@%'))
GO
ALTER TABLE [dbo].[Suppliers] CHECK CONSTRAINT [CK_Suppliers_email]
GO
ALTER TABLE [dbo].[Suppliers]  WITH CHECK ADD  CONSTRAINT [CK_Suppliers_nip_number] CHECK  ((isnumeric([NIP_number])=(1)))
GO
ALTER TABLE [dbo].[Suppliers] CHECK CONSTRAINT [CK_Suppliers_nip_number]
GO
ALTER TABLE [dbo].[Suppliers]  WITH CHECK ADD  CONSTRAINT [CK_Suppliers_phone_number] CHECK  ((isnumeric([supplier_phone])=(1)))
GO
ALTER TABLE [dbo].[Suppliers] CHECK CONSTRAINT [CK_Suppliers_phone_number]
GO
ALTER TABLE [dbo].[Suppliers]  WITH CHECK ADD  CONSTRAINT [CK_Suppliers_postal_code] CHECK  (([postal_code] like '[0-9][0-9]-[0-9][0-9][0-9]' OR [postal_code] like '[0-9][0-9][0-9][0-9][0-9]' OR [postal_code] like '[0-9][0-9][0-9][0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Suppliers] CHECK CONSTRAINT [CK_Suppliers_postal_code]
GO
ALTER TABLE [dbo].[Tables]  WITH CHECK ADD  CONSTRAINT [chairs_amount] CHECK  (([chairs_ammount]>(0)))
GO
ALTER TABLE [dbo].[Tables] CHECK CONSTRAINT [chairs_amount]
GO
/****** Object:  StoredProcedure [dbo].[AddCategory]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddCategory]
	-- Add the parameters for the stored procedure here
	@categoryName VARCHAR(15),
	@categoryDescription VARCHAR(40) = NULL
AS

DECLARE @error AS VARCHAR(20);

IF @categoryName IS NULL
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

INSERT INTO dbo.Categories
(
    category_ID,
    category_name,
    category_description
)
VALUES
(   (SELECT MAX(category_ID)+1 FROM dbo.Categories),  -- category_ID - int
    @categoryName, -- category_name - varchar(15)
    @categoryDescription  -- category_description - varchar(40)
    )

GO
/****** Object:  StoredProcedure [dbo].[AddCompanyClient]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddCompanyClient]
	@companyName AS VARCHAR(20),
	@NIP AS VARCHAR(10),
	@adress AS VARCHAR(50),
	@townName AS VARCHAR(50),
	@countryName AS VARCHAR(50),
	@postalCode AS VARCHAR(10),
	@phoneNumber AS VARCHAR(10),
	@email AS VARCHAR(50),
	@restaurantID AS INT
AS

DECLARE @newClientID AS INT;
SET @newClientID = (SELECT MAX(client_ID)+1 FROM dbo.Clients);

IF @townName NOT IN (
	SELECT town_name FROM dbo.Towns AS t
	INNER JOIN dbo.Towns_connections tc ON t.town_ID = tc.town_ID
	INNER JOIN dbo.Countries c ON c.country_ID = tc.country_ID
	WHERE t.town_name = @townName AND c.country_name = @countryName
	)
BEGIN
	EXEC dbo.AddTown @townName = @townName, @countryName = @countryName;
END

INSERT INTO dbo.Clients
(
    client_ID,
    phone_number,
    e_mail,
    restaurant_ID
)
VALUES
(   @newClientID,  -- client_ID - int
    @phoneNumber, -- phone_number - varchar(10)
    @email, -- e_mail - varchar(50)
    @restaurantID   -- restaurant_ID - int
    )

INSERT INTO dbo.Companies
(
    client_ID,
    company_name,
    NIP,
    address,
    town_ID,
    postal_code
)
VALUES
(   @newClientID,  -- client_ID - int
    @companyName, -- company_name - varchar(20)
    @NIP, -- NIP - varchar(10)
    @adress, -- address - varchar(50)
    (SELECT tc.town_ID FROM dbo.Towns AS t
	INNER JOIN dbo.Towns_connections tc ON t.town_ID = tc.town_ID
	INNER JOIN dbo.Countries c ON c.country_ID = tc.country_ID
	WHERE t.town_name = @townName AND c.country_name = @countryName
	),  -- town_ID - int
    @postalCode  -- postal_code - varchar(10)
    )

GO
/****** Object:  StoredProcedure [dbo].[AddCompanyReservation]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddCompanyReservation]
	@clientID AS INT,
	@reservationDate AS DATE,
	@reservationTime AS TIME(7),
	@tableID AS INT,
	@nameID AS INT = NULL
AS

DECLARE @error AS VARCHAR(20);
DECLARE @restaurantID AS INT;
DECLARE @restrictionID AS INT;
DECLARE @reservationID AS INT;

SET @restaurantID = (SELECT restaurant_ID FROM dbo.Tables WHERE @tableID = table_ID);
SET @restrictionID = (SELECT restriction_ID FROM dbo.Restrictions WHERE [start_date] <= @reservationDate AND  @reservationDate <= [end_date] AND @tableID = table_ID)
SET @reservationID = (SELECT MAX(reservation_ID)+1 FROM dbo.Reservations)

IF 
@clientID NOT IN (SELECT client_ID FROM dbo.Companies) OR @reservationDate < CAST(GETDATE() AS DATE) OR @tableID NOT IN (SELECT [Numer stolika] FROM dbo.SpecificDaysFreeTables(@restaurantID, @reservationDate, @reservationTime))
BEGIN
	SET @error = 'Nie możesz złożyć rezerwacji!';
	RAISERROR(@error, 16, 1);
	RETURN;
END

INSERT INTO dbo.Reservations
(
    reservation_ID,
    client_ID,
    reservation_date,
    reservation_time,
    restriction_ID
)
VALUES
(   @reservationID,          -- reservation_ID - int
    @clientID,          -- client_ID - int
    @reservationDate,  -- reservation_date - date
    @reservationTime, -- reservation_time - time(7)
    @restrictionID           -- restriction_ID - int
    )

INSERT INTO dbo.Company_Reservations
(
    resevervation_ID
)
VALUES
(@reservationID  -- resevervation_ID - int
    )

IF @nameID IS NOT NULL
BEGIN
	EXEC AddNameReservation @reservationID = @reservationID, @nameID = @nameID
END
GO
/****** Object:  StoredProcedure [dbo].[AddCountry]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddCountry]
	-- Add the parameters for the stored procedure here
	@countryName VARCHAR(50)
AS

DECLARE @error AS VARCHAR(20);

IF @countryName IS NULL
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

INSERT INTO dbo.Countries
(
	country_ID,
    country_name
)
VALUES
( 
	(SELECT MAX(country_ID)+1 FROM dbo.Countries),
    @countryName -- country_name - varchar(50)
)

GO
/****** Object:  StoredProcedure [dbo].[AddDiscountDictionary]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddDiscountDictionary]
	@countOfOrders AS INT,
	@valueOrders AS MONEY = NULL,
	@countOfDays AS INT = NULL,
	@discountValue AS FLOAT,
	@maxDiscountValue AS FLOAT,
	@discountDescription AS VARCHAR(50),
	@oneTimeDiscount AS BIT,
	@fromDate AS DATE,
	@toDate AS DATE,
	@restaurantID AS INT
AS

DECLARE @error AS VARCHAR(20);
DECLARE @newDiscountTypeID AS INT;

IF @restaurantID NOT IN (SELECT restaurant_ID FROM dbo.Restaurants)
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

SET @newDiscountTypeID = (SELECT MAX(Discount_type_ID)+1 FROM dbo.Discount_dictionary)

INSERT INTO dbo.Discount_dictionary
(
    Discount_type_ID,
    Count_Of_Orders,
    Value_Orders,
    Count_Of_Days,
    Discount_Value,
    Max_Discount_Value,
    Discount_description,
    One_Time_Discount,
    From_date,
    To_date,
    Restaurant_ID
)
VALUES
(   @newDiscountTypeID,         -- Discount_type_ID - int
    @countOfOrders,         -- Count_Of_Orders - int
    @valueOrders,      -- Value_Orders - money
    @countOfDays,         -- Count_Of_Days - int
    @discountValue,       -- Discount_Value - float
    @maxDiscountValue,       -- Max_Discount_Value - float
    @discountDescription,        -- Discount_description - varchar(50)
    @oneTimeDiscount,      -- One_Time_Discount - bit
    @fromDate, -- From_date - date
    @toDate, -- To_date - date
    @restaurantID          -- Restaurant_ID - int
    )



GO
/****** Object:  StoredProcedure [dbo].[AddDish]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddDish]
	@name AS VARCHAR(30),
	@categoryName AS VARCHAR(15),
	@price AS INT,
	@executionTime AS INT,
	@restaurantID AS INT
AS

DECLARE @error AS VARCHAR(20);
DECLARE @newDishID AS INT;

IF @restaurantID NOT IN (SELECT restaurant_ID FROM dbo.Restaurants)
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

SET @newDishID = (SELECT MAX(dish_ID)+1 FROM dbo.Dishes);

IF @categoryName NOT IN (SELECT category_name FROM dbo.Categories)
BEGIN
	EXEC dbo.AddCategory @categoryName = @categoryName       -- varchar(15)
END

INSERT INTO dbo.Dishes
(
    dish_ID,
    category_ID,
    dish_name,
    price,
    execution_time,
    locked_date,
    unlocked_date,
    restaurant_ID
)
VALUES
(   @newDishID,         -- dish_ID - int
    (SELECT category_ID FROM dbo.Categories WHERE category_name = @categoryName),         -- category_ID - int
    @name,        -- dish_name - varchar(30)
    @price,      -- price - money
    @executionTime,         -- execution_time - int
    NULL, -- locked_date - date
    NULL, -- unlocked_date - date
    @restaurantID          -- restaurant_ID - int
    )



GO
/****** Object:  StoredProcedure [dbo].[AddDishToMenu]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddDishToMenu]
	@dishID AS INT,
	@addDate AS DATE,
	@removeDate AS DATE,
	@restaurantID AS INT
AS

DECLARE @error AS VARCHAR(20);
DECLARE @newMenuID AS INT;

IF @restaurantID NOT IN (SELECT restaurant_ID FROM dbo.Restaurants) OR @dishID NOT IN (SELECT [Numer dania] FROM dbo.DishesThatCanBeAddedToMenu(@restaurantID))
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

SET @newMenuID = (SELECT MAX(Menu_ID)+1 FROM dbo.Menu)

INSERT INTO dbo.Menu
(
    Menu_ID,
    Dish_ID,
    Add_date,
    Remove_date,
    restaurant_ID
)
VALUES
(   @newMenuID,         -- Menu_ID - int
    @dishID,         -- Dish_ID - int
    @addDate, -- Add_date - date
    @removeDate, -- Remove_date - date
    @restaurantID          -- restaurant_ID - int
    )

GO
/****** Object:  StoredProcedure [dbo].[AddEmployee]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddEmployee]
	@positionName AS VARCHAR(20),
	@firstName AS VARCHAR(40),
	@lastName AS VARCHAR(40),
	@partTime AS VARCHAR(15),
	@hireDate AS DATE,
	@rate_per_hour AS MONEY,
	@phoneNumber AS VARCHAR(12),
	@email AS VARCHAR(50),
	@photoPath AS VARCHAR(50),
	@restaurantID AS INT

AS

DECLARE @positionID AS INT;
DECLARE @newEmployeeID AS INT;
DECLARE @error AS VARCHAR(20);

IF @positionName NOT IN (SELECT position_name FROM dbo.Positions)
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

SET @positionID = (SELECT position_ID FROM dbo.Positions WHERE position_name = @positionName);
SET @newEmployeeID = (SELECT MAX(employee_ID)+1 FROM dbo.Employees);

INSERT INTO dbo.Employees
(
    employee_ID,
    position_ID,
    first_name,
    last_name,
    part_time,
    rate_per_hour,
    phone_number,
    email,
    hire_date,
    photo_path,
    job_quit_date,
    restaurant_ID
)
VALUES
(   @newEmployeeID,         -- employee_ID - int
    @positionID,         -- position_ID - int
    @firstName,        -- first_name - varchar(40)
    @lastName,        -- last_name - varchar(40)
    @partTime,        -- part_time - varchar(15)
    @rate_per_hour,      -- rate_per_hour - money
    @phoneNumber,        -- phone_number - varchar(12)
    @email,        -- email - varchar(50)
    ISNULL(@hireDate, GETDATE()), -- hire_date - date
    @photoPath,        -- photo_path - varchar(50)
    NULL, -- job_quit_date - date
    @restaurantID          -- restaurant_ID - int
    )
	




GO
/****** Object:  StoredProcedure [dbo].[AddIndyvidualClient]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddIndyvidualClient]
	@phoneNumber AS VARCHAR(10),
	@email AS VARCHAR(50),
	@firstName AS VARCHAR(30),
	@lastName AS VARCHAR(30),
	@restaurantID AS INT
AS

DECLARE @newClientID AS INT;
DECLARE @error AS VARCHAR(20);

SET @newClientID = (SELECT MAX(client_ID)+1 FROM dbo.Clients)

IF @restaurantID IS NULL
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

INSERT INTO dbo.Clients
(
    client_ID,
    phone_number,
    e_mail,
    restaurant_ID
)
VALUES
(   @newClientID,  -- client_ID - int
    @phoneNumber, -- phone_number - varchar(10)
    @email, -- e_mail - varchar(50)
    @restaurantID   -- restaurant_ID - int
    )


INSERT INTO dbo.Indyvidual_clients
(
    client_ID,
    first_name,
    last_name
)
VALUES
(   @newClientID,  -- client_ID - int
    @firstName, -- first_name - varchar(30)
    @lastName  -- last_name - varchar(30)
    )


GO
/****** Object:  StoredProcedure [dbo].[AddIndyvidualReservation]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddIndyvidualReservation]
	@clientID AS INT,
	@orderID AS INT,
	@reservationDate AS DATE,
	@reservationTime AS TIME(7),
	@tableID AS INT
AS

DECLARE @error AS VARCHAR(20);
DECLARE @restaurantID AS INT;
DECLARE @restrictionID AS INT;
DECLARE @reservationID AS INT;

SET @restaurantID = (SELECT restaurant_ID FROM dbo.Tables WHERE @tableID = table_ID);
SET @restrictionID = (SELECT restriction_ID FROM dbo.Restrictions WHERE start_date <= @reservationDate AND end_date <= @reservationDate AND @tableID = table_ID)
SET @reservationID = (SELECT MAX(reservation_ID)+1 FROM dbo.Reservations)

IF (dbo.CanIndyvidualMakeReservation(@clientID,@orderID)) = 0 OR @reservationDate >= GETDATE() OR @tableID NOT IN (SELECT [Numer stolika] FROM dbo.SpecificDaysFreeTables(@restaurantID, @reservationDate, @reservationTime))
BEGIN
	SET @error = 'Nie możesz złożyć rezerwacji!';
	RAISERROR(@error, 16, 1);
END

INSERT INTO dbo.Reservations
(
    reservation_ID,
    client_ID,
    reservation_date,
    reservation_time,
    restriction_ID
)
VALUES
(   @reservationID,          -- reservation_ID - int
    @clientID,          -- client_ID - int
    @reservationDate,  -- reservation_date - date
    @reservationTime, -- reservation_time - time(7)
    @restrictionID           -- restriction_ID - int
    )

INSERT INTO dbo.Personal_Reservations
(
    reservation_ID,
    order_ID
)
VALUES
(   @reservationID, -- reservation_ID - int
    @orderID  -- order_ID - int
    )







GO
/****** Object:  StoredProcedure [dbo].[AddIndyvidualToCompany]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddIndyvidualToCompany]
	@indyvidualID AS INT,
	@companyID AS INT
AS

DECLARE @error AS VARCHAR(20);

IF @indyvidualID NOT IN (SELECT client_ID FROM dbo.Indyvidual_clients) OR @companyID NOT IN (SELECT client_ID FROM dbo.Companies)
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

INSERT INTO dbo.Company_Members
(
    Company_ID,
    Indyvidual_Client_ID
)
VALUES
(   @companyID, -- Company_ID - int
    @indyvidualID  -- Indyvidual_Client_ID - int
    )

GO
/****** Object:  StoredProcedure [dbo].[AddIngredient]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddIngredient]
	@name AS VARCHAR(20),
	@supplierID AS INT,
	@inStock AS INT = 0,
	@price AS MONEY = 0.01,
	@quantity AS VARCHAR(20),
	@extraInformation AS VARCHAR(50) = NULL,
	@restaurantID AS INT
AS

DECLARE @error AS VARCHAR(20);
DECLARE @newIngredientID AS INT;

SET @newIngredientID = (SELECT MAX(ingredient_ID)+1 FROM dbo.Ingredients);

IF @supplierID NOT IN (SELECT supplier_ID FROM dbo.Suppliers) OR @restaurantID NOT IN (SELECT @restaurantID FROM dbo.Restaurants)
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

INSERT INTO dbo.Ingredients
(
    ingredient_ID,
    supplier_ID,
    ingredient_name,
    ingredient_in_stock,
    ingredient_price,
    ingredient_quantity,
    safe_amout,
    extra_informations,
    locked_date,
    unlocked_date,
    restaurant_ID
)
VALUES
(   @newIngredientID,         -- ingredient_ID - int
    @supplierID,         -- supplier_ID - int
    @name,        -- ingredient_name - varchar(20)
    @inStock,         -- ingredient_in_stock - int
    @price,      -- ingredient_price - money
    @quantity,        -- ingredient_quantity - varchar(20)
    5,         -- safe_amout - int
    @extraInformation,        -- extra_informations - varchar(50)
    NULL, -- locked_date - date
    NULL, -- unlocked_date - date
    @restaurantID          -- restaurant_ID - int
    )


GO
/****** Object:  StoredProcedure [dbo].[AddNameReservation]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddNameReservation]
	@reservationID AS INT,
	@nameID AS INT
AS

DECLARE @companyID AS INT;
SET @companyID = (SELECT client_ID FROM dbo.Reservations WHERE @reservationID = reservation_ID)

DECLARE @error AS VARCHAR(20);

IF @nameID NOT IN (SELECT Indyvidual_Client_ID FROM dbo.Company_Members WHERE @companyID = Company_ID)
BEGIN
	SET @error = 'Nie możesz złożyć rezerwacji!';
	RAISERROR(@error, 16, 1);
END

IF @nameID IS NOT NULL
BEGIN
    INSERT INTO dbo.Company_Name_Reservation
    (
        reservation_ID,
        client_ID
    )
    VALUES
    (   @reservationID, -- reservation_ID - int
        @nameID  -- client_ID - int
        )
END

GO
/****** Object:  StoredProcedure [dbo].[AddNewDiscountToCompanies]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddNewDiscountToCompanies]
	@clientID AS INT
AS
BEGIN
	DECLARE @valueOfFirstTypeOfDiscount FLOAT;
	DECLARE @firstDiscountTypeID INT;
	DECLARE @newDiscountID INT;

	SET @valueOfFirstTypeOfDiscount = dbo.GetCompanyFirstDiscountValue(@clientID, GETDATE());
	
	IF @valueOfFirstTypeOfDiscount > 0
	BEGIN
		SET @firstDiscountTypeID = (SELECT Discount_type_ID FROM dbo.Discount_dictionary WHERE Max_Discount_Value IS NOT NULL AND One_Time_Discount = 0 AND Count_Of_Days IS NULL AND GETDATE() >= From_date AND GETDATE() <= To_date );
		SET @newDiscountID = ISNULL((SELECT MAX(discount_ID)+1 FROM dbo.Discounts),0);

		INSERT INTO dbo.Discounts
		(
		    discount_ID,
		    client_ID,
		    discount_value,
		    start_date,
		    end_date,
		    discount_type_ID
		)
		VALUES
		(   @newDiscountID,         -- discount_ID - int
		    @clientID,         -- client_ID - int
		    @valueOfFirstTypeOfDiscount,       -- discount_value - float
		    GETDATE(), -- start_date - date
		    DATEADD(MONTH, 1, GETDATE()), -- end_date - date
		    @firstDiscountTypeID          -- discount_type_ID - int
		    )
	END

	DECLARE @secondDiscountTypeID INT;
	DECLARE @valueOfSecondTypeOfDiscount FLOAT;

	SET @secondDiscountTypeID = dbo.GetCompanySecondDiscountID(@clientID, GETDATE());

	IF @secondDiscountTypeID != -1
	BEGIN
		SET @valueOfSecondTypeOfDiscount = (SELECT Discount_Value FROM dbo.Discount_dictionary WHERE Discount_type_ID = @secondDiscountTypeID);
		SET @newDiscountID = ISNULL((SELECT MAX(discount_ID)+1 FROM dbo.Discounts),0);

		INSERT INTO dbo.Discounts
		(
		    discount_ID,
		    client_ID,
		    discount_value,
		    start_date,
		    end_date,
		    discount_type_ID
		)
		VALUES
		(   @newDiscountID,         -- discount_ID - int
		    @clientID,         -- client_ID - int
		    @valueOfSecondTypeOfDiscount,       -- discount_value - float
		    GETDATE(), -- start_date - date
		    DATEADD(MONTH, 3, GETDATE()), -- end_date - date
		    @secondDiscountTypeID          -- discount_type_ID - int
		    )
	END



END
GO
/****** Object:  StoredProcedure [dbo].[AddOrder]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddOrder]
	@clientID AS INT,
	@employeeID AS INT,
	@takeaway AS BIT,
	@orderDate AS DATE,
	@pickupTime AS DATETIME,
	@discountID AS INT,
	@isPaid AS BIT
AS

DECLARE @newOrderID AS INT;
DECLARE @error AS VARCHAR(20);

IF @orderDate < GETDATE()
BEGIN
	SET @error = 'Nie możesz złożyć zamówienia!';
	RAISERROR(@error, 30, 1);
	RETURN;
END

SET @newOrderID = ISNULL((SELECT MAX(order_ID)+1 FROM dbo.Orders), 0);

INSERT INTO dbo.Orders
(
    order_ID,
    client_ID,
    employee_ID,
    takeaway,
    order_date,
    pickup_time,
    discount_ID
)
VALUES
(   @newOrderID,         -- order_ID - int
    @clientID,         -- client_ID - int
    @employeeID,         -- employee_ID - int
    @takeaway,      -- takeaway - bit
    @orderDate, -- order_date - date
    @pickupTime, -- pickup_time - datetime
    @discountID        -- discount - float
    )

IF @isPaid = 0
BEGIN
	INSERT INTO dbo.Orders_Unpaid
	(
	    order_ID
	)
	VALUES
	(@newOrderID  -- order_ID - int
	    )
END

GO
/****** Object:  StoredProcedure [dbo].[AddOrderDetails]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddOrderDetails]
	@orderID AS INT,
	@menuID AS INT,
	@quantity AS INT,
	@price AS MONEY
AS

INSERT INTO dbo.Order_details
(
    Order_ID,
    Menu_ID,
    Quantity,
    Price
)
VALUES
(   @orderID,   -- Order_ID - int
    @menuID,   -- Menu_ID - int
    @quantity,   -- Quantity - int
    @price -- Price - money
    )


GO
/****** Object:  StoredProcedure [dbo].[AddRestaurant]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddRestaurant]
	@restaurantName AS VARCHAR(20),
	@townName AS VARCHAR(50),
	@countryName AS VARCHAR(50),
	@adress AS VARCHAR(30),
	@NIP AS VARCHAR(10),
	@phoneNumber AS VARCHAR(9),
	@email AS VARCHAR(20)
AS

DECLARE @newRestaurantID AS INT
SET @newRestaurantID = (SELECT MAX(restaurant_ID)+1 FROM dbo.Restaurants)

IF @townName NOT IN (
	SELECT town_name FROM dbo.Towns AS t
	INNER JOIN dbo.Towns_connections tc ON t.town_ID = tc.town_ID
	INNER JOIN dbo.Countries c ON c.country_ID = tc.country_ID
	WHERE t.town_name = @townName AND c.country_name = @countryName
	)
BEGIN
	EXEC dbo.AddTown @townName = @townName, @countryName = @countryName;
END

INSERT INTO dbo.Restaurants
(
    restaurant_ID,
    restaurant_name,
    town_ID,
    adress,
    NIP,
    phone_number,
    e_mail
)
VALUES
(   @newRestaurantID,  -- restaurant_ID - int
    @restaurantName, -- restaurant_name - varchar(20)
    (SELECT tc.town_ID FROM dbo.Towns AS t
	INNER JOIN dbo.Towns_connections tc ON t.town_ID = tc.town_ID
	INNER JOIN dbo.Countries c ON c.country_ID = tc.country_ID
	WHERE t.town_name = @townName AND c.country_name = @countryName
	),  -- town_ID - int
    @adress, -- adress - varchar(30)
    @NIP, -- NIP - varchar(10)
    @phoneNumber, -- phone_number - varchar(15)
    @email  -- e_mail - varchar(20)
    )

GO
/****** Object:  StoredProcedure [dbo].[AddRestriction]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddRestriction]
	@tableID AS INT,
	@startDate AS DATE,
	@endDate AS DATE,
	@charsLimit AS FLOAT
AS

DECLARE @error AS VARCHAR(20);
DECLARE @newRestarictionID AS INT;
DECLARE @newLimit AS INT;

IF 0 > @charsLimit OR @charsLimit > 1
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

SET @newRestarictionID = (SELECT MAX(restriction_ID)+1 FROM dbo.Reservations);
SET @newLimit = FLOOR((SELECT chairs_ammount FROM dbo.Tables WHERE @tableID = table_ID) * @charsLimit);

INSERT INTO dbo.Restrictions
(
    restriction_ID,
    table_ID,
    start_date,
    end_date,
    limit_chairs
)
VALUES
(   @newRestarictionID,         -- restriction_ID - int
    @tableID,         -- table_ID - int
    @startDate, -- start_date - date
    @endDate, -- end_date - date
    @newLimit       -- limit_chairs - int
    )

GO
/****** Object:  StoredProcedure [dbo].[AddSupplier]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddSupplier]
	@supplierName AS VARCHAR(30),
	@townName AS VARCHAR(50),
	@countryName AS VARCHAR(50),
	@NIP AS VARCHAR(10),
	@phoneNumber AS VARCHAR(12),
	@email AS VARCHAR(20),
	@street AS VARCHAR(20),
	@postalCode AS VARCHAR(10),
	@bankAccount AS VARCHAR(26)
AS

DECLARE @newSupplierID AS INT;
SET @newSupplierID = (SELECT MAX(supplier_ID)+1 FROM dbo.Suppliers);

IF @townName NOT IN (
	SELECT town_name FROM dbo.Towns AS t
	INNER JOIN dbo.Towns_connections tc ON t.town_ID = tc.town_ID
	INNER JOIN dbo.Countries c ON c.country_ID = tc.country_ID
	WHERE t.town_name = @townName AND c.country_name = @countryName
	)
BEGIN
	EXEC dbo.AddTown @townName = @townName, @countryName = @countryName;
END

INSERT INTO dbo.Suppliers
(
    supplier_ID,
    town_ID,
    NIP_number,
    supplier_name,
    supplier_phone,
    supplier_email,
    street,
    postal_code,
    bank_account
)
VALUES
(   @newSupplierID,  -- supplier_ID - int
    (SELECT tc.town_ID FROM dbo.Towns AS t
	INNER JOIN dbo.Towns_connections tc ON t.town_ID = tc.town_ID
	INNER JOIN dbo.Countries c ON c.country_ID = tc.country_ID
	WHERE t.town_name = @townName AND c.country_name = @countryName
	),  -- town_ID - int
    @NIP, -- NIP_number - varchar(10)
    @supplierName, -- supplier_name - varchar(30)
    @phoneNumber, -- supplier_phone - varchar(12)
    @email, -- supplier_email - varchar(20)
    @street, -- street - varchar(20)
    @postalCode, -- postal_code - varchar(10)
    @bankAccount  -- bank_account - varchar(26)
    )

GO
/****** Object:  StoredProcedure [dbo].[AddTable]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddTable]
	@chairsAmmout AS INT,
	@restaurantID AS INT
AS
	
DECLARE @error AS VARCHAR(20);
DECLARE @newTableID AS INT;

SET @newTableID = (SELECT MAX(table_ID)+1 FROM dbo.Tables);

IF @restaurantID NOT IN (SELECT restaurant_ID FROM dbo.Restaurants)
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

INSERT INTO dbo.Tables
(
    table_ID,
    chairs_ammount,
    restaurant_ID
)
VALUES
(   @newTableID, -- table_ID - int
    @chairsAmmout, -- chairs_ammount - int
    @restaurantID  -- restaurant_ID - int
    )

GO
/****** Object:  StoredProcedure [dbo].[AddTown]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddTown]
	@townName VARCHAR(50),
	@countryName VARCHAR(50)
AS

DECLARE @error AS VARCHAR(20);
DECLARE @newTownID AS INT

IF @townName IS NULL OR @countryName IS NULL
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

SET @newTownID = (SELECT MAX(town_ID)+1 FROM dbo.Towns);

INSERT INTO dbo.Towns
(
    town_ID,
    town_name
)
VALUES
(   @newTownID, -- town_ID - int
    @townName -- town_name - varchar(50)
    )

IF @countryName NOT IN (SELECT country_name FROM dbo.Countries)
BEGIN
	EXEC dbo.AddCountry @countryName = @countryName;
END

INSERT INTO dbo.Towns_connections
(
    town_ID,
    country_ID
)
VALUES
(   @newTownID, -- town_ID - int
    (SELECT country_ID FROM dbo.Countries WHERE country_name = @countryName)  -- country_ID - int
    )



GO
/****** Object:  StoredProcedure [dbo].[ConnectDishWithIngredient]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ConnectDishWithIngredient]
	@dishID AS INT,
	@ingredientID AS INT,
	@quantity AS FLOAT,
	@price AS MONEY
AS

DECLARE @error AS VARCHAR(20);
DECLARE @dishRestaurantID AS INT;
DECLARE @ingredientRestaurantID AS INT;

SET @dishRestaurantID = (SELECT restaurant_ID FROM dbo.Dishes WHERE dish_ID = @dishID);
SET @ingredientRestaurantID = (SELECT restaurant_ID FROM dbo.Ingredients WHERE ingredient_ID = @ingredientID)

IF @dishID NOT IN (SELECT dish_ID FROM dbo.Dishes) OR @ingredientID NOT IN (SELECT ingredient_ID FROM dbo.Ingredients) OR @dishRestaurantID != @ingredientRestaurantID
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

INSERT INTO dbo.Dish_Details
(
    dish_ID,
    ingredient_ID,
    Quantity,
    Price
)
VALUES
(   @dishID,   -- dish_ID - int
    @ingredientID,   -- ingredient_ID - int
    @quantity, -- Quantity - float
    @price -- Price - money
    )

GO
/****** Object:  StoredProcedure [dbo].[DeleteUnpaidOrder]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DeleteUnpaidOrder]
	@deletingOrderID AS INT
AS

DECLARE @error AS VARCHAR(20);

IF @deletingOrderID IS NULL
BEGIN
	SET @error = 'Błędne dane!';
	RAISERROR(@error, 16, 1);
END

DELETE FROM dbo.Orders_Unpaid
WHERE order_ID = @deletingOrderID


GO
/****** Object:  StoredProcedure [dbo].[MenuMessage]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MenuMessage] 
	@restaurantID AS INT
AS

DECLARE @countAllMenu AS INT;
DECLARE @countMenuOverTwoWeeks AS INT;

SET @countAllMenu = (SELECT COUNT(*) FROM dbo.MenuToday(@restaurantID));
SET @countMenuOverTwoWeeks = (SELECT COUNT(*) FROM dbo.DishesInMenuOverTwoWeeks(@restaurantID));

IF @countMenuOverTwoWeeks > 0.5 * @countAllMenu
BEGIN
	PRINT 'Trzeba zmienić menu!'
END
GO
/****** Object:  StoredProcedure [dbo].[UpdateIngeredientAmmount]    Script Date: 20.01.2021 21:27:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateIngeredientAmmount]
	@ingredientID AS INT,
	@ammount AS INT
AS

UPDATE dbo.Ingredients
SET ingredient_in_stock = ingredient_in_stock + @ammount
WHERE ingredient_ID = @ingredientID

GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Order_details', @level2type=N'CONSTRAINT',@level2name=N'CK_Order_details_price'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[9] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Categories"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 119
               Right = 237
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CategoriesInformations'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'CategoriesInformations'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "r"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 215
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 6
               Left = 253
               Bottom = 102
               Right = 423
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "tc"
            Begin Extent = 
               Top = 6
               Left = 461
               Bottom = 102
               Right = 631
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 6
               Left = 669
               Bottom = 102
               Right = 839
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1815
         Width = 4935
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'RestaurantsInformations'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'RestaurantsInformations'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[11] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Towns"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 102
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Towns_connections"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 102
               Right = 416
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Countries"
            Begin Extent = 
               Top = 6
               Left = 454
               Bottom = 102
               Right = 624
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'TownsAndCountriesNames'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'TownsAndCountriesNames'
GO
USE [master]
GO
ALTER DATABASE [u_ploszczy] SET  READ_WRITE 
GO
