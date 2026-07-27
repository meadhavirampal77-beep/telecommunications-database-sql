# Creating Database
CREATE DATABASE db_telecom_provider;
USE db_telecom_provider;
# Creating tables associated within the database db_telecom_provider
----------------------------------------------------------------------------------
# Table Customer
CREATE TABLE Customer (
customer_id      INT AUTO_INCREMENT PRIMARY KEY,
first_name       VARCHAR(50) NOT NULL,
last_name        VARCHAR(50) NOT NULL,
email            VARCHAR(100) NOT NULL UNIQUE,
phone_number     VARCHAR(20),
customer_type    ENUM('PERSONAL', 'BUSINESS') NOT NULL DEFAULT 'PERSONAL',
date_joined      DATE NOT NULL,
status           ENUM('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE'
);

# Table Address
CREATE TABLE Address (
address_id     INT AUTO_INCREMENT PRIMARY KEY,
line1          VARCHAR(100) NOT NULL,
line2          VARCHAR(100),
city           VARCHAR(50) NOT NULL,
state_region   VARCHAR(50),
postal_code    VARCHAR(20),
country        VARCHAR(50) NOT NULL
);

# Table Plan
CREATE TABLE Plan (
plan_id          INT AUTO_INCREMENT PRIMARY KEY,
plan_name        VARCHAR(100) NOT NULL UNIQUE,
monthly_fee      DECIMAL(8,2) NOT NULL CHECK (monthly_fee >= 0),
voice_minutes    INT NOT NULL CHECK (voice_minutes >= 0),
data_limit_gb    DECIMAL(6,2) NOT NULL CHECK (data_limit_gb >= 0),
sms_limit        INT NOT NULL CHECK (sms_limit >= 0),
is_postpaid      BOOLEAN NOT NULL DEFAULT 1,
is_active        BOOLEAN NOT NULL DEFAULT 1
);

# Table Feature
CREATE TABLE Feature (
feature_id    INT AUTO_INCREMENT PRIMARY KEY,
feature_name  VARCHAR(100) NOT NULL UNIQUE,
description   VARCHAR(255)
);

# Table AddOn
CREATE TABLE AddOn (
addon_id       INT AUTO_INCREMENT PRIMARY KEY,
addon_name     VARCHAR(100) NOT NULL UNIQUE,
description    VARCHAR(255),
monthly_fee    DECIMAL(8,2) NOT NULL CHECK (monthly_fee >= 0),
is_recurring   BOOLEAN NOT NULL DEFAULT 1,
is_active      BOOLEAN NOT NULL DEFAULT 1
);

# Table Agent
CREATE TABLE Agent (
agent_id     INT AUTO_INCREMENT PRIMARY KEY,
first_name   VARCHAR(50) NOT NULL,
last_name    VARCHAR(50) NOT NULL,
email        VARCHAR(100) NOT NULL UNIQUE,
team_name    VARCHAR(50),
hire_date    DATE NOT NULL,
status       ENUM('ACTIVE', 'ON_LEAVE', 'LEFT') NOT NULL DEFAULT 'ACTIVE'
);
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# JUNCTION TABLES FOR M:N RELATIONSHIPS
# Customer_Address
CREATE TABLE Customer_Address (
customer_id   INT NOT NULL,
address_id    INT NOT NULL,
address_type  ENUM('BILLING', 'SERVICE', 'SHIPPING', 'OTHER') NOT NULL DEFAULT 'SERVICE',
is_primary    BOOLEAN NOT NULL DEFAULT 0,
PRIMARY KEY (customer_id, address_id, address_type),
FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
	ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (address_id) REFERENCES Address(address_id)
	ON DELETE CASCADE ON UPDATE CASCADE
);

# Plan_feature
CREATE TABLE Plan_Feature (
plan_id             INT NOT NULL,
feature_id          INT NOT NULL,
extra_monthly_fee   DECIMAL(8,2) NOT NULL DEFAULT 0 CHECK (extra_monthly_fee >= 0),
PRIMARY KEY (plan_id, feature_id),
FOREIGN KEY (plan_id) REFERENCES Plan(plan_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (feature_id) REFERENCES Feature(feature_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
# DEPENDENT TABLES
#Table Subscription
CREATE TABLE Subscription (
subscription_id   INT AUTO_INCREMENT PRIMARY KEY,
customer_id       INT NOT NULL,
plan_id           INT NOT NULL,
msisdn            VARCHAR(20) NOT NULL UNIQUE,
sim_number        VARCHAR(30),
start_date        DATE NOT NULL,
end_date          DATE,
status            ENUM('ACTIVE', 'SUSPENDED', 'CANCELLED') NOT NULL DEFAULT 'ACTIVE',
CHECK (end_date IS NULL OR end_date >= start_date),
FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
FOREIGN KEY (plan_id) REFERENCES Plan(plan_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

# Table Invoice
CREATE TABLE Invoice (
invoice_id           INT AUTO_INCREMENT PRIMARY KEY,
subscription_id      INT NOT NULL,
billing_period_start DATE NOT NULL,
billing_period_end   DATE NOT NULL,
issue_date           DATE NOT NULL,
due_date             DATE NOT NULL,
total_amount         DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
status               ENUM('ISSUED', 'PAID', 'OVERDUE', 'CANCELLED') NOT NULL DEFAULT 'ISSUED',
CHECK (billing_period_end >= billing_period_start),
CHECK (due_date >= issue_date),
FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
	ON DELETE RESTRICT ON UPDATE CASCADE
);

# Table Payment
CREATE TABLE Payment (
payment_id    INT AUTO_INCREMENT PRIMARY KEY,
invoice_id    INT NOT NULL,
payment_date  DATETIME NOT NULL,
amount        DECIMAL(10,2) NOT NULL CHECK (amount > 0),
method        ENUM('CARD', 'DIRECT_DEBIT', 'BANK_TRANSFER', 'CASH', 'ONLINE') NOT NULL,
status        ENUM('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'COMPLETED',
FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
	ON DELETE RESTRICT ON UPDATE CASCADE
);
# Table Call_Record
CREATE TABLE Call_Record (
call_id          INT AUTO_INCREMENT PRIMARY KEY,
subscription_id  INT NOT NULL,
call_timestamp   DATETIME NOT NULL,
duration_seconds INT NOT NULL CHECK (duration_seconds >= 0),
call_type        ENUM('OUTGOING', 'INCOMING') NOT NULL,
destination_number VARCHAR(20) NOT NULL,
charge_amount    DECIMAL(8,2) NOT NULL CHECK (charge_amount >= 0),
FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);
# Table Data_Session
CREATE TABLE Data_Session (
session_id       INT AUTO_INCREMENT PRIMARY KEY,
subscription_id  INT NOT NULL,
session_start    DATETIME NOT NULL,
session_end      DATETIME NOT NULL,
mb_used          DECIMAL(12,3) NOT NULL CHECK (mb_used >= 0),
charge_amount    DECIMAL(8,2) NOT NULL CHECK (charge_amount >= 0),
CHECK (session_end >= session_start),
FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
	ON DELETE CASCADE ON UPDATE CASCADE
);
# Table Support_Ticket
CREATE TABLE Support_Ticket (
ticket_id       INT AUTO_INCREMENT PRIMARY KEY,
subscription_id INT,
created_at      DATETIME NOT NULL,
closed_at       DATETIME,
issue_type      ENUM('BILLING', 'NETWORK', 'TECHNICAL', 'GENERAL', 'OTHER') NOT NULL,
priority        ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL DEFAULT 'MEDIUM',
status          ENUM('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED') NOT NULL DEFAULT 'OPEN',
short_summary   VARCHAR(255) NOT NULL,
description     TEXT,
CHECK (closed_at IS NULL OR closed_at >= created_at),
FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
	ON DELETE SET NULL ON UPDATE CASCADE
);
-------------------------------------------------------------------------------------------------------------------------------------------------------------
#JUNCTION TABLES DEPENDENT
# Table Subscription_AddOn
CREATE TABLE Subscription_AddOn (
subscription_id INT NOT NULL,
addon_id        INT NOT NULL,
start_date      DATE NOT NULL,
end_date        DATE,
CHECK (end_date IS NULL OR end_date >= start_date),
PRIMARY KEY (subscription_id, addon_id, start_date),
FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
	ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (addon_id) REFERENCES AddOn(addon_id)
	ON DELETE RESTRICT ON UPDATE CASCADE
);
# Ticket_Agent
CREATE TABLE Ticket_Agent (
ticket_id      INT NOT NULL,
agent_id       INT NOT NULL,
assigned_at    DATETIME NOT NULL,
role           ENUM('PRIMARY', 'SECONDARY', 'ESCALATION') NOT NULL,
PRIMARY KEY (ticket_id, agent_id),
FOREIGN KEY (ticket_id) REFERENCES Support_Ticket(ticket_id)
	ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (agent_id) REFERENCES Agent(agent_id)
	ON DELETE RESTRICT ON UPDATE CASCADE
);
---------------------------------------------------------------------TASK-2 DATA POPULATION--------------------------------------------------------------------------------------------
# Inserting data into Customer
INSERT INTO Customer (first_name, last_name, email, phone_number, customer_type, date_joined, status)
VALUES
('Anna', 'Schmidt', 'anna.schmidt@example.com', '+491701000001', 'PERSONAL', '2023-08-10', 'ACTIVE'),
('Lukas', 'Weber', 'lukas.weber@example.com', '+491701000002', 'PERSONAL', '2023-09-05', 'ACTIVE'),
('Meera', 'Patel', 'meera.patel@business.com', '+491701000003', 'BUSINESS', '2022-12-20', 'ACTIVE'),
('Omar', 'Khan', 'omar.khan@example.com', '+491701000004', 'PERSONAL', '2024-01-11', 'ACTIVE'),
('Sofia', 'Müller', 'sofia.mueller@example.com', '+491701000005', 'PERSONAL', '2023-03-03', 'ACTIVE'),
('Jonas', 'Schneider', 'jonas.schneider@business.com', '+491701000006', 'BUSINESS', '2021-11-15', 'ACTIVE'),
('Fatima', 'Ali', 'fatima.ali@example.com', '+491701000007', 'PERSONAL', '2024-02-28', 'ACTIVE'),
('Mark', 'Fischer', 'mark.fischer@example.com', '+491701000008', 'PERSONAL', '2023-06-30', 'INACTIVE');

# Inserting data into Address
INSERT INTO Address (line1, line2, city, state_region, postal_code, country)
VALUES
('Alexanderplatz 1', NULL, 'Berlin', 'Berlin', '10178', 'Germany'),
('Kurfürstendamm 10', 'Apt 2', 'Berlin', 'Berlin', '10707', 'Germany'),
('Marienplatz 3', NULL, 'Munich', 'Bavaria', '80331', 'Germany'),
('Friedrichstraße 50', NULL, 'Berlin', 'Berlin', '10117', 'Germany'),
('Business Park 5', 'Building B', 'Hamburg', 'Hamburg', '20095', 'Germany'),
('Heidestraße 12', NULL, 'Hanover', 'Lower Saxony', '30161', 'Germany');

# Inserting data into Plan
INSERT INTO Plan (plan_name, monthly_fee, voice_minutes, data_limit_gb, sms_limit, is_postpaid, is_active)
VALUES
('Basic 5GB', 14.99, 200, 5.00, 100, 1, 1),
('Standard 20GB', 29.99, 500, 20.00, 500, 1, 1),
('Unlimited 100GB', 49.99, 9999, 100.00, 9999, 1, 1),
('Business Pro', 79.99, 9999, 200.00, 9999, 1, 1),
('PayG 1GB', 4.99, 50, 1.00, 50, 0, 1),
('Family 50GB', 59.99, 2000, 50.00, 2000, 1, 1);

# Inserting data into Feature
INSERT INTO Feature (feature_name, description)
VALUES
('5G Access', 'Access to 5G network where available'),
('International Roaming', 'Roaming in partner countries'),
('Music Streaming Pass', 'Zero-rated music streaming'),
('Priority Support', 'Faster support response'),
('Tethering', 'Use phone as hotspot'),
('VoLTE', 'Voice over LTE');

# Inserting data into ADDON
INSERT INTO AddOn (addon_name, description, monthly_fee, is_recurring, is_active)
VALUES
('Extra 5GB', 'Additional 5GB high-speed data', 9.99, 1, 1),
('Intl Calls 100', '100 minutes international calls', 14.99, 1, 1),
('Roaming Pack EU', 'Roaming in EU', 7.99, 1, 1),
('Music Pass', 'Zero-rated music apps', 3.99, 1, 1),
('Data Booster 1GB', 'One-time 1GB top-up', 2.99, 0, 1);

# Inserting data into Agent
INSERT INTO Agent (first_name, last_name, email, team_name, hire_date, status)
VALUES
('Sara', 'Becker', 'sara.becker@telecom.com', 'Billing Support', '2022-05-01', 'ACTIVE'),
('Jonas', 'Fischer', 'jonas.fischer@telecom.com', 'Network Support', '2023-03-15', 'ACTIVE'),
('Emily', 'Kovacs', 'emily.kovacs@telecom.com', 'Technical Support', '2021-09-20', 'ACTIVE'),
('Michael', 'Reed', 'michael.reed@telecom.com', 'Customer Relations', '2020-07-10', 'ACTIVE');

# Inserting data into CUSTOMER_ADDRESS - Junction Table
INSERT INTO Customer_Address (customer_id, address_id, address_type, is_primary)
VALUES
(1,1,'BILLING',1),(1,4,'SERVICE',0),
(2,2,'BILLING',1),(3,5,'BILLING',1),
(4,4,'BILLING',1),(5,1,'SERVICE',0),
(6,3,'BILLING',1),(7,6,'BILLING',1),
(8,2,'BILLING',1),(3,4,'SERVICE',0),
(2,1,'SERVICE',0),(5,2,'SHIPPING',0);

# INSERT DATA INTO PLAN_FEATURE
INSERT INTO Plan_Feature (plan_id, feature_id, extra_monthly_fee)
VALUES
(1,1,0),(2,1,0),(2,5,0),(3,1,0),
(3,4,0),(4,4,0),(4,2,10),(6,5,0),(6,3,0);

# INSERT DATA INTO SUBSCRIPTION
INSERT INTO Subscription (customer_id, plan_id, msisdn, sim_number, start_date, end_date, status)
VALUES
(1,2,'+491711000101','SIM-A-0001','2023-09-10',NULL,'ACTIVE'),
(1,5,'+491711000102','SIM-A-0002','2024-02-15',NULL,'ACTIVE'),
(2,1,'+491711000103','SIM-A-0003','2023-10-01',NULL,'ACTIVE'),
(3,4,'+491711000104','SIM-A-0004','2022-12-21',NULL,'ACTIVE'),
(4,3,'+491711000105','SIM-A-0005','2024-01-12',NULL,'ACTIVE'),
(5,6,'+491711000106','SIM-A-0006','2023-04-01',NULL,'ACTIVE'),
(6,4,'+491711000107','SIM-A-0007','2021-11-20',NULL,'ACTIVE'),
(7,2,'+491711000108','SIM-A-0008','2024-03-05',NULL,'ACTIVE'),
(8,1,'+491711000109','SIM-A-0009','2023-07-01',NULL,'CANCELLED'),
(3,6,'+491711000110','SIM-A-0010','2024-04-10',NULL,'ACTIVE');

# INSERT INTO SUBSCRIPTION_ADDON
INSERT INTO Subscription_AddOn (subscription_id, addon_id, start_date, end_date)
VALUES
(21,1,'2024-03-10',NULL),
(21,4,'2024-03-10',NULL),
(22,5,'2024-02-15','2024-03-15'),
(23,1,'2024-01-05',NULL),
(24,2,'2024-01-20',NULL),
(25,3,'2024-02-01',NULL),
(26,4,'2024-03-01',NULL),
(27,2,'2024-03-10',NULL),
(30,1,'2024-04-15',NULL),
(28,3,'2024-04-01',NULL);

# INSERT INTO INVOICE
INSERT INTO Invoice (subscription_id, billing_period_start, billing_period_end, issue_date, due_date, total_amount, status)
VALUES
(21,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',39.98,'ISSUED'),
(22,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',4.99,'PAID'),
(23,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',24.98,'PAID'),
(24,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',89.99,'ISSUED'),
(25,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',59.99,'PAID'),
(26,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',79.99,'PAID'),
(27,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',89.99,'OVERDUE'),
(28,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',29.99,'ISSUED'),
(29,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',14.99,'PAID'),
(30,'2024-03-01','2024-03-31','2024-04-02','2024-04-20',59.99,'ISSUED');

SELECT invoice_id, subscription_id FROM Invoice;
# INSERT INTO PAYMENT
INSERT INTO Payment (invoice_id, payment_date, amount, method, status)
VALUES
(2,'2024-04-10 09:30:00',4.99,'CARD','COMPLETED'),
(3,'2024-04-09 14:05:00',24.98,'DIRECT_DEBIT','COMPLETED'),
(5,'2024-04-12 10:00:00',59.99,'CARD','COMPLETED'),
(6,'2024-04-11 11:20:00',79.99,'BANK_TRANSFER','COMPLETED'),
(9,'2024-04-15 15:45:00',14.99,'ONLINE','COMPLETED'),
(1,'2024-04-15 10:00:00',19.99,'CARD','COMPLETED'),
(1,'2024-04-19 16:22:00',19.99,'CARD','COMPLETED'),
(7,'2024-04-25 09:00:00',20.00,'CARD','PENDING'),
(4,'2024-04-18 13:00:00',40.00,'CARD','PENDING'),
(10,'2024-04-20 08:30:00',59.99,'DIRECT_DEBIT','COMPLETED');

# Insert into Call_Record
INSERT INTO Call_Record (subscription_id, call_timestamp, duration_seconds, call_type, destination_number, charge_amount)
VALUES
(21,'2024-03-12 08:15:00',120,'OUTGOING','+491739999001',0.50),
(21,'2024-03-15 18:40:00',60,'INCOMING','+491701111111',0.00),
(23,'2024-03-10 09:05:00',300,'OUTGOING','+491739999002',1.25),
(24,'2024-03-20 12:00:00',45,'OUTGOING','+441632960960',0.80),
(25,'2024-03-22 14:22:00',600,'OUTGOING','+491739999003',2.50),
(26,'2024-03-28 07:50:00',30,'INCOMING','+491701111112',0.00),
(27,'2024-03-30 20:10:00',200,'OUTGOING','+491739999004',0.90),
(28,'2024-03-05 11:05:00',15,'OUTGOING','+491739999005',0.10),
(22,'2024-03-18 16:00:00',90,'OUTGOING','+491739999006',0.60),
(30,'2024-04-11 19:20:00',450,'OUTGOING','+491739999007',1.80);

# Insert data into Data_Session
INSERT INTO Data_Session (subscription_id, session_start, session_end, mb_used, charge_amount)
VALUES
(21,'2024-03-12 09:00:00','2024-03-12 09:20:00',150.750,0.80),
(22,'2024-03-25 12:00:00','2024-03-25 12:30:00',600.500,2.50),
(23,'2024-03-05 07:15:00','2024-03-05 07:45:00',1024.000,4.00),
(24,'2024-03-10 13:00:00','2024-03-10 13:10:00',80.250,0.30),
(25,'2024-03-21 20:00:00','2024-03-21 20:40:00',2048.125,8.00),
(26,'2024-03-11 09:00:00','2024-03-11 09:05:00',10.000,0.05),
(27,'2024-03-12 22:00:00','2024-03-12 22:30:00',500.000,2.00),
(28,'2024-03-01 18:00:00','2024-03-01 18:05:00',5.125,0.02),
(30,'2024-04-12 10:00:00','2024-04-12 11:00:00',1200.500,5.00),
(21,'2024-04-01 14:00:00','2024-04-01 14:15:00',300.000,1.20);

# Insert data into Support_Ticket
INSERT INTO Support_Ticket (subscription_id, created_at, closed_at, issue_type, priority, status, short_summary, description)
VALUES
(21,'2024-03-15 11:00:00',NULL,'BILLING','HIGH','OPEN','Invoice seems too high','Customer reports invoice issue'),
(23,'2024-03-20 09:30:00','2024-03-22 14:00:00','NETWORK','MEDIUM','CLOSED','Intermittent data dropouts','Data service issues'),
(24,'2024-03-25 08:15:00',NULL,'TECHNICAL','HIGH','IN_PROGRESS','SIM activation issue','SIM did not activate'),
(27,'2024-04-01 10:00:00',NULL,'BILLING','LOW','OPEN','Roaming charge question','Customer unsure about fees'),
(26,'2024-03-28 14:00:00','2024-03-29 09:00:00','GENERAL','LOW','RESOLVED','Address update','Requested address change'),
(30,'2024-04-14 16:30:00',NULL,'BILLING','CRITICAL','OPEN','Invoice dispute','Business customer dispute');

# Insert data into Ticket_Agent
INSERT INTO Ticket_Agent (ticket_id, agent_id, assigned_at, role)
VALUES
(1,1,'2024-03-15 11:05:00','PRIMARY'),
(1,3,'2024-03-15 11:40:00','SECONDARY'),
(2,2,'2024-03-20 09:45:00','PRIMARY'),
(3,3,'2024-03-25 08:20:00','PRIMARY'),
(4,1,'2024-04-01 10:05:00','PRIMARY'),
(5,1,'2024-03-28 14:10:00','PRIMARY'),
(6,4,'2024-04-14 16:45:00','PRIMARY'),
(6,2,'2024-04-14 17:00:00','ESCALATION');
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SHOW TABLES;
select * from Customer;
select * from Plan;
SELECT subscription_id, customer_id, plan_id, msisdn, status 
FROM Subscription;
---------------------------------------------------------SQL VIEWS------------------------------------------------------------------------------------------------------------------------------------
#  Creating the view Subscription_Revenue_Summary
CREATE OR REPLACE VIEW Subscription_Revenue_Summary AS
SELECT
s.subscription_id,
c.first_name,
c.last_name,
p.plan_name,
p.monthly_fee AS plan_fee,
COALESCE(SUM(a.monthly_fee), 0) AS addon_fees,
(p.monthly_fee + COALESCE(SUM(a.monthly_fee), 0)) AS expected_monthly_revenue
FROM Subscription s
JOIN Customer c ON s.customer_id = c.customer_id
JOIN Plan p ON s.plan_id = p.plan_id
LEFT JOIN Subscription_AddOn sa ON s.subscription_id = sa.subscription_id
LEFT JOIN AddOn a ON sa.addon_id = a.addon_id
GROUP BY s.subscription_id;

SELECT * FROM Subscription_Revenue_Summary;

# Creating the view Monthly_Invoice_Trend
CREATE OR REPLACE VIEW Monthly_Invoice_Trend AS
SELECT
DATE_FORMAT(issue_date, '%Y-%m') AS month,
SUM(total_amount) AS total_revenue
FROM Invoice
GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
ORDER BY month;

SELECT * FROM Monthly_Invoice_Trend;
--------------------------------------------------------------------------TASK3- Advanced SQL Queries for Analytics-----------------------------------------------------------------------
# Query1 : Top subscriptions by expected monthly revenue
-- 1. Top subscriptions by expected monthly revenue
SELECT s.subscription_id, c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, p.plan_name, p.monthly_fee, COALESCE(SUM(a.monthly_fee), 0) AS total_addon_fee,
(p.monthly_fee + COALESCE(SUM(a.monthly_fee),0)) AS expected_monthly_revenue,
CASE
	WHEN (p.monthly_fee + COALESCE(SUM(a.monthly_fee),0)) >= 50 THEN 'HIGH'
    WHEN (p.monthly_fee + COALESCE(SUM(a.monthly_fee),0)) BETWEEN 25 AND 49.99 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS revenue_segment
FROM Subscription s
JOIN Customer c ON s.customer_id = c.customer_id
JOIN Plan p ON s.plan_id = p.plan_id
LEFT JOIN Subscription_AddOn sa ON s.subscription_id = sa.subscription_id
LEFT JOIN AddOn a ON sa.addon_id = a.addon_id
GROUP BY s.subscription_id
HAVING expected_monthly_revenue > 0
ORDER BY expected_monthly_revenue DESC
LIMIT 10;
------------------------------------------------------------------------------------
# Query2: Monthly invoice revenue and 3-month moving average
WITH monthly AS (
SELECT DATE_FORMAT(issue_date, '%Y-%m-01') AS month_start, SUM(total_amount) AS total_revenue
FROM Invoice
GROUP BY month_start
)
SELECT month_start, total_revenue,
ROUND( AVG(total_revenue) OVER (ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS moving_avg_3m
FROM monthly
ORDER BY month_start;

# Query3 : Customer payment behaviour: payment rate and delinquent customers
SELECT
c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
COUNT(DISTINCT inv.invoice_id) AS total_invoices,
COALESCE(SUM(pay.amount), 0) AS total_paid,
ROUND(COALESCE(SUM(pay.amount),0) / NULLIF(SUM(inv.total_amount),0), 2) AS payment_rate,
CASE
    WHEN SUM(inv.total_amount) = 0 THEN 'NO_BILLING'
    WHEN COALESCE(SUM(pay.amount),0) / SUM(inv.total_amount) >= 0.9 THEN 'GOOD'
    WHEN COALESCE(SUM(pay.amount),0) / SUM(inv.total_amount) BETWEEN 0.5 AND 0.89 THEN 'AT_RISK'
    ELSE 'DELINQUENT'
  END AS payment_status,
  (SELECT MAX(payment_date) FROM Payment p2
     JOIN Invoice iv2 ON p2.invoice_id = iv2.invoice_id
     JOIN Subscription s2 ON iv2.subscription_id = s2.subscription_id
     WHERE s2.customer_id = c.customer_id
  ) AS last_payment_date
FROM Customer c
LEFT JOIN Subscription s ON c.customer_id = s.customer_id
LEFT JOIN Invoice inv ON s.subscription_id = inv.subscription_id
LEFT JOIN Payment pay ON inv.invoice_id = pay.invoice_id
GROUP BY c.customer_id
HAVING payment_status = 'DELINQUENT' OR payment_status = 'AT_RISK'
ORDER BY payment_rate ASC;

# Query4: Top agents by number of resolved tickets
SELECT sub.agent_id, CONCAT(a.first_name, ' ', a.last_name) AS agent_name, sub.resolved_count, RANK() OVER (ORDER BY sub.resolved_count DESC) AS agent_rank
FROM (
    SELECT 
        ta.agent_id, 
        COUNT(DISTINCT t.ticket_id) AS resolved_count
    FROM Ticket_Agent ta
    JOIN Support_Ticket t ON ta.ticket_id = t.ticket_id
    WHERE t.status IN ('RESOLVED','CLOSED')
    GROUP BY ta.agent_id
) AS sub
JOIN Agent a ON sub.agent_id = a.agent_id
ORDER BY sub.resolved_count DESC
LIMIT 10;

# Query5: Creating the stored function which calculates Customer Lifetime Value (CLV) based on all payments made by the customer.

DELIMITER $$

CREATE FUNCTION fn_customer_lifetime_value(in_customer_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total DECIMAL(12,2);

    SELECT COALESCE(SUM(p.amount),0) INTO total
    FROM Payment p
    JOIN Invoice i ON p.invoice_id = i.invoice_id
    JOIN Subscription s ON s.subscription_id = i.subscription_id
    WHERE s.customer_id = in_customer_id;

    RETURN total;
END$$

DELIMITER ;

# Creating a stored procedure which presents an accounting report on a monthly basis comprising of invoices, payments and balance.
DELIMITER $$

CREATE PROCEDURE sp_monthly_revenue_report(IN in_yyyymm VARCHAR(7))
BEGIN
    SELECT 
        in_yyyymm AS report_month,
        COUNT(DISTINCT i.invoice_id) AS invoice_count,
        COALESCE(SUM(i.total_amount),0) AS total_invoiced,
        COALESCE(SUM(p.amount),0) AS total_paid,
        (COALESCE(SUM(i.total_amount),0) - COALESCE(SUM(p.amount),0)) AS outstanding_amount
    FROM Invoice i
    LEFT JOIN Payment p ON p.invoice_id = i.invoice_id
    WHERE DATE_FORMAT(i.issue_date, '%Y-%m') = in_yyyymm;
END$$

DELIMITER ;

# Calculating lifetime value for a customer
SELECT customer_id,
       CONCAT(first_name, ' ', last_name) AS customer_name,
       fn_customer_lifetime_value(customer_id) AS lifetime_value
FROM Customer;

# Calculating monthly financial summary
CALL sp_monthly_revenue_report('2024-03'); # output showing zero values
CALL sp_monthly_revenue_report('2024-04'); #output showing non-zero values
#-----------------------------------------------TASK 5 OPTIMIZATION----------------------------------------------------------------------------------------
# Strategy 1- Indexing Foreign Key Columns
CREATE INDEX idx_subscription_customer ON Subscription(customer_id);
CREATE INDEX idx_invoice_subscription ON Invoice(subscription_id);
CREATE INDEX idx_payment_invoice ON Payment(invoice_id);

# Strategy 2
SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, MAX(p.payment_date) AS last_payment_date
FROM Customer c
LEFT JOIN Subscription s ON c.customer_id = s.customer_id
LEFT JOIN Invoice i ON s.subscription_id = i.subscription_id
LEFT JOIN Payment p ON i.invoice_id = p.invoice_id
GROUP BY c.customer_id;
































