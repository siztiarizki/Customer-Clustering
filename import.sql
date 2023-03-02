DROP TABLE restaurant;
CREATE TABLE restaurant (
  akeed_order_id FLOAT,
  customer_id VARCHAR(250),
  item_count FLOAT,
  grand_total FLOAT,
  payment_mode INT,
  promo_code VARCHAR(250),
  vendor_discount_amount FLOAT,
  promo_code_discount_percentage FLOAT,
  is_favorite VARCHAR(50),
  is_rated VARCHAR(50),
  vendor_rating FLOAT, 
  driver_rating FLOAT, 
  deliverydistance FLOAT, 
  preparationtime FLOAT, 
  delivery_time VARCHAR(250),
  order_accepted_time TIMESTAMP,
  driver_accepted_time TIMESTAMP,
  ready_for_pickup_time TIMESTAMP,
  picked_up_time TIMESTAMP, 
  delivered_time VARCHAR(250), 
  delivery_date TIMESTAMP, 
  vendor_id INT, 
  created_at TIMESTAMP,
  LOCATION_NUMBER INT, 
  LOCATION_TYPE VARCHAR(50), 
  CID_X_LOC_NUM_X_VENDOR VARCHAR(250)
); 

COPY restaurant
FROM 'D:\data\input csv.csv'
DELIMITER ';'
CSV HEADER;