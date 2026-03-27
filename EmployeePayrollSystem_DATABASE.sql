--EmployeePayrollSysytem Database Script
--DATABASE : EmployeePayroll
 
use EmployeePayroll;

--Create database
CREATE DATABASE EmployeePayroll;
GO

--Create table Employee
CREATE TABLE Employee(
EmployeeID INT PRIMARY KEY IDENTITY(1,1),
FirstName VARCHAR(50),
LastName VARCHAR(50),
DepartmentID INT, 
HireDate DATE,
HourlyWage DECIMAL(10,2),
IsActive BIT DEFAULT 1    --BIT datatype stores only two values 1,0
);
GO

--Create table Departments
CREATE TABLE Departments(
DepartmentID INT PRIMARY KEY IDENTITY(1,1),
DepartmentName VARCHAR(100)
);
GO

--Create table Attendance
CREATE TABLE Attendance (
AttendanceID INT PRIMARY KEY IDENTITY(1,1),
EmployeeID INT,
WorkDate DATE,
HoursWorked DECIMAL(5,2),
CONSTRAINT Employeefk FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)); 
GO

--Create table Payroll
CREATE TABLE Payroll(
PayrollID INT PRIMARY KEY IDENTITY(1,1),
EmployeeID INT NOT NULL,
PayDate DATE DEFAULT GETDATE(),
CONSTRAINT EmployeePayfk FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID));  --Ensures referential integrity, ensuring only valid employees are included
GO

/***Importing data using bcp command for Employee table
bcp EmployeePayroll.dbo.Employee in "c:\Users\Sarvanan\Employeedata.csv" -c -t, -T -S SS-PC\SQLEXPRESS
***/

--Check if data is inserted into the table using Select command on Employee table
SELECT * FROM Employee;
GO

--Insert data into the Department table using Bulk insert command
SET IDENTITY_INSERT Departments ON;  --Allow me to manually insert values into the identity column for this table
BULK INSERT Departments 
FROM "C:\Users\Saravanan\Departmentdata.csv"
WITH (
FIELDTERMINATOR=',',
ROWTERMINATOR='\n',
FIRSTROW=2
);
SET IDENTITY_INSERT Departments OFF;
GO

SELECT * FROM Departments;
GO

--Insert data into the Attendance table using Bulk insert command
BULK INSERT Attendance 
FROM "C:\Users\Saravanan\Attendancedata.csv"
WITH (
FIELDTERMINATOR=',',
ROWTERMINATOR='\n',
FIRSTROW=2
);
GO
SELECT * FROM Attendance;
GO

--Using Staging Table to insert data into the Payroll table
--In order to do that create PayrollStaging table
CREATE TABLE Payroll_Staging
(EmployeeID INT NOT NULL,
PayDate DATE DEFAULT GETDATE(),
CONSTRAINT EmployeePayStagefk FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)); 
GO

--Bulk insert into Staging
BULK INSERT Payroll_Staging 
FROM "C:\Users\Saravanan\Payrolldata.csv"
WITH (
FIELDTERMINATOR=',',
ROWTERMINATOR='\n',
FIRSTROW=2
);
GO
SELECT * FROM Payroll_Staging;
GO

--Insert into real table
INSERT INTO Payroll(EmployeeID,TotalHours,TaxRate,PayDate)
SELECT EmployeeID,TotalHours,GrossPay,TaxRate,TaxAmount,NetPay,PayDate FROM Payroll_Staging;
GO

SELECT * FROM Payroll; --PayrollID starts with 2 instead of 1 because of an insert fail first time
--If you want to RESET the IDENTITY back to 1 then, you can use TRUNCATE TABLE command which is used to remove all rows from a table.
TRUNCATE TABLE Payroll;
GO

--Now add data again into the Payroll table
INSERT INTO Payroll(EmployeeID,TotalHours,GrossPay,TaxRate,TaxAmount,NetPay,PayDate)
SELECT EmployeeID,TotalHours,GrossPay,TaxRate,TaxAmount,NetPay,PayDate FROM Payroll_Staging;
GO

SELECT * FROM Payroll; --Now it shows PayrollID 1.
GO

--Sample queries
--View all employees
SELECT * FROM Employee;
GO

--View all Departments
SELECT * FROM Departments;
GO

--View Payroll Records
SELECT * FROM Payroll;
GO

--View Attendance
SELECT * FROM Attendance;
GO

--Update Query
ALTER TABLE Payroll ADD PayDate DATE;
UPDATE Payroll SET PayDate ='2026-04-04';
GO

--Join Queries
--Query to show employees grouped by department
SELECT e.EmployeeID,e.FirstName,e.LastName,d.DepartmentName FROM  Employee e JOIN Departments d  ON e.DepartmentID=d.DepartmentID ORDER BY d.DepartmentName;
GO

--Query to show each department with all of its employees combined into one row as a comma-seperated list
SELECT d.DepartmentName, STRING_AGG(e.FirstName,',') FROM Departments d LEFT JOIN Employee e ON d.DepartmentID=e.DepartmentID GROUP BY d.DepartmentName;
GO

--Query to show employees and their payroll information
SELECT e.EmployeeID, e.FirstName,e.LastName,p.GrossPay,P.NetPay,P.PayDate FROM Employee e JOIN Payroll p ON e.EmployeeID=p.EmployeeID;
GO

--Query to show Full Payroll details
SELECT e.FirstName,e.LastName,p.TotalHours,p.GrossPay,p.NetPay,p.PayDate FROM Payroll p JOIN Employee e ON p.EmployeeID=e.EmployeeID JOIN Departments d ON e.DepartmentID=d.DepartmentID;
GO

--Sample queries to show how gross pay is calculated
SELECT e.FirstName,e.EmployeeID,e.HourlyWage,SUM(a.HoursWorked) AS TotalHours,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay FROM Attendance a JOIN Employee e ON a.EmployeeID=e.EmployeeID GROUP BY e.FirstName,e.EmployeeID,e.HourlyWage;
GO

--Tax Calculations
--TaxAmount= GrossPay * TaxRate /100
SELECT a.EmployeeID,p.TaxRate,e.HourlyWage,SUM(a.HoursWorked) AS TotalHours,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay,(((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100 AS TaxAmount FROM Attendance a JOIN Employee e ON a.EmployeeID=e.EmployeeID JOIN Payroll p ON e.EmployeeID=p.EmployeeID GROUP BY a.EmployeeID,p.TaxRate,e.HourlyWage ;
GO

--Query to calculate Net Pay
-- Net pay=(Grosspay - TaxAmount)
SELECT a.EmployeeID,p.TaxRate,e.HourlyWage,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay,(((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100 AS TaxAmount, (((SUM(a.HoursWorked))*e.HourlyWage))-((((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100) AS NetPay FROM Attendance a JOIN Employee e ON a.EmployeeID=e.EmployeeID JOIN Payroll p ON e.EmployeeID=p.EmployeeID GROUP BY a.EmployeeID,p.TaxRate,e.HourlyWage ;
GO

--Views
--Creating view for gross pay to simplify complex queries
CREATE VIEW GrossPayView AS
SELECT 
e.FirstName,e.EmployeeID,e.HourlyWage,SUM(a.HoursWorked) AS TotalHours,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay 
FROM Attendance a 
JOIN Employee e ON a.EmployeeID=e.EmployeeID 
GROUP BY e.FirstName,e.EmployeeID,e.HourlyWage;
GO
SELECT * FROM GrossPayView;
GO

--Create view for TaxAmount
CREATE VIEW TaxView AS
SELECT a.EmployeeID,p.TaxRate,e.HourlyWage,SUM(a.HoursWorked) AS TotalHours,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay,(((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100 AS TaxAmount 
FROM Attendance a 
JOIN Employee e ON a.EmployeeID=e.EmployeeID 
JOIN Payroll p ON e.EmployeeID=p.EmployeeID 
GROUP BY a.EmployeeID,p.TaxRate,e.HourlyWage ;
GO
SELECT * FROM TaxView;
GO

--Create view for NetPay
CREATE VIEW NetView AS
SELECT a.EmployeeID,p.TaxRate,e.HourlyWage,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay,(((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100 AS TaxAmount, (((SUM(a.HoursWorked))*e.HourlyWage))-((((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100) AS NetPay 
FROM Attendance a 
JOIN Employee e ON a.EmployeeID=e.EmployeeID 
JOIN Payroll p ON e.EmployeeID=p.EmployeeID 
GROUP BY a.EmployeeID,p.TaxRate,e.HourlyWage ;
GO

CREATE VIEW NetView1 AS
SELECT a.EmployeeID,e.FirstName,e.LastName,p.TaxRate,e.HourlyWage,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay,(((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100 AS TaxAmount, (((SUM(a.HoursWorked))*e.HourlyWage))-((((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100) AS NetPay 
FROM Attendance a 
JOIN Employee e ON a.EmployeeID=e.EmployeeID 
JOIN Payroll p ON e.EmployeeID=p.EmployeeID 
GROUP BY a.EmployeeID,e.FirstName,e.LastName,p.TaxRate,e.HourlyWage ;
GO
SELECT * FROM NetView;
GO

--Aggregate Queries
--Total Salary paid by Company
SELECT SUM(NetPay) AS TotalSalaries FROM NetView;
GO
--To find out Average Salary
SELECT AVG(NetPay) AS AvgSalary FROM NetView;
GO

--To find the Highest Paid Employee in the company(Both these queries provide same result)
SELECT EmployeeID,FirstName,LastName,NetPay FROM NetView1 WHERE NetPay = (SELECT MAX(NetPay) FROM NetView1);
GO
SELECT TOP 1 EmployeeID,FirstName,LastName, MAX(NetPay) AS HighestPaidEmployee FROM NetView1 GROUP BY EmployeeID,FirstName,LastName ORDER BY MAX(NetPay) DESC;
GO

--Salary by Department
CREATE VIEW DepartmentSalaryView AS
SELECT d.DepartmentName, a.EmployeeID,p.TaxRate,e.HourlyWage,(((SUM(a.HoursWorked))*e.HourlyWage))-((((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100) AS TotalSalary FROM Attendance a JOIN Employee e ON a.EmployeeID=e.EmployeeID
JOIN Payroll p ON e.EmployeeID=p.EmployeeID JOIN Departments d ON e.DepartmentID=d.DepartmentID GROUP BY a.EmployeeID,p.TaxRate,e.HourlyWage,d. DepartmentName;
GO
SELECT DepartmentName, SUM(TotalSalary) AS TotalSalaryByDepartment FROM DepartmentSalaryView GROUP BY DepartmentName;
GO

--Employees with no attendance
SELECT e.FirstName,e.LastName FROM Employee e LEFT JOIN Attendance a ON e.EmployeeID=a.EmployeeID WHERE a.AttendanceID IS NULL;
GO

--Rank Employees by Salary
--Apply Window Function to NetView1 
SELECT FirstName,LastName,NetPay,
RANK() OVER (ORDER BY NetPay DESC) AS SalaryRank
FROM NetView1;
GO

--Create table Payroll(Dropped and Created the payroll table again to check and test stored procedure)
CREATE TABLE Payroll(
PayrollID INT PRIMARY KEY IDENTITY(1,1),
EmployeeID INT NOT NULL,
TaxRate DECIMAL(5,0),
TotalHours DECIMAL(10,0),
GrossPay DECIMAL(10,0)
,TaxAmount DECIMAL(5,0)
,NetPay DECIMAL(10,0),
CONSTRAINT EmployeePayfk FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID));  --Ensures referential integrity, ensuring only valid employees are included
GO

--Stored Procedure
CREATE PROCEDURE GeneratePayroll
AS
BEGIN 
INSERT INTO Payroll(EmployeeID,TaxRate,TotalHours,GrossPay,TaxAmount,NetPay)
SELECT a.EmployeeID,10,SUM(ISNULL(a.HoursWorked,0)), SUM(ISNULL(a.HoursWorked,0) * e.HourlyWage),SUM(ISNULL(a.HoursWorked,0) * e.HourlyWage)*0.10,SUM(ISNULL(a.HoursWorked,0) * e.HourlyWage)*0.90
FROM Employee e LEFT JOIN Attendance a ON e.EmployeeID=a.EmployeeID GROUP BY a.EmployeeID;
END;
GO

--Run the above stored procedure
EXEC GeneratePayroll;
GO

--Check if the payroll table is updated
SELECT * FROM Payroll;
GO

--Constraints(Data Validation)
--Ensure Salary and Hours are valid
ALTER TABLE Employee 
ADD CONSTRAINT CHK_HourlyWage
CHECK (HourlyWage>0);
GO

ALTER TABLE Attendance 
ADD CONSTRAINT CHK_HoursWorked
CHECK (HoursWorked BETWEEN 0 AND 24);
GO

--Ensure NetPay is not Negative
ALTER TABLE Payroll
ADD CONSTRAINT CHK_NetPay
CHECK (NetPay>=0);
GO

--Indexes
DELETE FROM Payroll WHERE PayrollID BETWEEN 11 AND 20;
GO
SELECT * FROM Payroll;
GO

--Index on EmployeeID
CREATE INDEX idx_employee_payroll  
ON Payroll(EmployeeID);
GO

--Testing
--Check Execution Plan
SET STATISTICS PROFILE ON;                           --To check index is used Efficiently or not
SELECT EmployeeID FROM Payroll WHERE EmployeeID=1;   --It shows Index Seek(Index used Efficiently)
GO

--Index on PayDate(for reports)
CREATE INDEX idx_paydate
ON Payroll(PayDate);                                 --It shows Index scan(Index not used Efficiently)
GO

--Triggers(Automation)
--Auto-calculate NetPay when inserting Payroll
CREATE TRIGGER trg_CalculateNetPay                   --Trigger activates when an insert happens on payroll
ON Payroll                                
INSTEAD OF INSERT  
AS 
BEGIN
INSERT INTO Payroll(EmployeeID,TaxRate,TotalHours,GrossPay,TaxAmount,NetPay,PayDate)
SELECT
EmployeeID,
10,
TotalHours,
GrossPay,
GrossPay * 0.10,
GrossPay -(GrossPay * 0.10),
'2026-04-04'
FROM inserted;  --Temporary table(holds the data user is trying to insert)
END;            
GO

--Testing Trigger by inserting row into the Payroll table
INSERT INTO Payroll(EmployeeID,TaxRate,TotalHours,GrossPay)VALUES (1,10,40,1500);   --NetPay,TaxAmount is automatically created by the trigger
GO
SELECT * FROM Payroll; 
GO                  

--Trigger for Attendance(Payroll)
--Auto Update Payroll when Attendance is added
CREATE TRIGGER TRG_UpdatePayroll
ON Attendance
AFTER INSERT
AS
BEGIN
UPDATE p 
SET TotalHours=TotalHours+i.HoursWorked      --It adds the new workd hours to the existing TotalHours
FROM Payroll p JOIN inserted i ON p.EmployeeID=i.EmployeeID;
END;
GO   

--Testing Trigger by inserting row into the Attendance Table
INSERT INTO Attendance(EmployeeID,WorkDate,HoursWorked) VALUES (1,'2026-03-28',7);
GO   
INSERT INTO Attendance(EmployeeID,WorkDate,HoursWorked) VALUES (9,'2026-03-28',10);
GO   
SELECT * FROM Attendance;
GO   
--Check if the data is updated in the payroll table
SELECT * FROM Payroll;
GO
   
--Windows Functions
--Rank Employees By Salary
SELECT e.FirstName,e.LastName,p.NetPay,
RANK() OVER (ORDER BY p.NetPay DESC) AS SalaryRank
FROM Employee e JOIN Payroll p ON e.EmployeeID=p.EmployeeID;
GO   

--Unique Ranking Using ROW_NUMBER()
SELECT e.FirstName,e.LastName,p.NetPay,
ROW_NUMBER() OVER (ORDER BY p.NetPay DESC) AS SalaryRank
FROM Employee e JOIN Payroll p ON e.EmployeeID=p.EmployeeID;
GO   

--Top 3 Highest Paid Employees
SELECT * FROM (
 SELECT e.FirstName,e.LastName,p.NetPay,
RANK() OVER (ORDER BY p.NetPay DESC) AS SalaryRank
FROM Employee e JOIN Payroll p ON e.EmployeeID=p.EmployeeID
) t
WHERE SalaryRank <= 3;
GO   

--Top 1 Employee per department
SELECT * FROM(
SELECT e.FirstName,e.LastName,d.DepartmentName, p.NetPay,
ROW_NUMBER() OVER(PARTITION BY d.DepartmentName ORDER BY p.NetPay DESC) AS SalaryRank
FROM Employee e JOIN Payroll p ON e.EmployeeID=p.EmployeeID JOIN Departments d  ON e.DepartmentID=d.DepartmentID
) t
WHERE SalaryRank <= 1;
GO   

--PayRoll Transaction
BEGIN TRANSACTION;
BEGIN TRY
--Insert Calculated Salary
INSERT INTO Payroll(EmployeeID,TaxRate,TotalHours,GrossPay,TaxAmount,NetPay,PayDate)
SELECT 
e.EmployeeID,10,SUM(a.HoursWorked),
SUM(a.HoursWorked*e.HourlyWage),
SUM(a.HoursWorked*e.HourlyWage)*0.10,
SUM(a.HoursWorked*e.HourlyWage)*0.90,
GETDATE()
FROM Employee e
JOIN Attendance a ON e.EmployeeID=a.EmployeeID
GROUP BY e.EmployeeID;
--If everything works
COMMIT;
PRINT 'Transaction Successful';
END TRY
BEGIN CATCH
--If any error happens
ROLLBACK;--All changes are undone
PRINT 'Transaction Failed';
END CATCH;
GO   
