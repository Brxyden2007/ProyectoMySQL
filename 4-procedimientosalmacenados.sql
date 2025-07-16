-- 4. Procedimientos Almacenados (20 pts)

-- 1. Registrar una nueva calificación y actualizar el promedio

DELIMITER $$

CREATE PROCEDURE registrar_calificacion (
    IN p_product_id INT,
    IN p_customer_id INT,
    IN p_company_id VARCHAR(20),
    IN p_poll_id INT,
    IN p_rating DECIMAL(2,1)
)
BEGIN
    INSERT INTO rates (customer_id, company_id, poll_id, daterating, rating)
    VALUES (p_customer_id, p_company_id, p_poll_id, NOW(), p_rating);

END$$
DELIMITER ;

CALL registrar_calificacion(1, 1, 'EMP001', 1, 4.5);

-- 2.  Insertar empresa y asociar productos por defecto
 
DELIMITER $$

CREATE PROCEDURE insertar_empresa_y_productos_defecto (
    IN p_id VARCHAR(20),
    IN p_type_id INT,
    IN p_name VARCHAR(100),
    IN p_category_id INT,
    IN p_city_id VARCHAR(10),
    IN p_audience_id INT,
    IN p_cellphone VARCHAR(20),
    IN p_email VARCHAR(100)
)
BEGIN
    INSERT INTO companies (id, type_id, name, category_id, city_id, audience_id, cellphone, email)
    VALUES (p_id, p_type_id, p_name, p_category_id, p_city_id, p_audience_id, p_cellphone, p_email);

    INSERT INTO companyproducts (company_id, product_id, price, unitmeasure_id)
    VALUES (p_id, 1, 10000, 1),
           (p_id, 9, 120000, 8);
END$$
DELIMITER ;

CALL insertar_empresa_y_productos_defecto(
    'EMP999',    
    1,           
    'Nueva Empresa XYZ',
    1,           
    '11001',     
    1,           
    '3101234567',
    'xyz@nueva.com' 
);

-- 3. Añadir producto favorito validando duplicados

DELIMITER $$

CREATE PROCEDURE agregar_producto_favorito (
    IN p_customer_id INT,
    IN p_company_id VARCHAR(20),
    IN p_product_id INT
)
BEGIN
    DECLARE v_fav_id INT;

    SELECT id INTO v_fav_id
    FROM favorites
    WHERE customer_id = p_customer_id AND company_id = p_company_id;

    IF v_fav_id IS NULL THEN
        INSERT INTO favorites (customer_id, company_id)
        VALUES (p_customer_id, p_company_id);

        SET v_fav_id = LAST_INSERT_ID();
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM details_favorites
        WHERE favorite_id = v_fav_id AND product_id = p_product_id
    ) THEN
        INSERT INTO details_favorites (favorite_id, product_id)
        VALUES (v_fav_id, p_product_id);
    END IF;
END$$
DELIMITER ;

CALL agregar_producto_favorito(
    1,           
    'EMP001',    
    1           
);

-- 4. Generar resumen mensual de calificaciones por empresa

DELIMITER $$

CREATE PROCEDURE generar_resumen_mensual()
BEGIN
    INSERT INTO resumen_calificaciones (company_id, mes_anio, promedio)
    SELECT company_id,
           DATE_FORMAT(daterating, '%Y-%m'),
           AVG(rating)
    FROM rates
    GROUP BY company_id, DATE_FORMAT(daterating, '%Y-%m');
END$$
DELIMITER ;

CALL generar_resumen_mensual();

-- 5. Calcular beneficios activos por membresía

DELIMITER //

CREATE PROCEDURE obtener_beneficios_por_membresia()
BEGIN
  SELECT mb.membership_id, b.description
  FROM membershipbenefits mb
  JOIN benefits b ON mb.benefit_id = b.id;
END //

DELIMITER ;

CALL obtener_beneficios_por_membresia;

-- 6. Eliminar productos huérfanos

DELIMITER //
CREATE PROCEDURE eliminar_productos_huerfanos()
BEGIN
    DELETE FROM products
    WHERE id NOT IN (SELECT DISTINCT product_id FROM quality_products)
      AND id NOT IN (SELECT DISTINCT product_id FROM companyproducts);
END //
DELIMITER ;

CALL eliminar_productos_huerfanos();

-- 7. Actualizar precios de productos por categoría

DELIMITER //
CREATE PROCEDURE actualizar_precios_categoria(
    IN categoria INT,
    IN factor DECIMAL(5,2)
)
BEGIN
    UPDATE companyproducts cp
    JOIN products p ON cp.product_id = p.id
    SET cp.price = cp.price * factor
    WHERE p.category_id = categoria;
END //
DELIMITER ;

CALL actualizar_precios_categoria(2, 1.10);

-- 8. Validar inconsistencia entre rates y quality_products (no pude)

DELIMITER $$

CREATE PROCEDURE validar_inconsistencias_rates_quality()
BEGIN
    INSERT INTO errores_log (descripcion)
    SELECT CONCAT('Inconsistencia: rate sin entry en quality_products - Cliente: ', r.customer_id, ', Empresa: ', r.company_id, ', Encuesta: ', r.poll_id)
    FROM rates r
    LEFT JOIN quality_products q
        ON r.customer_id = q.customer_id
       AND r.company_id = q.company_id
       AND r.poll_id = q.poll_id
    WHERE q.customer_id IS NULL;
END $$
DELIMITER ;

CALL validar_inconsistencias_rates_quality();

-- 9. Asignar beneficios a nuevas audiencias

DELIMITER //
CREATE PROCEDURE asignar_beneficio_audiencia(
    IN beneficio INT,
    IN audiencia INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM audiencebenefits
        WHERE benefit_id = beneficio AND audience_id = audiencia
    ) THEN
        INSERT INTO audiencebenefits (benefit_id, audience_id)
        VALUES (beneficio, audiencia);
    END IF;
END //
DELIMITER ;

CALL asignar_beneficio_audiencia(1, 2);

-- 10. Activar planes de membresía vencidos con pago confirmado

ALTER TABLE membershipperiods ADD COLUMN status VARCHAR(20) DEFAULT 'INACTIVA';
ALTER TABLE membershipperiods ADD COLUMN pago_confirmado BOOLEAN DEFAULT FALSE;

DELIMITER $$

CREATE PROCEDURE activar_planes_vencidos_con_pago()
BEGIN
    UPDATE membershipperiods
    SET status = 'ACTIVA'
    WHERE pago_confirmado = TRUE;
END $$
DELIMITER ;

CALL activar_planes_vencidos_con_pago();

-- 11. Listar productos favoritos del cliente con su calificación

DELIMITER $$
CREATE PROCEDURE sp_favoritos_con_promedio(IN p_customer_id INT)
BEGIN
    SELECT 
        p.name AS producto,
        AVG(r.rating) AS promedio_rating
    FROM favorites f
    JOIN details_favorites df ON df.favorite_id = f.id
    JOIN products p ON p.id = df.product_id
    LEFT JOIN rates r ON r.customer_id = f.customer_id
                    AND r.poll_id IN (
                        SELECT id FROM polls WHERE name LIKE CONCAT('%', p.name, '%')
                    )
    WHERE f.customer_id = p_customer_id
    GROUP BY p.id;
END $$
DELIMITER ;

CALL sp_favoritos_con_promedio(1);

-- 12. Registrar encuesta y sus preguntas asociadas

DELIMITER $$
CREATE PROCEDURE sp_registrar_encuesta_con_preguntas(
    IN p_name VARCHAR(80),
    IN p_description TEXT,
    IN p_category_id INT,
    IN p_preguntas TEXT
)
BEGIN
    DECLARE encuesta_id INT;

    INSERT INTO polls(name, description, categorypoll_id, isactive)
    VALUES (p_name, p_description, p_category_id, 1);

    SET encuesta_id = LAST_INSERT_ID();

    WHILE LOCATE(';', p_preguntas) > 0 DO
        INSERT INTO poll_questions(poll_id, question)
        VALUES (
            encuesta_id,
            TRIM(SUBSTRING_INDEX(p_preguntas, ';', 1))
        );
        SET p_preguntas = SUBSTRING(p_preguntas FROM LOCATE(';', p_preguntas) + 1);
    END WHILE;

    IF LENGTH(TRIM(p_preguntas)) > 0 THEN
        INSERT INTO poll_questions(poll_id, question)
        VALUES (encuesta_id, TRIM(p_preguntas));
    END IF;
END $$
DELIMITER ;

CALL sp_registrar_encuesta_con_preguntas(
  'Encuesta de satisfacción cliente #2',
  'Evaluación sobre la experiencia de usuario',
  1,
  '¿Cómo calificarías el producto?;¿Recibiste atención adecuada?;¿Recomendarías este producto?'
);

-- 13. Eliminar favoritos antiguos sin calificaciones

ALTER TABLE details_favorites
ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;

DELIMITER $$

CREATE PROCEDURE eliminar_favoritos_antiguos_sin_calificaciones()
BEGIN
    DELETE FROM details_favorites df
    WHERE df.created_at < NOW() - INTERVAL 12 MONTH
      AND NOT EXISTS (
          SELECT 1
          FROM quality_products q
          WHERE q.product_id = df.product_id
      );
END $$
DELIMITER ;

CALL eliminar_favoritos_antiguos_sin_calificaciones();

-- 14. Asociar beneficios automáticamente por audiencia

DELIMITER $$

CREATE PROCEDURE asociar_beneficios_audiencia(IN audiencia_id INT)
BEGIN
    INSERT IGNORE INTO audiencebenefits (audience_id, benefit_id)
    SELECT audiencia_id, b.id
    FROM benefits b;
END $$
DELIMITER ;

CALL asociar_beneficios_audiencia(1);

-- 15. Historial de cambios de precio

DELIMITER $$

CREATE PROCEDURE registrar_cambio_precio(
    IN empresa_id VARCHAR(20),
    IN producto_id INT,
    IN nuevo_precio DOUBLE
)
BEGIN
    DECLARE precio_actual DOUBLE;

    SELECT price INTO precio_actual
    FROM companyproducts
    WHERE company_id = empresa_id AND product_id = producto_id;

    IF precio_actual IS NOT NULL AND precio_actual <> nuevo_precio THEN
        
        INSERT INTO historial_precios (company_id, product_id, precio_anterior, precio_nuevo)
        VALUES (empresa_id, producto_id, precio_actual, nuevo_precio);

        UPDATE companyproducts
        SET price = nuevo_precio
        WHERE company_id = empresa_id AND product_id = producto_id;
    END IF;
END $$
DELIMITER ;

CALL registrar_cambio_precio('EMP001', 1, 119.99);

-- 16. Registrar encuesta activa automáticamente

DELIMITER $$
CREATE PROCEDURE registrar_encuesta_activa (
    IN nombre_encuesta VARCHAR(80),
    IN descripcion_encuesta TEXT,
    IN categoria_id INT
)
BEGIN
    INSERT INTO polls (name, description, isactive, categorypoll_id)
    VALUES (nombre_encuesta, descripcion_encuesta, TRUE, categoria_id);
END$$
DELIMITER ;

CALL registrar_encuesta_activa('Encuesta de calidad semanal', 'Evaluación semanal de productos.', 1);

-- 17. Actualizar unidad de medida de productos sin afectar ventas

DELIMITER $$
CREATE PROCEDURE actualizar_unidad_si_no_vendido (
    IN prod_id INT,
    IN nueva_unidad INT
)
BEGIN
    DECLARE ventas INT;

    SELECT COUNT(*) INTO ventas
    FROM quality_products
    WHERE product_id = prod_id;

    IF ventas = 0 THEN
        UPDATE companyproducts
        SET unitmeasure_id = nueva_unidad
        WHERE product_id = prod_id;
    END IF;
END$$
DELIMITER ;

CALL actualizar_unidad_si_no_vendido(1, 2);

-- 18. Recalcular promedios de calidad semanalmente

DELIMITER $$
CREATE PROCEDURE recalcular_promedios_calidad()
BEGIN
    UPDATE products p
    JOIN (
        SELECT product_id, AVG(rating) AS promedio
        FROM quality_products
        GROUP BY product_id
    ) q ON p.id = q.product_id
    SET p.price = q.promedio;
END$$
DELIMITER ;

CALL recalcular_promedios_calidad();

-- 19. Validar claves foráneas entre calificaciones y encuestas

DELIMITER $$
CREATE PROCEDURE validar_rates_sin_poll()
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS errores_poll_rate (
        customer_id INT,
        company_id VARCHAR(20),
        poll_id INT,
        error TEXT
    );

    INSERT INTO errores_poll_rate (customer_id, company_id, poll_id, error)
    SELECT r.customer_id, r.company_id, r.poll_id, 'Poll no existe'
    FROM rates r
    LEFT JOIN polls p ON r.poll_id = p.id
    WHERE p.id IS NULL;
END$$
DELIMITER ;

CALL validar_rates_sin_poll();

-- 20. Generar el top 10 de productos más calificados por ciudad

DELIMITER $$
CREATE PROCEDURE top_10_productos_por_ciudad()
BEGIN
    SELECT c.city_id, cp.product_id, COUNT(*) AS total_calificaciones
    FROM rates r
    JOIN companies c ON r.company_id = c.id
    JOIN quality_products qp ON r.customer_id = qp.customer_id AND r.poll_id = qp.poll_id AND r.company_id = qp.company_id
    JOIN companyproducts cp ON cp.company_id = c.id
    GROUP BY c.city_id, cp.product_id
    ORDER BY c.city_id, total_calificaciones DESC
    LIMIT 10;
END$$
DELIMITER ;

CALL top_10_productos_por_ciudad();
