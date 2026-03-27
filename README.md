# MS_SQL_SERVER_EmployeePayrollSystem
### Employee Payroll System (SQL Server)


##  📌 Project Overview

The Employee Payroll System is a database-driven project developed using Microsoft SQL Server. It is designed to manage employee details, attendance records, and salary processing efficiently.
This system automates payroll calculations including gross pay, tax deductions, and net salary using SQL queries, stored procedures, and triggers.

## 🎯 Objectives
• Store and manage employee information<br>
• Track employee attendance and working hours<br>
• Automatically calculate payroll<br>
• Ensure data integrity using transactions<br>
• Demonstrate SQL concepts like joins, triggers, procedures, and indexing<br>


## Technologies Used
• Microsoft SQL Server<br>
• SQL (Structured Query Language)<br>

## Database Structure

### 1. Employees Table
Stores employee details.
Columns:<br>
• EmployeeID (Primary Key)<br>
• Name<br>
• Department<br>
• HourlyRate<br>

### 2. Attendance Table
Stores daily work hours.
Columns:<br>
• AttendanceID (Primary Key)<br>
• EmployeeID (Foreign Key)<br>
• Date<br>
• HoursWorked<br>

### 3. Payroll Table
Stores salary details.
Columns:<br>
• PayrollID (Primary Key)<br>
• EmployeeID (Foreign Key)<br>
• TotalHours<br>
• GrossPay<br>
• TaxRate<br>
• TaxAmount<br>
• NetPay<br>
• PayDate<br>

### 4.Departments Table
Stores employee and their corresponding Department details.
Columns:<br>
• DepartmentID<br>
• DepartmentName<br>


## Key Concepts Covered
### Payroll Calculation

Payroll is calculated using:<br>
• Total Hours from Attendance<br>
• Hourly Rate from Employees<br>
• Tax deduction (e.g., 10%)<br>

Payroll Calculation Logic<br>
• Gross Pay = Hours Worked × Hourly Wage<br>
• Tax = 10% of (Gross Pay)<br>
• Net Pay = Gross Pay - Tax<br>


## Stored Procedure
GeneratePayroll<br>
• Calculates salary for all employees<br>
• Inserts results into Payroll table<br>



## Trigger
TRG_UpdatePayroll<br>
• Automatically updates total hours when attendance is inserted<br>

## Transactions
Ensures safe execution:<br>
• BEGIN TRANSACTION<br>
• COMMIT (if success)<br>
• ROLLBACK (if error)<br>

## Sample Queries:
### Query to show how gross pay is calculated
SELECT e.FirstName,e.EmployeeID,e.HourlyWage,SUM(a.HoursWorked) AS TotalHours,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay FROM Attendance a JOIN Employee e ON a.EmployeeID=e.EmployeeID GROUP BY e.FirstName,e.EmployeeID,e.HourlyWage;
GO

### Output:
|FirstName	|EmployeeID	|HourlyWage	|TotalHours	|GrossPay|
|------------|----------|-----------|-----------|--------|
|John|	1|	45.00	|50.00|	2250.0000|
|Emma|	2	|40.00	|40.00	|1600.0000|
|Michael|	3	|30.00	|44.00	|1320.0000|
|Sophia	|4	|35.00|	45.00	|1575.0000|
|Daniel	|5|	28.00|	46.00	|1288.0000|
|Olivia	|6	|32.00|	42.00	|1344.0000|
|James	|7	|27.00|	44.00|	1188.0000|
|Isabella|	8|	33.00	|44.00|	1452.0000|
|Siddharth	|9	|55.00	|55.00	|3025.0000|
|Mia	|10	|32.00	|46.00	|1472.0000|

## Tax Calculations
### TaxAmount= GrossPay * TaxRate /100
SELECT a.EmployeeID,p.TaxRate,e.HourlyWage,SUM(a.HoursWorked) AS TotalHours,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay,(((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100 AS TaxAmount FROM Attendance a JOIN Employee e ON a.EmployeeID=e.EmployeeID JOIN Payroll p ON e.EmployeeID=p.EmployeeID GROUP BY a.EmployeeID,p.TaxRate,e.HourlyWage ;
GO

### Output:
|EmployeeID	|TaxRate	|HourlyWage	|TotalHours	|GrossPay	|TaxAmount|
|-----------|--------|-------------|----------|--------|----------|
|1|	10|	45.00|	200.00	|9000.0000	|900.000000|
|2|	10|	40.00	|120.00	|4800.0000	|480.000000|
|3|	10	|30.00	|132.00	|3960.0000	|396.000000|
|4	|10|	35.00	|135.00	|4725.0000	|472.500000|
|5	|10	|28.00	|138.00	|3864.0000	|386.400000|
|6	|10	|32.00	|126.00	|4032.0000	|403.200000|
|7|	10	|27.00	|132.00	|3564.0000	|356.400000|
|8	|10	|33.00	|132.00	|4356.0000	|435.600000|
|9	|10	|55.00	|165.00	|9075.0000	|907.500000|
|10	|10	|32.00	|138.00	|4416.0000	|441.600000|

## Query to calculate Net Pay
### Net pay=(Grosspay - TaxAmount)
SELECT a.EmployeeID,p.TaxRate,e.HourlyWage,(SUM(a.HoursWorked))*e.HourlyWage AS GrossPay,(((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100 AS TaxAmount, (((SUM(a.HoursWorked))*e.HourlyWage))-((((SUM(a.HoursWorked))*e.HourlyWage)*TaxRate )/100) AS NetPay FROM Attendance a JOIN Employee e ON a.EmployeeID=e.EmployeeID JOIN Payroll p ON e.EmployeeID=p.EmployeeID GROUP BY a.EmployeeID,p.TaxRate,e.HourlyWage ;
GO

### Output:
|EmployeeID	|TaxRate	|HourlyWage	|GrossPay	|TaxAmount	|NetPay|
|-----------|--------|-------------|----------|--------|----------|
|1	|10	|45.00	|9000.0000	|900.000000	|8100.0000|
|2	|10|	40.00|	4800.0000|	480.000000	|4320.0000|
|3	|10|	30.00|	3960.0000	|396.000000	|3564.0000|
|4	|10	|35.00	|4725.0000	|472.500000	|4252.5000|
|5	|10|	28.00|	3864.0000	|386.400000	|3477.6000|
|6|	10	|32.00	|4032.0000	|403.200000	|3628.8000|
|7	|10	|27.00	|3564.0000	|356.400000	|3207.6000|
|8	|10|	33.00|4356.0000	|435.600000	|3920.4000|
|9	|10	|55.00	|9075.0000|	907.500000	|8167.5000|
|10	|10	|32.00	|4416.0000	|441.600000	|3974.4000|

## Windows Functions
### Top 1 Employee per department
SELECT * FROM(
SELECT e.FirstName,e.LastName,d.DepartmentName, p.NetPay,
ROW_NUMBER() OVER(PARTITION BY d.DepartmentName ORDER BY p.NetPay DESC) AS SalaryRank
FROM Employee e JOIN Payroll p ON e.EmployeeID=p.EmployeeID JOIN Departments d  ON e.DepartmentID=d.DepartmentID
) t
WHERE SalaryRank <= 1;
GO   

### Output:
|FirstName	|LastName	|DepartmentName|	NetPay	|SalaryRank|
|-----------|--------|-------------|----------|--------|
|Emma	|Johnson	|Finance	|1440	|1|
|Sophia	|Davis|	Human Resources|	1418|	1|
|John|	Smith	|IT	|2025	|1|
|Siddharth	|Saravanan|	Operations|	2723	|1|
|Isabella	|Thomas|	Sales|	1307|	1|

### To find the Highest Paid Employee in the company(Both these queries provide same result)
SELECT EmployeeID,FirstName,LastName,NetPay FROM NetView1 WHERE NetPay = (SELECT MAX(NetPay) FROM NetView1);
GO
SELECT TOP 1 EmployeeID,FirstName,LastName, MAX(NetPay) AS HighestPaidEmployee FROM NetView1 GROUP BY EmployeeID,FirstName,LastName ORDER BY MAX(NetPay) DESC;
GO

### Output:
|EmployeeID	|FirstName	|LastName	|HighestPaidEmployee|
|-----------|-----------|-------------|----------------|
|9|	Siddharth|	Saravanan|	12870.0000|

## PayRoll Transaction
BEGIN TRANSACTION;<br>
BEGIN TRY<br>
--Insert Calculated Salary<br>
INSERT INTO Payroll(EmployeeID,TaxRate,TotalHours,GrossPay,TaxAmount,NetPay,PayDate)<br>
SELECT <br>
e.EmployeeID,10,SUM(a.HoursWorked),<br>
SUM(a.HoursWorked*e.HourlyWage),<br>
SUM(a.HoursWorked*e.HourlyWage)*0.10,<br>
SUM(a.HoursWorked*e.HourlyWage)*0.90,<br>
GETDATE()<br>
FROM Employee e<br>
JOIN Attendance a ON e.EmployeeID=a.EmployeeID<br>
GROUP BY e.EmployeeID;<br>
--If everything works<br>
COMMIT;<br>
PRINT 'Transaction Successful';<br>
END TRY<br>
BEGIN CATCH<br>
--If any error happens<br>
ROLLBACK;--All changes are undone<br>
PRINT 'Transaction Failed';<br>
END CATCH;<br>
GO   <br>

### Output:
(10 row(s) affected)<br>
Transaction Successful<br>

## Real-World Use Cases
• HR payroll processing systems<br>
• Salary and tax calculation<br>
• Employee attendance tracking<br>
• Financial reporting<br>

## How to Run the Project
1. Create database in SQL Server<br>
2. Run:<br>
• Tables.sql<br>
• SampleData.sql<br>
• StoredProcedures.sql<br>
• Views.sql<br>
• Triggers.sql<br>

## Author
Developed as a hands-on SQL Server project to demonstrate real-world payroll system design and database concepts. <br>
-Sowndarya Vasan
