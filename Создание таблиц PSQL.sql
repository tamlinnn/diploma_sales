set search_path = diplom;

create table city(
city_id uuid primary key default gen_random_uuid(),
city varchar(33) not null
);

create type branch_type as enum ('A', 'B', 'C');

create table branch(
branch_id uuid primary key default gen_random_uuid(),
branch_name branch_type not null default 'A',
city_id uuid not null references city(city_id)
);

create type customer_type as enum ('Member', 'Normal');
create type gender_type as enum ('Male', 'Female');

create table customer(
customer_id uuid primary key default gen_random_uuid(),
"type" customer_type default 'Normal' not null,
gender gender_type default 'Female' not null,
rating numeric,
branch_id uuid not null references branch(branch_id)
);

create type product_line_type as enum ('Electronic accessories', 'Fashion accessories', 'Food and beverages', 'Health and beauty', 'Home and lifestyle', 'Sports and travel');

create table product(
product_id uuid primary key default gen_random_uuid(),
product_line product_line_type default 'Electronic accessories' not null,
unit_price numeric(6,2) default 0.99 not null,
branch_id uuid not null references branch(branch_id)
);

create table calendar(
date_id uuid primary key default gen_random_uuid(),
real_date date not null
);

create type payment_types as enum ('Cash', 'Credit card', 'Ewallet');

create table payments(
payment_id uuid primary key default gen_random_uuid(),
invoice_id varchar(11),
date_id uuid not null references calendar(date_id),
quantity int default 1 not null,
total_price numeric(6,2) default 0.99 not null,
tax numeric(4, 2) not null,
time_payment time with time zone not null,
payment_type payment_types default 'Cash' not null,
COGS numeric(10,2) default 0.99 not null,
gross_margin_percentage numeric(10,2) default 0.99 not null,
gross_income numeric(10,2) default 0.99 not null,
customer_id uuid not null references customer(customer_id),
product_id uuid not null references product(product_id)
);

create table unit_price_history(
unit_price_id uuid primary key default gen_random_uuid(),
change_date timestamp with time zone not null,
start_unit_price numeric(6,2) default 0.99,
end_unit_price numeric(6,2) default 0.99
);
