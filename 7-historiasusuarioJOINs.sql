-- 7. Historias de Usuario con JOINs

-- 1. Ver productos con la empresa que los vende

SELECT 
    c.name AS empresa,
    p.name AS producto,
    cp.price AS precio
FROM companies c
JOIN companyproducts cp ON c.id = cp.company_id
JOIN products p ON p.id = cp.product_id;

-- 2. Mostrar productos favoritos con su empresa y categoría

SELECT 
    cu.name AS cliente,
    p.name AS producto,
    cat.description AS categoria,
    c.name AS empresa
FROM favorites f
JOIN customers cu ON cu.id = f.customer_id
JOIN details_favorites df ON df.favorite_id = f.id
JOIN products p ON p.id = df.product_id
JOIN companyproducts cp ON cp.product_id = p.id AND cp.company_id = f.company_id
JOIN companies c ON c.id = f.company_id
JOIN categories cat ON cat.id = p.category_id;

-- 3. Ver empresas aunque no tengan productos

SELECT 
    c.name AS empresa,
    cp.product_id
FROM companies c
LEFT JOIN companyproducts cp ON c.id = cp.company_id;

-- 4. Ver productos que fueron calificados (o no)

SELECT 
    p.name AS producto,
    r.rating
FROM products p
LEFT JOIN companyproducts cp ON p.id = cp.product_id
LEFT JOIN rates r ON cp.company_id = r.company_id;

-- 5. Ver productos con promedio de calificación y empresa

SELECT 
    p.name AS producto,
    c.name AS empresa,
    AVG(qp.rating) AS promedio_calificacion
FROM products p
JOIN companyproducts cp ON p.id = cp.product_id
JOIN companies c ON c.id = cp.company_id
JOIN quality_products qp ON qp.product_id = p.id AND qp.company_id = c.id
GROUP BY p.name, c.name;

-- 6. Ver clientes y sus calificaciones (si las tienen)

SELECT 
    cu.name AS cliente,
    r.rating,
    r.daterating
FROM customers cu
LEFT JOIN rates r ON cu.id = r.customer_id;

-- 7. Ver favoritos con la última calificación del cliente

SELECT 
    cu.name AS cliente,
    p.name AS producto,
    MAX(r.daterating) AS ultima_calificacion
FROM customers cu
JOIN favorites f ON cu.id = f.customer_id
JOIN details_favorites df ON df.favorite_id = f.id
JOIN products p ON p.id = df.product_id
LEFT JOIN quality_products r ON r.product_id = p.id AND r.customer_id = cu.id
GROUP BY cu.name, p.name;

-- 8. Ver beneficios incluidos en cada plan de membresía

SELECT 
    m.name AS plan,
    b.description AS beneficio
FROM membershipbenefits mb
JOIN memberships m ON m.id = mb.membership_id
JOIN benefits b ON b.id = mb.benefit_id;

-- 9. Ver clientes con membresía activa y sus beneficios

SELECT 
    cu.name AS cliente,
    b.description AS beneficio
FROM customers cu
JOIN audiences a ON a.id = cu.audience_id
JOIN audiencebenefits ab ON ab.audience_id = a.id
JOIN benefits b ON b.id = ab.benefit_id;

-- 10. Ver ciudades con cantidad de empresas

SELECT 
    cm.name AS ciudad,
    COUNT(c.id) AS total_empresas
FROM citiesormunicipalities cm
JOIN companies c ON c.city_id = cm.code
GROUP BY cm.name;

-- 11. Ver encuestas con calificaciones

SELECT 
    p.name AS encuesta,
    r.rating,
    r.daterating
FROM polls p
JOIN rates r ON p.id = r.poll_id;

-- 12. Ver productos evaluados con datos del cliente

SELECT 
    pr.name AS producto,
    cu.name AS cliente,
    qp.rating,
    qp.daterating
FROM quality_products qp
JOIN products pr ON pr.id = qp.product_id
JOIN customers cu ON cu.id = qp.customer_id;

-- 13. Ver productos con audiencia de la empresa

SELECT 
    pr.name AS producto,
    a.name AS audiencia
FROM products pr
JOIN companyproducts cp ON cp.product_id = pr.id
JOIN companies c ON c.id = cp.company_id
JOIN audiences a ON a.id = c.audience_id;

-- 14. Ver clientes con sus productos favoritos

SELECT 
    cu.name AS cliente,
    pr.name AS producto_favorito
FROM customers cu
JOIN favorites f ON f.customer_id = cu.id
JOIN details_favorites df ON df.favorite_id = f.id
JOIN products pr ON pr.id = df.product_id;

-- 15. Ver planes, periodos, precios y beneficios

SELECT 
    m.name AS plan,
    p.name AS periodo,
    mp.price AS precio,
    b.description AS beneficio
FROM memberships m
JOIN membershipperiods mp ON mp.membership_id = m.id
JOIN periods p ON p.id = mp.period_id
JOIN membershipbenefits mb ON mb.membership_id = m.id AND mb.period_id = p.id
JOIN benefits b ON b.id = mb.benefit_id;

-- 16. Ver combinaciones empresa-producto-cliente calificados

SELECT 
    c.name AS empresa,
    pr.name AS producto,
    cu.name AS cliente,
    qp.rating
FROM quality_products qp
JOIN products pr ON pr.id = qp.product_id
JOIN companies c ON c.id = qp.company_id
JOIN customers cu ON cu.id = qp.customer_id;

-- 17. Comparar favoritos con productos calificados

SELECT 
    cu.name AS cliente,
    pr.name AS producto,
    qp.rating
FROM customers cu
JOIN favorites f ON f.customer_id = cu.id
JOIN details_favorites df ON df.favorite_id = f.id
JOIN products pr ON pr.id = df.product_id
JOIN quality_products qp ON qp.product_id = pr.id AND qp.customer_id = cu.id;
 
-- 18. Ver productos ordenados por categoría
 
 SELECT 
    c.description AS categoria,
    pr.name AS producto
FROM products pr
JOIN categories c ON c.id = pr.category_id
ORDER BY c.description, pr.name;
 
-- 19. Ver beneficios por audiencia, incluso vacíos

SELECT 
    a.name AS audiencia,
    b.description AS beneficio
FROM audiences a
LEFT JOIN audiencebenefits ab ON ab.audience_id = a.id
LEFT JOIN benefits b ON b.id = ab.benefit_id;

-- 20. Ver datos cruzados entre calificaciones, encuestas, productos y clientes
 
SELECT 
    cu.name AS cliente,
    po.name AS encuesta,
    pr.name AS producto,
    qp.rating,
    qp.daterating
FROM quality_products qp
JOIN customers cu ON cu.id = qp.customer_id
JOIN polls po ON po.id = qp.poll_id
JOIN products pr ON pr.id = qp.product_id;
