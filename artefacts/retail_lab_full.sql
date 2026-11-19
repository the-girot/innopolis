BEGIN;
CREATE SCHEMA retail_lab;
SET LOCAL search_path TO retail_lab;
CREATE TABLE import_log(id int PRIMARY KEY, file_name text, received_at timestamp, status text);
CREATE TABLE sales(id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, batch_id int, source text, order_no text, line_no text, customer_email text, sku text, qty text, unit_price text, currency text, sold_at text, status text);
CREATE TABLE products(sku text PRIMARY KEY, name text, current_price numeric(12,2));
CREATE TABLE payments(id int PRIMARY KEY, source text, order_no text, amount numeric(12,2), currency text);
INSERT INTO import_log VALUES (1,'web_20261118.csv','2026-11-18 23:00','ok'),(2,'pos_20261118.csv','2026-11-18 23:05','ok'),(3,'web_20261118.csv','2026-11-18 23:10','ok'),(4,'web_20261118_fix.csv','2026-11-19 07:30','ok'),(10001,'web_generated_20261118.csv','2026-11-18 23:20','ok'),(10002,'pos_generated_20261118.csv','2026-11-18 23:25','ok');
INSERT INTO products VALUES ('A','Клавиатура',55),('B','Мышь',25);
INSERT INTO sales(batch_id,source,order_no,line_no,customer_email,sku,qty,unit_price,currency,sold_at,status) VALUES
(1,'web','100','1','buyer@example.test','A','2','50.00','EUR','2026-11-18 15:00','paid'),
(1,'web','100','2','buyer@example.test','B','1','20.00','EUR','2026-11-18 15:00','paid'),
(2,'pos','100','1',NULL,'B','3','20,00','EUR','18.11.2026 16:00','PAID'),
(3,'web','100','1','buyer@example.test','A','2','50.00','EUR','2026-11-18 15:00','paid'),
(3,'web','100','2','buyer@example.test','B','1','20.00','EUR','2026-11-18 15:00','paid'),
(4,'web','100','1','buyer@example.test','A','1','50.00','EUR','2026-11-18 15:00','paid'),
(2,'pos','101','1',NULL,'UNKNOWN','1','10,00','EUR','18.11.2026 17:00','PAID'),
(10001,'web','GEN-0001','1','buyer1@example.test','A','1','50.00','EUR','2026-11-18 08:00','paid'),
(10001,'web','GEN-0001','2','buyer1@example.test','B','1','20.00','EUR','2026-11-18 08:00','paid'),
(10000,'pos','GEN-0001','1',NULL,'A','1','50,00','EUR','18.11.2026 08:00','PAID'),
(10000,'pos','GEN-0001','2',NULL,'B','1','20,00','EUR','18.11.2026 08:00','PAID');
INSERT INTO payments VALUES
(1,'web','100',40,'EUR'),
(2,'web','100',30,'EUR'),
(3,'pos','100',60,'EUR'),
(10001,'web','GEN-0001',70,'EUR'),
(10601,'pos','GEN-0001',70,'EUR');
CREATE VIEW payment_report AS SELECT s.source,s.order_no,sum(p.amount) AS paid FROM sales s JOIN payments p ON p.order_no=s.order_no GROUP BY s.source,s.order_no;
COMMIT;
