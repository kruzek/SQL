-- top 20 produktov podla poctu predanych ks
SELECT 
    p.product_id, 
    p.product_name, 
    SUM(o.quantity) AS sales_volume, 
    COUNT(DISTINCT o.order_id) AS distinct_orders 
FROM 
    `products` AS p 
LEFT JOIN 
    `orders_items` AS o 
ON 
    p.product_id = o.product_id 
GROUP BY 
    p.product_id,
    p.product_name 
ORDER BY 
    sales_volume DESC
LIMIT 20;

-- trzby z predaja jednotlivych titulov, no iba v objednavkach od zakaznikov, u ktorych celkovo evidujeme aspon 5 objednavok
SELECT 
    p.product_id, 
    p.product_name, 
    SUM(o.quantity * o.price) AS revenue 
FROM 
    `products` AS p 
LEFT JOIN 
    `orders_items` AS o 
ON 
    p.product_id = o.product_id 
WHERE 
    o.order_id IN (SELECT order_id FROM orders GROUP BY customer_id HAVING COUNT(*) >= 5)
GROUP BY 
    p.product_id, 
    p.product_name;


-- zoznam kombinacii titulov, ktore najcastejsie zakupili rovnaki zakaznici, s poctom kolko
SELECT 
    oi1.product_id AS product_id_1, 
    oi2.product_id AS product_id_2, 
    COUNT(DISTINCT o.customer_id) AS distinct_customers 
FROM 
    orders_items AS oi1 
JOIN 
    orders_items AS oi2 
ON 
    oi1.order_id = oi2.order_id 
JOIN 
    orders AS o 
ON 
    oi1.order_id = o.order_id 
WHERE 
    oi1.product_id < oi2.product_id 
GROUP BY 
    product_id_1, 
    product_id_2 
ORDER BY 
    distinct_customers DESC;


-- priemerny pocet dni medzi 2 objednavkami na jedneho zakaznika. Ak zakaznik spravil iba 1 objednavku, vo vystupe mzoe byt NULL alebo ich nezahrname do vystupu
SELECT 
    customer_id,
    orders_count,
    AVG(days_between_orders) AS frequency
FROM (
    SELECT 
        customer_id,
        COUNT(*) AS orders_count,
        AVG(days_between) AS days_between_orders
    FROM (
        SELECT 
            customer_id,
            order_created,
            LAG(order_created) OVER (PARTITION BY customer_id ORDER BY order_created) AS previous_order_created,
            DATEDIFF(order_created, LAG(order_created) OVER (PARTITION BY customer_id ORDER BY order_created)) AS days_between
        FROM 
            orders
    ) AS order_gaps
    GROUP BY 
        customer_id
    HAVING 
        orders_count > 1
) AS avg_days_between
GROUP BY 
    customer_id, orders_count;

alebo

SELECT 
    customer_id,
    orders_count,
    AVG(days_between) AS frequency
FROM (
    SELECT 
        customer_id,
        COUNT(*) AS orders_count,
        AVG(strftime('%s', order_created) - strftime('%s', previous_order_created)) / (24 * 60 * 60) AS days_between
    FROM (
        SELECT 
            customer_id,
            order_created,
            (SELECT MAX(order_created) FROM orders o2 WHERE o2.customer_id = o.customer_id AND o2.order_created < o.order_created) AS previous_order_created
        FROM 
            orders o
    ) AS order_gaps
    WHERE previous_order_created IS NOT NULL
    GROUP BY 
        customer_id
    HAVING 
        orders_count > 1
) AS avg_days_between
GROUP BY 
    customer_id, orders_count;

-- zoznam zakaznickych objednavok s poctom dni od poslednej objednavky rovnakeho zakaznika (podobne ako query 4 ale bez agregovania)
SELECT 
    order_id,
    customer_id,
    order_created,
    DATEDIFF(
        order_created,
        LAG(order_created) OVER (PARTITION BY customer_id ORDER BY order_created)
    ) AS days_since_last_order
FROM 
    orders
ORDER BY 
    customer_id, 
    order_created;



to remind we have databse:
orders table with order_id, order_created_customer_id
orders-items table with order_item_id, order_id, product_id, quantity, price
products table with product_id, product_name