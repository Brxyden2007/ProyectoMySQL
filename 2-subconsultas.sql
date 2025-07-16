-- SUBCONSULTAS (20 PTS)

-- 1. Como gerente, quiero ver los productos cuyo precio esté por encima del promedio de su categoría (bien)

SELECT p.name, p.price, p.category_id
FROM products p
WHERE p.price > (
    SELECT AVG(p2.price)
    FROM products p2
    WHERE p2.category_id = p.category_id
);

-- 2. Como administrador, deseo listar las empresas que tienen más productos que la media de empresas (bien)

SELECT c.id, c.name
FROM companies c
WHERE (
    SELECT COUNT(*)
    FROM companyproducts cp
    WHERE cp.company_id = c.id
) > (
    SELECT AVG(product_count) FROM (
        SELECT COUNT(*) AS product_count
        FROM companyproducts
        GROUP BY company_id
    ) AS avg_products
);

-- 3. Como cliente, quiero ver mis productos favoritos que han sido calificados por otros clientes (bien)

SELECT 
    p.name AS producto_favorito,
    p.detail AS detalle,
    co.name AS empresa,
    AVG(qp.rating) AS calificacion_promedio,
    COUNT(qp.rating) AS total_calificaciones_otros
FROM customers cu
JOIN favorites f ON cu.id = f.customer_id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
JOIN companies co ON f.company_id = co.id
JOIN quality_products qp ON p.id = qp.product_id
WHERE cu.id = 1 -- Cambiar por el ID del cliente actual
  AND qp.customer_id != cu.id -- Excluir calificaciones del mismo cliente
GROUP BY p.id, p.name, p.detail, co.name
ORDER BY calificacion_promedio DESC;

-- 4. Como supervisor, deseo obtener los productos con el mayor número de veces añadidos como favoritos (bien)

SELECT p.name, COUNT(*) AS veces_favorito
FROM details_favorites df
JOIN products p ON df.product_id = p.id
GROUP BY p.id
HAVING COUNT(*) = (
    SELECT MAX(fav_count)
    FROM (
        SELECT COUNT(*) AS fav_count
        FROM details_favorites
        GROUP BY product_id
    ) AS sub
);

-- 5. Como técnico, quiero listar los clientes cuyo correo no aparece en la tabla rates ni en quality_products (bien)

SELECT c.id, c.name
FROM customers c
WHERE c.email IS NOT NULL
  AND c.id NOT IN (SELECT DISTINCT customer_id FROM rates)
  AND c.id NOT IN (SELECT DISTINCT customer_id FROM quality_products);

-- 6. Como gestor de calidad, quiero obtener los productos con una calificación inferior al mínimo de su categoría (empty, no hay ningún inferior)

SELECT p.name, q.rating
FROM quality_products q
JOIN products p ON q.product_id = p.id
WHERE q.rating < (
    SELECT MIN(q2.rating)
    FROM quality_products q2
    JOIN products p2 ON q2.product_id = p2.id
    WHERE p2.category_id = p.category_id
);

-- 7. Como desarrollador, deseo listar las ciudades que no tienen clientes registrados(bien, antes eran 1118 ahora son 1109, por ende, hay 9 ciudades registradas)

SELECT 
    cm.name AS ciudad,
    sr.name AS estado_region,
    co.name AS pais
FROM citiesormunicipalities cm
JOIN stateorregions sr ON cm.statereg_id = sr.code
JOIN countries co ON sr.country_id = co.isocode
WHERE cm.code NOT IN (
    SELECT DISTINCT city_id 
    FROM customers 
    WHERE city_id IS NOT NULL
)
ORDER BY co.name, sr.name, cm.name;

-- 8. Como administrador, quiero ver los productos que no han sido evaluados en ninguna encuesta(bien)

SELECT p.name
FROM products p
WHERE p.id NOT IN (
    SELECT DISTINCT product_id FROM quality_products
);

-- 9. Como auditor, quiero listar los beneficios que no están asignados a ninguna audiencia(empty, todos están listados por audiencia)

SELECT b.id, b.description
FROM benefits b
WHERE b.id NOT IN (
    SELECT DISTINCT benefit_id FROM audiencebenefits
);

-- 10. Como cliente, deseo obtener mis productos favoritos que no están disponibles actualmente en ninguna empresa(bien, de por si, todos tienen productos favoritos asi que seria empty)

SELECT DISTINCT p.name
FROM products p
WHERE p.id IN (
    SELECT product_id FROM details_favorites
)
AND p.id NOT IN (
    SELECT product_id FROM companyproducts
);

-- 11. Como director, deseo consultar los productos vendidos en empresas cuya ciudad tenga menos de tres empresas registradas(bien)

SELECT 
    p.name AS producto,
    cat.description AS categoria,
    co.name AS empresa,
    cm.name AS ciudad,
    cp.price AS precio,
    (SELECT COUNT(*) 
     FROM companies c2 
     WHERE c2.city_id = co.city_id) AS empresas_en_ciudad
FROM products p
JOIN categories cat ON p.category_id = cat.id
JOIN companyproducts cp ON p.id = cp.product_id
JOIN companies co ON cp.company_id = co.id
JOIN citiesormunicipalities cm ON co.city_id = cm.code
WHERE co.city_id IN (
    SELECT city_id 
    FROM companies 
    GROUP BY city_id 
    HAVING COUNT(*) < 3
)
ORDER BY cm.name, co.name, p.name;

-- 12. Como analista, quiero ver los productos con calidad superior al promedio de todos los productos(bien)

SELECT p.name, AVG(q.rating) AS promedio
FROM quality_products q
JOIN products p ON q.product_id = p.id
GROUP BY p.id
HAVING AVG(q.rating) > (
    SELECT AVG(rating) FROM quality_products
);

-- 13. Como gestor, quiero ver empresas que sólo venden productos de una única categoría(bien)

SELECT c.name, c.email
FROM companies c
WHERE (
    SELECT COUNT(DISTINCT p.category_id)
    FROM companyproducts cp
    JOIN products p ON cp.product_id = p.id
    WHERE cp.company_id = c.id
) = 1;

-- 14. Como gerente comercial, quiero consultar los productos con el mayor precio entre todas las empresas.

SELECT p.name, cp.price
FROM companyproducts cp
JOIN products p ON cp.product_id = p.id
WHERE cp.price = (
    SELECT MAX(price) FROM companyproducts
);

-- 15. Como cliente, quiero saber si algún producto de mis favoritos ha sido calificado por otro cliente con más de 4 estrellas.(bien)

SELECT 
    p.name AS producto_favorito,
    'SÍ' AS tiene_mas4_estrellas
FROM customers cu
JOIN favorites f ON cu.id = f.customer_id
JOIN details_favorites df ON f.id = df.favorite_id
JOIN products p ON df.product_id = p.id
WHERE cu.id = 1 -- Cambiar por ID del cliente
  AND p.id IN (
      SELECT product_id 
      FROM quality_products 
      WHERE customer_id != 1 AND rating > 4
  );

-- 16. Como operador, quiero saber qué productos no tienen imagen asignada pero sí han sido calificados.(empty, todos tienen image)

SELECT 
    p.name AS producto,
    COUNT(qp.rating) AS total_calificaciones
FROM products p
JOIN quality_products qp ON p.id = qp.product_id
WHERE (p.image IS NULL OR p.image = '')
GROUP BY p.id, p.name;

-- 17. Como auditor, quiero ver los planes de membresía sin periodo vigente.(empty, todos están en periodo vigente)

SELECT m.name
FROM memberships m
WHERE m.id NOT IN (
    SELECT DISTINCT membership_id
    FROM membershipperiods
);

-- 18. Como especialista, quiero identificar los beneficios compartidos por más de una audiencia.(bien)

SELECT 
    b.description AS beneficio,
    COUNT(ab.audience_id) AS total_audiencias
FROM benefits b
JOIN audiencebenefits ab ON b.id = ab.benefit_id
WHERE b.id IN (
    SELECT benefit_id 
    FROM audiencebenefits 
    GROUP BY benefit_id 
    HAVING COUNT(audience_id) > 1
)
GROUP BY b.id, b.description;

-- 19. Como técnico, quiero encontrar empresas cuyos productos no tengan unidad de medida definida.(empty, todos tienen unidad de medida)

SELECT 
    co.name AS empresa,
    COUNT(cp.product_id) AS productos_sin_unidad
FROM companies co
JOIN companyproducts cp ON co.id = cp.company_id
WHERE cp.unitmeasure_id IS NULL
GROUP BY co.id, co.name;

-- 20. Como gestor de campañas, deseo obtener los clientes con membresía activa y sin productos favoritos

SELECT DISTINCT c.name
FROM customers c
WHERE c.id NOT IN (
    SELECT f.customer_id
    FROM favorites f
)
AND EXISTS (
    SELECT 1
    FROM membershipbenefits mb
    WHERE mb.audience_id = c.audience_id
);
