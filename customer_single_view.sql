SELECT  A.CUST_CODE,
        LAST_VISIT,
        TOTAL_VISIT,
        TOTAL_SPEND,
        AVG_WEEKLY_VISIT,
        AVG_WEEKLY_SPEND,
        AVG_BASKET_SIZE,
        BEST_SELLER,
        LEAST_SELLER,
        BEST_SELLER_PROD_CODE_10,
        LEAST_SELLER_PROD_CODE_10,
        BEST_SELLER_PROD_CODE_20,
        LEAST_SELLER_PROD_CODE_20,
        BEST_SELLER_PROD_CODE_30,
        LEAST_SELLER_PROD_CODE_30,
        BEST_SELLER_PROD_CODE_40,
        LEAST_SELLER_PROD_CODE_40,
        HIGHEST_BASKET_DOMINANT,
        LOWEST_BASKET_DOMINANT,
        POPULAR_TIME,
        POPULAR_DAY,
        LEAST_POPULAR_DAY,
        AVERAGE_VISIT_PER_WEEK

# SIMPLE CALCULATION VALUE
FROM (
        SELECT  *                                 
        FROM (
                SELECT  CUST_CODE,
                        MAX(SHOP_DATE) AS LAST_VISIT,
                        COUNT(DISTINCT BASKET_ID) AS TOTAL_VISIT,
                        SUM(SPEND) AS TOTAL_SPEND,
                        COUNT(DISTINCT BASKET_ID)/COUNT(DISTINCT SHOP_WEEK) AS AVG_WEEKLY_VISIT,
                        SUM(SPEND)/COUNT(DISTINCT SHOP_WEEK) AS AVG_WEEKLY_SPEND,
                        SUM(SPEND)/COUNT(DISTINCT BASKET_ID) AS AVG_BASKET_SIZE,
                FROM  `minibads2.Supermarket.supermarket`
                WHERE CUST_CODE is not NULL
        GROUP BY CUST_CODE) 
     ) A

# JOIN VALUE FOR COMPLEX CASES AS BELOW 
# HIGHEST_BASKET_DOMINANT
LEFT JOIN  (
        SELECT  CUST_CODE,
                BASKET_DOMINANT_MISSION AS HIGHEST_BASKET_DOMINANT
        FROM(
                SELECT  CUST_CODE,
                        BASKET_DOMINANT_MISSION,
                        SUM(SPEND) AS total_spend,
                        DENSE_RANK() OVER(PARTITION BY CUST_CODE ORDER BY SUM(SPEND) DESC) AS MAX_DMN,
                FROM `minibads2.Supermarket.supermarket`
                WHERE CUST_CODE IS NOT NULL
                GROUP BY CUST_CODE, BASKET_DOMINANT_MISSION)
        WHERE MAX_DMN=1
            ) B
ON A.CUST_CODE = B.CUST_CODE

#LOWEST_BASKET_DOMINANT
LEFT JOIN  (
        SELECT  CUST_CODE,
                BASKET_DOMINANT_MISSION AS LOWEST_BASKET_DOMINANT
        FROM(
                SELECT  CUST_CODE,
                        BASKET_DOMINANT_MISSION,
                        SUM(SPEND) AS total_spend,
                        ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY SUM(SPEND) ASC) AS MIN_DMN,
                FROM `minibads2.Supermarket.supermarket`
                WHERE CUST_CODE IS NOT NULL
                GROUP BY CUST_CODE, BASKET_DOMINANT_MISSION)
        WHERE MIN_DMN=1
            ) C
ON B.CUST_CODE = C.CUST_CODE

# POPULAR_TIME
LEFT JOIN  (
        SELECT  CUST_CODE,
                SHOP_HOUR AS POPULAR_TIME 
        FROM( 
                    SELECT  CUST_CODE,
                            SHOP_HOUR,
                            COUNT(SHOP_HOUR) AS highest_hour,
                            ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY COUNT(SHOP_HOUR) DESC) AS MAX_HRS,
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, SHOP_HOUR)
        WHERE MAX_HRS=1
            ) D
ON C.CUST_CODE = D.CUST_CODE

#POPULAR_DAY
LEFT JOIN  (
        SELECT  CUST_CODE,
                SHOP_WEEKDAY AS POPULAR_DAY 
        FROM(
                SELECT  CUST_CODE,
                        SHOP_WEEKDAY,
                        COUNT(SHOP_WEEKDAY) AS highest_day,
                        ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY COUNT(SHOP_WEEKDAY) DESC) AS MAX_DAY,
                FROM `minibads2.Supermarket.supermarket`
                WHERE CUST_CODE IS NOT NULL
                GROUP BY CUST_CODE, SHOP_WEEKDAY)
        WHERE MAX_DAY=1
            ) E
ON D.CUST_CODE = E.CUST_CODE

#LEAST_POPULAR_DAY
LEFT JOIN  (
        SELECT  CUST_CODE,
                SHOP_WEEKDAY AS LEAST_POPULAR_DAY
        FROM(
                SELECT  CUST_CODE,
                        SHOP_WEEKDAY,
                        COUNT(SHOP_WEEKDAY) AS highest_day,
                        ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY COUNT(SHOP_WEEKDAY) ASC) AS MIN_DAY,
                FROM `minibads2.Supermarket.supermarket`
                WHERE CUST_CODE IS NOT NULL
                GROUP BY CUST_CODE, SHOP_WEEKDAY)
        WHERE MIN_DAY=1
            ) F
ON E.CUST_CODE = F.CUST_CODE

# BEST_SELLER
LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE AS BEST_SELLER
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY DESC) AS MAX_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE
                    ORDER BY CUST_CODE
                )
        )
    WHERE MAX_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE) G
ON F.CUST_CODE = G.CUST_CODE

#LEAST_SELLER
LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE AS LEAST_SELLER
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY ASC) AS MIN_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE
                    ORDER BY CUST_CODE
                )
        )
    WHERE MIN_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE) H
ON G.CUST_CODE = H.CUST_CODE

# BEST_SELLER AND LEAST SELLER FOR EACH PRODUCT 
LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE_10 AS BEST_SELLER_PROD_CODE_10
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE_10,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY DESC) AS MAX_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE_10,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE_10
                    ORDER BY CUST_CODE
                )
        )
    WHERE MAX_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE_10) I
ON H.CUST_CODE = I.CUST_CODE

LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE_10 AS LEAST_SELLER_PROD_CODE_10
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE_10,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY ASC) AS MIN_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE_10,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE_10
                    ORDER BY CUST_CODE
                )
        )
    WHERE MIN_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE_10) J
ON I.CUST_CODE = J.CUST_CODE

LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE_20 AS BEST_SELLER_PROD_CODE_20
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE_20,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY DESC) AS MAX_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE_20,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE_20
                    ORDER BY CUST_CODE
                )
        )
    WHERE MAX_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE_20) K
ON J.CUST_CODE = K.CUST_CODE

LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE_20 AS LEAST_SELLER_PROD_CODE_20
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE_20,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY ASC) AS MIN_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE_20,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE_20
                    ORDER BY CUST_CODE
                )
        )
    WHERE MIN_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE_20) L
ON K.CUST_CODE = L.CUST_CODE

LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE_30 AS BEST_SELLER_PROD_CODE_30
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE_30,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY DESC) AS MAX_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE_30,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE_30
                    ORDER BY CUST_CODE
                )
        )
    WHERE MAX_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE_30) M
ON L.CUST_CODE = M.CUST_CODE

LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE_30 AS LEAST_SELLER_PROD_CODE_30
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE_30,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY ASC) AS MIN_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE_30,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE_30
                    ORDER BY CUST_CODE
                )
        )
    WHERE MIN_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE_30) N
ON M.CUST_CODE = N.CUST_CODE

LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE_40 AS BEST_SELLER_PROD_CODE_40
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE_40,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY DESC) AS MAX_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE_40,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE_40
                    ORDER BY CUST_CODE
                )
        )
    WHERE MAX_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE_40) O
ON N.CUST_CODE = O.CUST_CODE

LEFT JOIN (
    SELECT  CUST_CODE,
            PROD_CODE_40 AS LEAST_SELLER_PROD_CODE_40
    FROM(
            SELECT  CUST_CODE,
                    PROD_CODE_40,
                    ROW_NUMBER() OVER(PARTITION BY CUST_CODE ORDER BY QTY ASC) AS MIN_QTY

            FROM(   SELECT  CUST_CODE,
                            PROD_CODE_40,
                            SUM(QUANTITY) AS QTY
                    FROM `minibads2.Supermarket.supermarket`
                    WHERE CUST_CODE IS NOT NULL
                    GROUP BY CUST_CODE, PROD_CODE_40
                    ORDER BY CUST_CODE
                )
        )
    WHERE MIN_QTY = 1
    GROUP BY CUST_CODE, PROD_CODE_40) P
ON O.CUST_CODE = P.CUST_CODE

# AVERAGE_VISIT_PER_WEEK
LEFT JOIN (
SELECT CUST_CODE, SUM(TOTAL_VISIT)/COUNT(DISTINCT WEEK_OF_YEAR) AS AVERAGE_VISIT_PER_WEEK
FROM    (
        SELECT  CUST_CODE,
                EXTRACT(WEEK FROM DATE_OFFICIAL) AS WEEK_OF_YEAR,
                COUNT(DISTINCT BASKET_ID) AS TOTAL_VISIT
        FROM    (
                SELECT  *,
                        PARSE_TIMESTAMP("%Y%m%d", CAST(SHOP_DATE AS STRING)) AS DATE_OFFICIAL
                FROM `minibads2.Supermarket.supermarket`
                )
        WHERE CUST_CODE IS NOT NULL
        GROUP BY CUST_CODE, WEEK_OF_YEAR
        ORDER BY CUST_CODE, WEEK_OF_YEAR
        )
GROUP BY CUST_CODE
ORDER BY CUST_CODE) Q
ON P.CUST_CODE = Q.CUST_CODE