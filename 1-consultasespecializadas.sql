-- 1. Historias de Usuario /  Consultas SQL Especializadas

-- 1. Como analista, quiero listar todos los productos con su empresa asociada y el precio más bajo por ciudad (bien)

SELECT 
  p.name AS nombre_producto,
  c.name AS nombre_empresa,
  ci.name AS ciudad,
  MIN(cp.price) AS precio_mas_bajo
FROM 
  companyproducts cp
JOIN products p ON cp.product_id = p.id
JOIN companies c ON cp.company_id = c.id
JOIN citiesormunicipalities ci ON c.city_id = ci.code
GROUP BY 
  p.name, c.name, ci.name;

-- 2. Como administrador, deseo obtener el top 5 de clientes que más productos han calificado en los últimos 6 meses. (bien)

SELECT 
    c.id AS customer_id,
    c.name AS nombre_customer,
    COUNT(*) AS rating_total
FROM quality_products qp
JOIN customers c ON qp.customer_id = c.id
WHERE qp.daterating >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY c.id, c.name
ORDER BY rating_total DESC
LIMIT 5; 

-- 3. Como gerente de ventas, quiero ver la distribución de productos por categoría y unidad de medida. (bien)

SELECT 
    cat.description AS categoria,
    um.description AS unidad_de_medida,
    COUNT(DISTINCT p.id) AS productos_totales
FROM products p
JOIN categories cat ON p.category_id = cat.id
JOIN companyproducts cp ON p.id = cp.product_id
JOIN unitofmeasure um ON cp.unitmeasure_id = um.id
GROUP BY cat.description, um.description
ORDER BY cat.description, productos_totales DESC;

-- 4. Como cliente, quiero saber qué productos tienen calificaciones superiores al promedio general. (bien)

SELECT 
    p.id,
    p.name AS nombre_producto,
    ROUND(AVG(qp.rating), 2) AS promedio_rating_producto
FROM quality_products qp
JOIN products p ON qp.product_id = p.id
GROUP BY p.id, p.name
HAVING AVG(qp.rating) > (
    SELECT AVG(rating) FROM quality_products
)
ORDER BY promedio_rating_producto DESC;

-- 5. Como auditor, quiero conocer todas las empresas que no han recibido ninguna calificación. (bien)

SELECT c.id, 
c.name AS nombre_empresa, 
c.email AS email_empresa
FROM companies c
LEFT JOIN rates r ON c.id = r.company_id
WHERE r.company_id IS NULL;

-- 6. Como operador, deseo obtener los productos que han sido añadidos como favoritos por más de 10 clientes distintos. (bien)

SELECT p.name, COUNT(DISTINCT f.customer_id) AS total_clientes
FROM details_favorites df
JOIN favorites f ON df.favorite_id = f.id
JOIN products p ON df.product_id = p.id
GROUP BY p.id
HAVING total_clientes >= 10;

-- 7. Como gerente regional, quiero obtener todas las empresas activas por ciudad y categoría (bien)

SELECT 
    cm.name AS ciudad,
    cat.description AS categoria,
    co.name AS empresa,
    co.email,
    co.cellphone,
    COUNT(cp.product_id) AS productos_ofrecidos
FROM companies co
JOIN citiesormunicipalities cm ON co.city_id = cm.code
JOIN categories cat ON co.category_id = cat.id
LEFT JOIN companyproducts cp ON co.id = cp.company_id
GROUP BY cm.name, cat.description, co.id, co.name, co.email, co.cellphone
ORDER BY cm.name, cat.description, productos_ofrecidos DESC;

-- 8.Como especialista en marketing, deseo obtener los 10 productos más calificados en cada ciudad. (solo salen de algunas ciudades)

SELECT ci.name AS ciudad, p.name AS producto, COUNT(qp.rating) AS total_calificaciones
FROM quality_products qp
JOIN products p ON qp.product_id = p.id
JOIN companies c ON qp.company_id = c.id
JOIN citiesormunicipalities ci ON c.city_id = ci.code
GROUP BY ci.name, p.id
ORDER BY ci.name, total_calificaciones DESC
LIMIT 10;

-- 9. Como técnico, quiero identificar productos sin unidad de medida asignada (empty)

SELECT 
    p.id AS producto_id,
    p.name AS producto,
    p.detail AS detalle,
    p.price AS precio_base,
    cat.description AS categoria
FROM products p
JOIN categories cat ON p.category_id = cat.id
LEFT JOIN companyproducts cp ON p.id = cp.product_id
WHERE cp.unitmeasure_id IS NULL OR cp.product_id IS NULL
ORDER BY p.name;

-- 10. Como gestor de beneficios, deseo ver los planes de membresía sin beneficios registrados(empty)

SELECT 
    m.id AS membresia_id,
    m.name AS membresia,
    m.description AS descripcion
FROM memberships m
LEFT JOIN membershipbenefits mb ON m.id = mb.membership_id
WHERE mb.membership_id IS NULL
ORDER BY m.name;

-- 11. Como supervisor, quiero obtener los productos de una categoría específica con su promedio de calificación(bien)

SELECT p.name, AVG(qp.rating) AS promedio
FROM products p
JOIN quality_products qp ON p.id = qp.product_id
WHERE p.category_id = 1  -- Cambiar 1 por el ID de la categoría deseada
GROUP BY p.id;

-- 12. Como asesor, deseo obtener los clientes que han comprado productos de más de una empresa(empty)

SELECT 
    cu.name AS cliente,
    cu.email,
    COUNT(DISTINCT qp.company_id) AS empresas_distintas,
    COUNT(qp.product_id) AS productos_calificados
FROM customers cu
JOIN quality_products qp ON cu.id = qp.customer_id
GROUP BY cu.id, cu.name, cu.email
HAVING COUNT(DISTINCT qp.company_id) > 1
ORDER BY empresas_distintas DESC, productos_calificados DESC;

-- 13. Como director, quiero identificar las ciudades con más clientes activos (bien)

SELECT ci.name AS ciudad, COUNT(cu.id) AS total_clientes
FROM customers cu
JOIN citiesormunicipalities ci ON cu.city_id = ci.code
GROUP BY ci.name
ORDER BY total_clientes DESC;

-- 14. Como analista de calidad, deseo obtener el ranking de productos por empresa basado en la media de quality_products(bien)

SELECT 
    co.name AS empresa,
    p.name AS producto,
    AVG(qp.rating) AS calificacion_promedio,
    COUNT(qp.rating) AS total_calificaciones,
    RANK() OVER (PARTITION BY co.id ORDER BY AVG(qp.rating) DESC) AS ranking_empresa
FROM companies co
JOIN quality_products qp ON co.id = qp.company_id
JOIN products p ON qp.product_id = p.id
GROUP BY co.id, co.name, p.id, p.name
ORDER BY co.name, ranking_empresa;

-- 15. Como administrador, quiero listar empresas que ofrecen más de cinco productos distintos(empty)

SELECT 
    co.name AS empresa,
    co.email,
    cm.name AS ciudad,
    cat.description AS categoria_empresa,
    COUNT(DISTINCT cp.product_id) AS productos_ofrecidos,
    AVG(cp.price) AS precio_promedio
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
JOIN citiesormunicipalities cm ON co.city_id = cm.code
JOIN categories cat ON co.category_id = cat.id
GROUP BY co.id, co.name, co.email, cm.name, cat.description
HAVING COUNT(DISTINCT cp.product_id) > 5
ORDER BY productos_ofrecidos DESC;

-- 16. Como cliente, deseo visualizar los productos favoritos que aún no han sido calificados(bien)

SELECT 
    cu.name AS cliente,
    p.name AS producto_favorito,
    p.detail AS detalle,
    co.name AS empresa
FROM customers cu
JOIN favorites f ON cu.id = f.customer_id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
JOIN companies co ON f.company_id = co.id
LEFT JOIN quality_products qp ON (cu.id = qp.customer_id AND p.id = qp.product_id)
WHERE qp.customer_id IS NULL
ORDER BY cu.name, p.name;

-- 17. Como desarrollador, deseo consultar los beneficios asignados a cada audiencia junto con su descripción(bien) / (empty)

SELECT 
    a.name AS audiencia,
    a.description AS descripcion_audiencia,
    b.description AS beneficio,
    b.detail AS detalle_beneficio
FROM audiences a
LEFT JOIN audiencebenefits ab ON a.id = ab.audience_id
LEFT JOIN benefits b ON ab.benefit_id = b.id
ORDER BY a.name, b.description;

-- 18. Como operador logístico, quiero saber en qué ciudades hay empresas sin productos asociados(empty)

SELECT 
    cm.name AS ciudad,
    sr.name AS estado_region,
    co.name AS empresa,
    co.email,
    cat.description AS categoria_empresa
FROM citiesormunicipalities cm
JOIN companies co ON cm.code = co.city_id
JOIN stateorregions sr ON cm.statereg_id = sr.code
JOIN categories cat ON co.category_id = cat.id
LEFT JOIN companyproducts cp ON co.id = cp.company_id
WHERE cp.company_id IS NULL
ORDER BY cm.name, co.name;

-- 19. Como técnico, deseo obtener todas las empresas con productos duplicados por nombre(empty)

SELECT 
    co.name AS empresa,
    p.name AS producto_duplicado,
    COUNT(*) AS veces_duplicado,
    GROUP_CONCAT(DISTINCT cp.price) AS precios_diferentes
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
JOIN products p ON cp.product_id = p.id
GROUP BY co.id, co.name, p.name
HAVING COUNT(*) > 1
ORDER BY co.name, veces_duplicado DESC;

-- 20. Como analista, quiero una vista resumen de clientes, productos favoritos y promedio de calificación recibido(bien algunos valores votan null)

SELECT 
    cu.name AS cliente,
    cu.email,
    cm.name AS ciudad_cliente,
    COUNT(DISTINCT f.id) AS total_favoritos,
    COUNT(DISTINCT df.product_id) AS productos_favoritos_unicos,
    COUNT(DISTINCT qp.product_id) AS productos_calificados,
    AVG(qp.rating) AS promedio_calificaciones_dadas,
    MAX(qp.daterating) AS ultima_calificacion
FROM customers cu
JOIN citiesormunicipalities cm ON cu.city_id = cm.code
LEFT JOIN favorites f ON cu.id = f.customer_id
LEFT JOIN details_favorites df ON f.id = df.favorite_id
LEFT JOIN quality_products qp ON cu.id = qp.customer_id
GROUP BY cu.id, cu.name, cu.email, cm.name
ORDER BY total_favoritos DESC, promedio_calificaciones_dadas DESC;
