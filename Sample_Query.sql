--Sample Queries

--Insert data into the Attendance table using Bulk insert command
BULK INSERT Attendance 
FROM "C:\Users\Saravanan\Attendancedata.csv"
WITH (
FIELDTERMINATOR=',',
ROWTERMINATOR='\n',
FIRSTROW=2
);

--Using Staging Table to insert data into the Payroll table
CREATE TABLE Payroll_Staging
(EmployeeID INT NOT NULL,
PayDate DATE DEFAULT GETDATE(),
CONSTRAINT EmployeePayStagefk FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)); 

--Bulk insert into Staging
BULK INSERT Payroll_Staging 
FROM "C:\Users\Saravanan\Payrolldata.csv"
WITH (
FIELDTERMINATOR=',',
ROWTERMINATOR='\n',
FIRSTROW=2
);
SELECT * FROM Payroll_Staging;

--Insert into real table
INSERT INTO Payroll(EmployeeID,TotalHours,TaxRate,PayDate)
SELECT EmployeeID,TotalHours,GrossPay,TaxRate,TaxAmount,NetPay,PayDate 
FROM Payroll_Staging;

SELECT * FROM Payroll; 

--Views
--Creating view for gross pay to simplify complex queries
CREATE VIEW GrossPayView AS
SELECT 
e.FirstName,e.EmployeeID,e.HourlyWage,SUM(a.HoursWorked) AS TotalHours,
(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay 
FROM Attendance a 
JOIN Employee e ON a.EmployeeID=e.EmployeeID 
GROUP BY e.FirstName,e.EmployeeID,e.HourlyWage;
 
 SELECT * FROM GrossPayView;

--Triggers(Automation)
--Auto-calculate NetPay when inserting Payroll
CREATE TRIGGER trg_CalculateNetPay
ON Payroll                                          --Trigger activates when an insert happens on payroll
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
FROM inserted;  
END;                                     --Temporary table(holds the data user is trying to insert)

--Testing Trigger by inserting row into the Payroll table
INSERT INTO Payroll(EmployeeID,TaxRate,TotalHours,GrossPay) VALUES (1,10,40,1500);
SELECT * FROM Payroll;                    --NetPay,TaxAmount is automatically created by the trigger

--Stored Procedure
CREATE PROCEDURE GeneratePayroll
AS
BEGIN 
INSERT INTO Payroll(EmployeeID,TaxRate,TotalHours,GrossPay,TaxAmount,NetPay)
SELECT a.EmployeeID,10,SUM(ISNULL(a.HoursWorked,0)), 
SUM(ISNULL(a.HoursWorked,0) * e.HourlyWage),
SUM(ISNULL(a.HoursWorked,0) * e.HourlyWage)*0.10,
SUM(ISNULL(a.HoursWorked,0) * e.HourlyWage)*0.90
FROM Employee e
LEFT JOIN Attendance a ON e.EmployeeID=a.EmployeeID 
GROUP BY a.EmployeeID;
END;
GO

--Run the above stored procedure
EXEC GeneratePayroll;
GO

--Check if the payroll table is updated
SELECT * FROM Payroll;
GO
