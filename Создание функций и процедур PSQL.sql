set search_path = diplom;

-- подключаем модуль для работы с файлами csv и созздаем сервер для внешней таблицы

create extension file_fdw;

create server file_server foreign data wrapper file_fdw;

-- создаем функцию, которая будет загружать данные файла csv в созданную базу данных через внешнюю таблицу (инкрементальная загрузка)

create or replace function insert_date_for_sales() RETURNS VOID AS $$
begin
	create foreign table sales (
      	 "Invoice ID" varchar(11),
			Branch varchar(100),
			City  varchar(100),
			"Customer type" varchar(100),
			Gender varchar(100),
			"Product line" varchar(100),
			"Unit price" numeric,
			"Quantity" integer,
			"Tax 5%" numeric(8,2),
			Total numeric(8,2),
			"Date" varchar(11),
			"Time" time with time zone,
			Payment varchar(100),
			cogs numeric(8,2),
			"gross margin percentage" numeric(8,2),
			"gross income" numeric(8,2),
			Rating numeric(8,2)
   	) 
	server file_server
	options (
    	format 'csv',
    	filename 'supermarket_sales.csv',
   	header 'true',
    delimiter ',',
   	null 'NULL'
	);

	-- заполняем таблицы данными
	INSERT INTO city (city)
	SELECT distinct City as city
	FROM sales;

	INSERT INTO branch (branch_name, city_id)
	SELECT distinct CAST(s.Branch AS branch_type) as branch_name, c.city_id
	FROM sales s
	INNER JOIN city c ON s.City = c.city;

	INSERT INTO customer ("type", gender, rating, branch_id)
	SELECT distinct CAST("Customer type" AS customer_type) AS "type", CAST(Gender AS gender_type) AS gender, Rating AS rating, b.branch_id
	FROM sales s
	INNER JOIN branch b ON CAST(s.Branch AS branch_type) = b.branch_name
	INNER JOIN city c ON s.City = c.city and c.city_id = b.city_id;

	INSERT INTO product (product_line, unit_price, branch_id)
	SELECT distinct CAST("Product line" AS product_line_type) as product_line, "Unit price" as unit_price, b.branch_id
	FROM sales s
	INNER JOIN branch b ON CAST(s.Branch AS branch_type) = b.branch_name
	INNER JOIN city c ON s.City = c.city and c.city_id = b.city_id;

	INSERT INTO calendar (real_date)
	SELECT distinct  CAST(TO_DATE("Date", 'MM/DD/YYYY') AS date) as real_date
	FROM sales;

	INSERT INTO payments (invoice_id, date_id, quantity, total_price, tax, time_payment, payment_type, COGS, gross_margin_percentage, gross_income, customer_id, product_id)
	SELECT s."Invoice ID" as invoice_id, d.date_id, s."Quantity"as quantity, s.Total as total_price, s."Tax 5%" as tax, 
			s."Time" as time_payment, CAST(s.Payment AS payment_types) as payment_type, s.cogs as COGS, s."gross margin percentage" as gross_margin_percentage, 
			s."gross income" as gross_income, c.customer_id, p.product_id
	FROM sales s
	INNER JOIN city ct ON s.City = ct.city
	INNER JOIN branch b ON CAST(s.Branch AS branch_type) = b.branch_name and ct.city_id = b.city_id
	INNER JOIN customer c ON CAST(s."Customer type" AS customer_type) = c."type" and CAST(s.Gender AS gender_type) = c.gender and s.Rating = c.rating and c.branch_id = b.branch_id
	INNER JOIN product p ON CAST(s."Product line" AS product_line_type) = p.product_line and s."Unit price" = p.unit_price and c.branch_id = p.branch_id
	INNER JOIN calendar d ON CAST(TO_DATE(s."Date", 'MM/DD/YYYY') AS date) = d.real_date;

	drop foreign table sales;
end;
$$ language plpgsql;

-- создаем функцию для очистки данных таблиц базы данных для полной (не инкрементальной загрузки), если таковая понадобится

create or replace function drop_date_for_sales()  RETURNS VOID AS $$
begin
	truncate table payments;
	truncate table customer cascade;
	truncate table product cascade;
	truncate table branch cascade;
	truncate table city cascade;
	truncate table calendar cascade;
end;
$$ language plpgsql;

-- создаем триггерную функцию и триггер, которые будут обеспечивать отслеживание историчности изменения цен единиц товаров

create or replace function history_unit_price() returns trigger AS $$
begin
  if tg_op = 'UPDATE' then
    insert into unit_price_history (change_date, start_unit_price, end_unit_price)
    values (now(), new.start_unit_price, new.end_unit_price);
    return new;
  elsif tg_op = 'DELETE' then
    insert into unit_price_history (change_date, start_unit_price, end_unit_price)
    values (now(), old.start_unit_price, old.end_unit_price);
    return old;
  end if;
end;
$$ language plpgsql;

create or replace trigger unit_price_history 
before update or delete on product 
for each row execute function history_unit_price();


select insert_date_for_sales()







