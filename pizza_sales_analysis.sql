-- 1. Retrieve the total number of orders placed.

SELECT COUNT(order_id) 
FROM orders;

-- 2. Calculate the total revenue generated from pizza sales.
SELECT ROUND(SUM(order_details.quantity * pizzas.price),2) AS total_revenue
FROM order_details
JOIN pizzas
ON order_details.pizza_id = pizzas.pizza_id;

-- 3. Identify the highest-priced pizza.

SELECT pizza_types.name, pizzas.price
FROM pizza_types
JOIN pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY 2 DESC
LIMIT 1;

-- 4. Identify the most common pizza size ordered.

WITH pizzas_ordered (pizza_id, size, quantity) AS (
SELECT order_details.pizza_id, pizzas.size, order_details.quantity
FROM order_details
JOIN pizzas
ON order_details.pizza_id = pizzas.pizza_id)
SELECT size, SUM(quantity) AS total_quantity
FROM pizzas_ordered
GROUP BY size 
ORDER BY total_quantity DESC LIMIT 1
;

-- 5. List the top 5 most ordered pizza types along with their quantities.

SELECT pizza_types.name, SUM(order_details.quantity) AS total_quantity
FROM pizzas
JOIN pizza_types
ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN order_details
ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY total_quantity DESC LIMIT 5;

-- 6. Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT pizza_types.category, SUM(order_details.quantity) AS total_quantity
FROM pizza_types
JOIN pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details
ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY total_quantity;

-- 7. Determine the distribution of orders by hour.

SELECT HOUR(time), COUNT(order_id)
FROM orders
GROUP BY HOUR(time);

-- 8. Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT ROUND(AVG(quantity),0) AS avg_pizzas_per_day FROM
(SELECT orders.date, SUM(order_details.quantity) as quantity
FROM orders
JOIN order_details
ON orders.order_id = order_details.order_details_id
GROUP BY orders.date) AS order_quantity;

-- 9. Determine the top 3 most ordered pizza types based on revenue.

SELECT pizza_types.name,
SUM(order_details.quantity * pizzas.price) AS revenue
FROM pizza_types
JOIN pizzas
ON pizzas.pizza_type_id = pizza_types.pizza_type_id
JOIN order_details
ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY revenue DESC LIMIT 3;

-- 10. Calculate the percentage contribution of each pizza type to total revenue.

WITH revenue_per_category AS(
SELECT pizza_types.category AS category, 
ROUND(SUM(order_details.quantity * pizzas.price),2) AS total_revenue_per_category
FROM pizza_types
JOIN pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details
ON order_details.pizza_id = pizzas.pizza_id 
GROUP BY pizza_types.category),
total_revenue_category AS(
SELECT category, total_revenue_per_category,
SUM(total_revenue_per_category) OVER() AS total_revenue_category
FROM revenue_per_category)
SELECT category, 
ROUND((total_revenue_per_category/total_revenue_category) *100,2) AS percentage_revenue
FROM total_revenue_category
;

-- 11. Analyze the cumulative revenue generated over time.

SELECT date,
SUM(revenue) OVER(ORDER BY date) AS cum_revenue FROM (
SELECT orders.date, 
SUM(order_details.quantity*pizzas.price) AS revenue 
FROM order_details
JOIN pizzas
ON order_details.pizza_id = pizzas.pizza_id
JOIN orders
ON order_details.order_details_id = orders.order_id
GROUP BY orders.date) AS sales;

-- 12. Determine the top 3 most ordered pizza types based on revenue for each pizza category.

WITH ranked_pizza AS(
SELECT pizza_types.category, 
pizza_types.name,
ROUND(SUM(order_details.quantity*pizzas.price),2) as revenue,
RANK() OVER(PARTITION BY pizza_types.category ORDER BY SUM(order_details.quantity*pizzas.price) DESC) AS ranking
FROM pizza_types
JOIN pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN order_details
ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category, pizza_types.name
)
SELECT category, name, revenue, ranking
FROM ranked_pizza
WHERE ranking<=3;

