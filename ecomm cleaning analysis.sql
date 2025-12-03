USE ecomm;


SELECT * FROM customer_churn;


SET SQL_SAFE_UPDATES = 0;

# Data Cleaning

/*Imputing mean  and round off to the nearest integer if 
required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear, 
DaySinceLastOrder. */

UPDATE customer_churn SET WarehouseToHome = (SELECT * FROM (SELECT ROUND(AVG(WarehouseToHome)) FROM customer_churn 
                                            WHERE WarehouseToHome IS NOT NULL) AS warehouse_mean ) 
                                            WHERE WarehouseToHome IS NULL;
                                            
UPDATE customer_churn SET  HourSpendOnApp = (SELECT * FROM (SELECT ROUND(AVG(HourSpendOnApp)) FROM customer_churn 
                                            WHERE HourSpendOnApp IS NOT NULL) AS hourspendonapp_mean ) 
                                            WHERE HourSpendOnApp IS NULL;
								
UPDATE customer_churn SET  OrderAmountHikeFromlastYear = (SELECT * FROM (SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) FROM customer_churn 
                                            WHERE OrderAmountHikeFromlastYear IS NOT NULL) AS OrderAmountHikeFromlastYear_mean ) 
                                            WHERE OrderAmountHikeFromlastYear IS NULL;
									
UPDATE customer_churn SET  DaySinceLastOrder = (SELECT * FROM (SELECT ROUND(AVG(DaySinceLastOrder)) FROM customer_churn 
                                            WHERE DaySinceLastOrder IS NOT NULL) AS DaySinceLastOrder ) 
                                            WHERE DaySinceLastOrder IS NULL;
                                            
                                            
/* ➢ Imputing mode for the columns: Tenure, CouponUsed, OrderCount. */

SET @mode_tenure = (SELECT Tenure FROM customer_churn 
					group by Tenure order by count(tenure) DESC LIMIT 1);
UPDATE customer_churn SET Tenure = @mode_tenure WHERE Tenure IS NULL;

SET @mode_coupon_used = (SELECT CouponUsed FROM customer_churn 
						group by CouponUsed order by count(CouponUsed) DESC LIMIT 1);
UPDATE customer_churn SET CouponUsed = @mode_coupon_used WHERE CouponUsed IS NULL;

SET @mode_ordercount = (SELECT OrderCount FROM customer_churn 
						group by OrderCount order by count(OrderCount) DESC LIMIT 1);
UPDATE customer_churn SET OrderCount = @mode_ordercount WHERE OrderCount IS NULL;



/*Handling outliers in the 'WarehouseToHome' column by deleting rows where the 
values are greater than 100.*/

DELETE FROM customer_churn WHERE WarehouseToHome > 100;



/*Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and 
“Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure 
uniformity. */

UPDATE customer_churn SET PreferredLoginDevice = "Mobile Phone" 
					  WHERE PreferredLoginDevice = 'Phone';
UPDATE customer_churn SET PreferredOrderCat = "Mobile Phone" 
					  WHERE PreferredOrderCat = 'Mobile';

                      
                      
/*Standardizing payment mode values: Replace "COD" with "Cash on Delivery" and 
"CC" with "Credit Card" in the PreferredPaymentMode column.*/

UPDATE customer_churn SET PreferredPaymentMode =
					  CASE PreferredPaymentMode
                      WHEN 'COD' THEN 'Cash on Delivery'
                      WHEN 'CC' THEN 'Credit Card'
                      ELSE PreferredPaymentMode
                      END;
                      
# Data Transformation
                      
/* Renaming the column "PreferedOrderCat" to "PreferredOrderCat".*/

ALTER TABLE customer_churn RENAME column PreferedOrderCat TO PreferredOrderCat;



/*  Renaming the column "HourSpendOnApp" to "HoursSpentOnApp". */

ALTER TABLE customer_churn RENAME column HourSpendOnApp TO HoursSpentOnApp;



/* Creating a new column named ‘ComplaintReceived’ with values "Yes" if the 
corresponding value in the ‘Complain’ is 1, and "No" otherwise. */

ALTER TABLE customer_churn ADD COLUMN ComplaintReceived VARCHAR(3);

UPDATE customer_churn SET ComplaintReceived = IF(Complain = 1, 'Yes', 'No');



/*Creating a new column named 'ChurnStatus'. Set its value to “Churned” if the 
corresponding value in the 'Churn' column is 1, else assign “Active”.*/

ALTER TABLE customer_churn ADD COLUMN ChurnStatus VARCHAR(15);

UPDATE customer_churn SET ChurnStatus = IF(Churn = 1, 'Churned', 'Active');



/*  Drop the columns "Churn" and "Complain" from the table. */

ALTER TABLE customer_churn DROP COLUMN Churn ;


ALTER TABLE customer_churn DROP COLUMN Complain;


#Data Exploration and Analysis


/*  Retrieving the count of churned and active customers from the dataset. */

SELECT ChurnStatus, count(CustomerID) AS count_churn_status 
FROM customer_churn  GROUP BY ChurnStatus ;



/* Displaying the average tenure and total cashback amount of customers who 
churned. */

SELECT avg(Tenure) AS average_tenure, sum(CashbackAmount) AS total_cashback_amount FROM customer_churn
WHERE ChurnStatus = 'Churned';



/*  Determine the percentage of churned customers who complained. */

SET @complaint = (SELECT count(ChurnStatus) FROM customer_churn
				  WHERE ChurnStatus = 'Churned' AND ComplaintReceived = 'Yes');
                  
SET @churned = (SELECT count(ChurnStatus) FROM customer_churn 
				  WHERE ChurnStatus = 'Churned');
                  
SELECT(@complaint*100/@churned) AS percentage_of_churned_customers_complained;



/* City tier with the highest number of churned customers whose 
preferred order category is Laptop & Accessory.*/

SELECT CityTier , count(ChurnStatus) FROM customer_churn 
				  WHERE ChurnStatus= 'Churned' AND PreferredOrderCat= 'Laptop & Accessory' 
				  GROUP BY CityTier ORDER BY count(ChurnStatus) DESC LIMIT 1;
         
         
         
/* Most preferred payment mode among active customers. */

SELECT PreferredPaymentMode AS Most_Preferred_payment_method , count(ChurnStatus)  
				  FROM customer_churn 
				  group by PreferredPaymentMode 
                  order by count(ChurnStatus) DESC LIMIT 1;
                            

/* Total order amount hike from last year for customers who are single 
and prefer mobile phones for ordering.*/



SELECT sum(OrderAmountHikeFromlastYear) AS Total_order_amount_single_mobile FROM customer_churn
WHERE PreferredOrderCat = 'Mobile Phone' AND MaritalStatus = 'Single';


/* Average number of devices registered among customers who used UPI as 
their preferred payment mode.*/



SELECT count(PreferredLoginDevice) AS Avg_devices_uses_UPI  FROM customer_churn 
WHERE PreferredPaymentMode = 'UPI' GROUP BY PreferredPaymentMode;

SELECT * FROM customer_churn;


/* The city tier with the highest number of customers */

SELECT CityTier AS citytier_with_high_customers, count(CustomerID) FROM customer_churn
 GROUP BY CityTier ORDER BY count(CustomerID) DESC LIMIT 1;



/* Gender that utilized the highest number of coupons. */

SELECT Gender AS gender_used_high_no_of_coupons FROM customer_churn
GROUP BY Gender ORDER BY sum(CouponUsed) DESC LIMIT 1;



/* Number of customers and the maximum hours spent on the app in each 
preferred order category. */

SELECT PreferredOrderCat,count(CustomerID) AS no_of_cstmrs, max(HoursSpentOnApp) AS max_hrs_spent 
FROM  customer_churn
GROUP BY PreferredOrderCat;



/* Total order count for customers who prefer using credit cards and 
have the maximum satisfaction score. */

SELECT sum(OrderCount) AS Total_ordercount_CreditCard_MaxSatisfactionscore FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card' AND SatisfactionScore = '5';



/* Average satisfaction score of customers who have complained? */

SELECT avg(SatisfactionScore) FROM customer_churn WHERE ComplaintReceived = 'Yes';



/* Preferred order catego
ry among customers who used more than 5 
coupons.*/

SELECT PreferredOrderCat ,count(*) AS customer_count 
								   FROM customer_churn 
                                   WHERE CouponUsed >5 
                                   GROUP BY PreferredOrderCat ;



/* Top 3 preferred order categories with the highest average cashback 
amount. */


SELECT PreferredOrderCat AS high_cashback_category, avg(CashbackAmount) 
	    FROM customer_churn
        GROUP BY PreferredOrderCat
        ORDER BY avg(CashbackAmount)
        DESC
        LIMIT 3;
                        
	
    
 /*Preferred payment modes of customers whose average tenure is 10 
months and have placed more than 500 orders.*/


SELECT PreferredPaymentMode,avg(Tenure) FROM customer_churn 
	WHERE OrderCount > 500 GROUP BY PreferredPaymentMode HAVING avg(Tenure)=10;
    
    
    
/* Categorizing customers based on their distance from the warehouse to home such 
as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km, 
'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the 
churn status breakdown for each distance category. */    

SELECT 
	CASE
    WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
    WHEN WarehouseToHome <= 10 THEN 'Close Distance'
    WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
    ELSE 'Far Distance'
    END AS Distance_Category,
    ChurnStatus,
    count(*) AS customer_count
    FROM customer_churn
    GROUP BY Distance_Category,ChurnStatus;
    
    
    


/* List of customer’s order details who are married, live in City Tier-1, and their 
order counts are more than the average number of orders placed by all 
customers */

SELECT * FROM customer_churn 
		 WHERE MaritalStatus = 'Married' 
         AND CityTier = 1 
         AND OrderCount > (SELECT avg(OrderCount) FROM customer_churn);





























                      