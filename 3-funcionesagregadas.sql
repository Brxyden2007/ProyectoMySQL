-- 3. Funciones Agregadas (20 pts)

-- 1. Obtener el promedio de calificación por producto 

SELECT qp.product_id, p.name AS product_name, AVG(qp.rating) AS average_rating
FROM quality_products qp
JOIN products p ON qp.product_id = p.id
GROUP BY qp.product_id;

-- 2. Contar cuántos productos ha calificado cada cliente

SELECT customer_id, COUNT(*) AS total_calificaciones
FROM quality_products
GROUP BY customer_id;

-- 3. Sumar el total de beneficios asignados por audiencia

SELECT audience_id, COUNT(benefit_id) AS total_benefits
FROM audiencebenefits
GROUP BY audience_id;

-- 4. Calcular la media de productos por empresa

SELECT AVG(productos_por_empresa) AS promedio_productos_por_empresa
FROM (
    SELECT company_id, COUNT(product_id) AS productos_por_empresa
    FROM companyproducts
    GROUP BY company_id
) AS sub;

-- 5. Contar el total de empresas por ciudad

SELECT city_id, cm.name AS nombre_ciudad, COUNT(*) AS total_empresas
FROM companies c
JOIN citiesormunicipalities cm ON cm.code = c.city_id
GROUP BY city_id;

-- 6. Calcular el promedio de precios por unidad de medida

SELECT unitmeasure_id,um.description AS nom_unidad_medida, AVG(price) AS promedio_precio
FROM companyproducts cp
JOIN unitofmeasure um ON um.id = cp.unitmeasure_id
GROUP BY unitmeasure_id
ORDER BY unitmeasure_id ASC;

-- 7. Contar cuántos clientes hay por ciudad

SELECT city_id,cm.name, COUNT(*) AS total_clientes
FROM customers c
JOIN citiesormunicipalities cm ON cm.code = c.city_id
GROUP BY city_id;

-- 8. Calcular planes de membresía por periodo

SELECT period_id, COUNT(*) AS total_planes
FROM membershipperiods
GROUP BY period_id;

-- 9. Ver el promedio de calificaciones dadas por un cliente a sus favoritos

SELECT f.customer_id, AVG(qp.rating) AS promedio_favoritos
FROM favorites f
JOIN details_favorites df ON f.id = df.favorite_id
JOIN quality_products qp ON df.product_id = qp.product_id AND f.customer_id = qp.customer_id
GROUP BY f.customer_id;

-- 10. Consultar la fecha más reciente en que se calificó un producto

SELECT product_id,p.name, MAX(daterating) AS ultima_calificacion
FROM quality_products qp
JOIN products p ON p.id = qp.product_id
GROUP BY product_id;

-- 11. Obtener la desviación estándar de precios por categoría

SELECT p.category_id, STDDEV(cp.price) AS desviacion_estandar
FROM companyproducts cp
JOIN products p ON cp.product_id = p.id
GROUP BY p.category_id;

-- 12. Contar cuántas veces un producto fue favorito

SELECT product_id, p.name, COUNT(*) AS veces_favorito
FROM details_favorites df
JOIN products p ON p.id = df.product_id 
GROUP BY product_id;

-- 13. Calcular el porcentaje de productos evaluados

SELECT 
    COUNT(DISTINCT p.id) AS total_productos,
    COUNT(DISTINCT qp.product_id) AS productos_evaluados,
    (COUNT(DISTINCT qp.product_id) * 100.0 / COUNT(DISTINCT p.id)) AS porcentaje_evaluados
FROM products p
LEFT JOIN quality_products qp ON p.id = qp.product_id;

-- 14. Ver el promedio de rating por encuesta

SELECT poll_id, AVG(rating) AS promedio_rating
FROM rates
GROUP BY poll_id;

-- 15. Calcular el promedio y total de beneficios por plan

SELECT membership_id, COUNT(*) AS total_beneficios
FROM membershipbenefits
GROUP BY membership_id;

-- 16. Obtener media y varianza de precios por empresa

SELECT company_id, AVG(price) AS media_precio, VARIANCE(price) AS varianza_precio
FROM companyproducts
GROUP BY company_id;

--  17. Ver total de productos disponibles en la ciudad del cliente

SELECT c.id AS customer_id, COUNT(DISTINCT cp.product_id) AS productos_disponibles
FROM customers c
JOIN companies co ON c.city_id = co.city_id
JOIN companyproducts cp ON co.id = cp.company_id
GROUP BY c.id;

-- 18. Contar productos únicos por tipo de empresa

SELECT type_id, COUNT(DISTINCT product_id) AS productos_unicos
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
GROUP BY type_id;

-- 19. Ver total de clientes sin correo electrónico registrado

SELECT COUNT(*) AS clientes_sin_correo
FROM customers
WHERE email IS NULL OR email = '';

-- 20. Empresa con más productos calificados

SELECT company_id AS id_empresa,c.name AS nombre_empresa, COUNT(DISTINCT product_id) AS total_calificados
FROM quality_products qp
JOIN companies c ON c.id = qp.company_id
GROUP BY company_id
ORDER BY total_calificados DESC
LIMIT 1;
