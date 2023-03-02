WITH data_order as (
	SELECT *,
		COALESCE(CAST(delivery_time AS VARCHAR(250)), 
				 CAST(delivery_date AS VARCHAR(250))) delivery_fix
	FROM restaurant
), 

fav_payment_mode as (
	SELECT distinct on (customer_id) d.*
	FROM (
		SELECT customer_id, payment_mode, COUNT(akeed_order_id) total_order
		FROM data_order
		GROUP BY 1,2
	) d
	ORDER BY customer_id, total_order DESC
),

order_with_promo as (
	SELECT customer_id, COUNT(DISTINCT akeed_order_id) order_promo
	FROM data_order 
	WHERE promo_code IS NOT NULL
	GROUP BY 1
),

fav_vendor as (
	SELECT distinct on (customer_id) d.*
	FROM (
		SELECT customer_id, vendor_id, COUNT(akeed_order_id) total_order
		FROM data_order
		GROUP BY 1,2
	) d
	ORDER BY customer_id, total_order DESC
),

order_not_delivered as (
	SELECT customer_id, COUNT(DISTINCT akeed_order_id) not_delivered
	FROM data_order 
	WHERE delivery_fix IS NULL
	GROUP BY 1
),

data_cust as (
SELECT 
	customer_id, 
	COUNT(DISTINCT akeed_order_id) total_order,
	SUM(item_count) total_qty,
	SUM(grand_total) gmv,
	SUM(vendor_discount_amount) value_discount,
	AVG(vendor_rating) avg_vendor_rating, 
	AVG(driver_rating) avg_driver_rating, 
	AVG(deliverydistance) avg_delivery_distance, 
	AVG(preparationtime) avg_preparation_time,
	COUNT(DISTINCT vendor_id) total_vendor,  
	MAX(created_at) last_order, 
	DATE('2020-02-29') today --set example of today
FROM data_order
GROUP BY 1
),

hasil as (
SELECT 
	dc.*, 
	AVG(gmv) OVER() avg_gmv_all,
	pm.payment_mode favorite_payment_methode, 
	owp.order_promo, 
	fv.vendor_id fav_vendor,
	not_delivered/NULLIF(dc.total_order,0)*100 perc_not_delivered,
	owp.order_promo/NULLIF(gmv,0)*100 perc_promotion_order,
	CASE 
		WHEN not_delivered/NULLIF(dc.total_order,0) >= 0.8 THEN 'high'
		WHEN not_delivered/NULLIF(dc.total_order,0) < 0.8 
			AND not_delivered/NULLIF(dc.total_order,0) > 0.3 
				THEN 'moderate'
		WHEN not_delivered/NULLIF(dc.total_order,0) <= 0.3 
			THEN 'low'
		ELSE 'never'
	END AS cluster_not_delivered,
	CASE 
		WHEN owp.order_promo/NULLIF(gmv,0) >= 0.8 THEN 'high'
		WHEN owp.order_promo/NULLIF(gmv,0) < 0.8 
			AND owp.order_promo/NULLIF(gmv,0) > 0.3 THEN 'moderate'
		WHEN owp.order_promo/NULLIF(gmv,0) <= 0.3 THEN 'low'
		ELSE 'never'
	END AS cluster_promo, 
	CASE 
		WHEN avg_vendor_rating >= 4 then 'High'
		WHEN avg_vendor_rating >= 2 then 'Moderate' 
		WHEN avg_vendor_rating < 2 then 'Low' 
		Else 'never'
	END AS cluster_vendor_rat,
	CASE 
		WHEN avg_driver_rating >= 4 then 'High'
		WHEN avg_driver_rating >= 2 then 'Moderate' 
		WHEN avg_driver_rating < 2 then 'Low' 
		Else 'never'
	END AS cluster_driver_rat,
	(DATE_PART('year', today::date) - DATE_PART('year', last_order::date)) * 12 + 
		(DATE_PART('month', today::date) - DATE_PART('month', last_order::date)) last_order_month,
	CASE 
		WHEN (DATE_PART('year', today::date) - DATE_PART('year', last_order::date)) * 12 +
              (DATE_PART('month', today::date) - DATE_PART('month', last_order::date)) > 2 THEN 'Not Active'
		Else 'Active'
	END AS stat_active
FROM data_cust dc
LEFT JOIN fav_payment_mode pm on dc.customer_id = pm.customer_id
LEFT JOIN order_with_promo owp on dc.customer_id = owp.customer_id
LEFT JOIN fav_vendor fv on dc.customer_id = fv.customer_id 
LEFT JOIN order_not_delivered ond on dc.customer_id = ond.customer_id 
)

--SELECT * FROM hasil
SELECT 
	customer_id, total_order, total_qty, gmv, perc_not_delivered, 
	perc_promotion_order, favorite_payment_methode,
	avg_vendor_rating, total_vendor, fav_vendor,
	avg_driver_rating, avg_driver_rating, avg_delivery_distance,
	avg_preparation_time, last_order, last_order_month, stat_active,
	cluster_promo,cluster_vendor_rat, cluster_vendor_rat,
	CASE 
		WHEN gmv > avg_gmv_all AND cluster_promo = 'never'
			AND cluster_vendor_rat = 'High'
			AND cluster_vendor_rat = 'High' 
				THEN 'Excellent Performance Customer'
		WHEN gmv > avg_gmv_all THEN 'Good Performance Customer' 
		WHEN gmv < avg_gmv_all
			AND cluster_vendor_rat NOT IN ('never','Low')
			AND cluster_driver_rat NOT IN ('never','Low')
				THEN 'Moderate Performance Customer' 
		WHEN gmv < avg_gmv_all
			AND (cluster_vendor_rat IN ('never','Low')
			OR cluster_driver_rat IN ('never','Low') )
				THEN 'Poor Performace Customer' 
		Else 'Unidentified'
	END AS stat_cust
FROM hasil 





