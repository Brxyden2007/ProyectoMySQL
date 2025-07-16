-- 6. Events (Eventos Programados..Usar procedimientos o funciones para cada evento) 

-- 1. Borrar productos sin actividad cada 6 meses

DELIMITER $$
CREATE PROCEDURE sp_borrar_productos_sin_actividad()
BEGIN
    DELETE FROM products
    WHERE id NOT IN (SELECT product_id FROM companyproducts)
      AND id NOT IN (SELECT product_id FROM details_favorites)
      AND id NOT IN (SELECT product_id FROM quality_products);
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_borrar_productos_inactivos
ON SCHEDULE EVERY 6 MONTH
DO
    CALL sp_borrar_productos_sin_actividad();

-- 2. Recalcular el promedio de calificaciones semanalmente

DELIMITER $$
CREATE PROCEDURE sp_actualizar_promedio_productos()
BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS promedio_temp (
        product_id INT,
        promedio DOUBLE
    );

    TRUNCATE TABLE promedio_temp;

    INSERT INTO promedio_temp (product_id, promedio)
    SELECT product_id, AVG(rating)
    FROM quality_products
    GROUP BY product_id;

    UPDATE products p
    JOIN promedio_temp pt ON p.id = pt.product_id
    SET p.price = pt.promedio;

    DROP TEMPORARY TABLE IF EXISTS promedio_temp;
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_promedio_productos
ON SCHEDULE EVERY 1 WEEK
DO
    CALL sp_actualizar_promedio_productos();

-- 3. Actualizar precios según inflación mensual

DELIMITER $$
CREATE PROCEDURE sp_actualizar_precio_inflacion()
BEGIN
    UPDATE companyproducts
    SET price = price * 1.03;
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_actualizar_inflacion
ON SCHEDULE EVERY 1 MONTH
DO
    CALL sp_actualizar_precio_inflacion();

-- 4. Crear backups lógicos diariamente

DELIMITER $$
CREATE PROCEDURE sp_backup_logico()
BEGIN
    CREATE TABLE IF NOT EXISTS products_backup LIKE products;
    INSERT INTO products_backup SELECT * FROM products;

    CREATE TABLE IF NOT EXISTS rates_backup LIKE rates;
    INSERT INTO rates_backup SELECT * FROM rates;
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_backup_logico
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 0 HOUR
DO
    CALL sp_backup_logico();

-- 5. Notificar sobre productos favoritos sin calificar

DELIMITER $$
CREATE PROCEDURE sp_notificar_favoritos_no_calificados()
BEGIN
    CREATE TABLE IF NOT EXISTS recordatorios (
        customer_id INT,
        product_id INT,
        mensaje TEXT,
        PRIMARY KEY (customer_id, product_id)
    );

    INSERT IGNORE INTO recordatorios (customer_id, product_id, mensaje)
    SELECT f.customer_id, df.product_id,
           CONCAT('Tienes un producto favorito sin calificar: ', p.name)
    FROM favorites f
    JOIN details_favorites df ON f.id = df.favorite_id
    JOIN products p ON df.product_id = p.id
    LEFT JOIN quality_products qp ON df.product_id = qp.product_id AND f.customer_id = qp.customer_id
    WHERE qp.product_id IS NULL;
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_notificar_sin_calificar
ON SCHEDULE EVERY 1 WEEK
DO
    CALL sp_notificar_favoritos_no_calificados();

-- 6. Revisar inconsistencias entre empresa y productos

DELIMITER $$
CREATE PROCEDURE sp_revisar_inconsistencias_empresa_producto()
BEGIN
    CREATE TABLE IF NOT EXISTS errores_log (
        id INT AUTO_INCREMENT PRIMARY KEY,
        descripcion TEXT,
        fecha DATETIME DEFAULT NOW()
    );

    INSERT INTO errores_log (descripcion)
    SELECT CONCAT('Producto sin empresa: ', p.id)
    FROM products p
    WHERE NOT EXISTS (
        SELECT 1 FROM companyproducts cp WHERE cp.product_id = p.id
    );

    INSERT INTO errores_log (descripcion)
    SELECT CONCAT('Empresa sin productos: ', c.id)
    FROM companies c
    WHERE NOT EXISTS (
        SELECT 1 FROM companyproducts cp WHERE cp.company_id = c.id
    );
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_inconsistencias_emp_prod
ON SCHEDULE EVERY 1 WEEK
DO
    CALL sp_revisar_inconsistencias_empresa_producto();

-- 7. Archivar membresías vencidas diariamente

DELIMITER $$
CREATE PROCEDURE sp_archivar_membresias_vencidas()
BEGIN
    UPDATE membershipperiods
    SET status = 'INACTIVA'
    WHERE status = 'ACTIVA' AND CURDATE() > DATE_ADD(CURDATE(), INTERVAL -duration_in_months MONTH);
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_archivar_membresias
ON SCHEDULE EVERY 1 DAY
DO
    CALL sp_archivar_membresias_vencidas();

-- 8. Notificar beneficios nuevos a usuarios semanalmente

DELIMITER $$
CREATE PROCEDURE sp_notificar_nuevos_beneficios()
BEGIN
    INSERT INTO notificaciones_events (benefit_id, mensaje)
    SELECT b.id, CONCAT('Nuevo beneficio disponible: ', b.description)
    FROM benefits b
    WHERE b.id NOT IN (
        SELECT benefit_id FROM notificaciones_events WHERE created_at >= NOW() - INTERVAL 7 DAY
    );
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_notificar_beneficios_nuevos
ON SCHEDULE EVERY 1 WEEK
DO
    CALL sp_notificar_nuevos_beneficios();

-- 9.  Calcular cantidad de favoritos por cliente mensualmente

DELIMITER $$
CREATE PROCEDURE sp_resumen_favoritos_mensual()
BEGIN
    INSERT INTO favoritos_resumen (customer_id, cantidad, mes_anio)
    SELECT f.customer_id, COUNT(df.id), DATE_FORMAT(NOW(), '%Y-%m')
    FROM favorites f
    JOIN details_favorites df ON f.id = df.favorite_id
    GROUP BY f.customer_id;
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_resumen_favoritos
ON SCHEDULE EVERY 1 MONTH
DO
    CALL sp_resumen_favoritos_mensual();

-- 10. Validar claves foráneas semanalmente

DELIMITER $$
CREATE PROCEDURE sp_validar_claves_foraneas()
BEGIN
    CREATE TABLE IF NOT EXISTS inconsistencias_fk (
        id INT AUTO_INCREMENT PRIMARY KEY,
        tabla_origen VARCHAR(50),
        mensaje TEXT,
        fecha DATETIME DEFAULT NOW()
    );

    -- Validar que todos los company_id en rates existan en companies
    INSERT INTO inconsistencias_fk (tabla_origen, mensaje)
    SELECT 'rates', CONCAT('Company no válida: ', r.company_id)
    FROM rates r
    LEFT JOIN companies c ON r.company_id = c.id
    WHERE c.id IS NULL;
END$$
DELIMITER ;

CREATE EVENT IF NOT EXISTS ev_validar_fk
ON SCHEDULE EVERY 1 WEEK
DO
    CALL sp_validar_claves_foraneas();

-- 11. Eliminar calificaciones inválidas antiguas

DELIMITER //

CREATE PROCEDURE sp_eliminar_calificaciones_invalidas()
BEGIN
    DELETE FROM rates
    WHERE (rating IS NULL OR rating < 0)
      AND daterating < NOW() - INTERVAL 3 MONTH;
END //
DELIMITER ;

CREATE EVENT ev_eliminar_calificaciones_invalidas
ON SCHEDULE EVERY 1 MONTH
DO
    CALL sp_eliminar_calificaciones_invalidas();

-- 12. Cambiar estado de encuestas inactivas automáticamente

ALTER TABLE polls ADD COLUMN status VARCHAR(20) DEFAULT 'activa';

DELIMITER //

CREATE PROCEDURE sp_actualizar_estado_encuestas()
BEGIN
    UPDATE polls
    SET status = 'inactiva'
    WHERE id NOT IN (
        SELECT DISTINCT poll_id FROM rates
        WHERE daterating >= NOW() - INTERVAL 6 MONTH
    );
END //
DELIMITER ;

CREATE EVENT ev_actualizar_estado_encuestas
ON SCHEDULE EVERY 1 MONTH
DO
    CALL sp_actualizar_estado_encuestas();

-- 13. Registrar auditorías de forma periódica

DELIMITER //

CREATE PROCEDURE sp_registrar_auditoria()
BEGIN
    INSERT INTO auditorias_diarias(fecha, total_productos, total_clientes, total_empresas)
    VALUES (
        CURDATE(),
        (SELECT COUNT(*) FROM products),
        (SELECT COUNT(*) FROM customers),
        (SELECT COUNT(*) FROM companies)
    );
END //
DELIMITER ;

CREATE EVENT ev_registrar_auditoria
ON SCHEDULE EVERY 1 DAY
DO
    CALL sp_registrar_auditoria();

-- 14. Notificar métricas de calidad a empresas

DELIMITER //

CREATE PROCEDURE sp_notificar_metricas_calidad()
BEGIN
    INSERT INTO notificaciones_empresa (company_id, producto_id, promedio)
    SELECT cp.company_id, cp.product_id, AVG(qp.rating)
    FROM quality_products qp
    JOIN companyproducts cp ON cp.product_id = qp.product_id
    GROUP BY cp.company_id, cp.product_id;
END //
DELIMITER ;

CREATE EVENT ev_notificar_metricas_calidad
ON SCHEDULE EVERY 1 WEEK STARTS CURRENT_TIMESTAMP + INTERVAL 1 WEEK
DO
    CALL sp_notificar_metricas_calidad();

-- 15. Recordar renovación de membresías

DELIMITER //

CREATE PROCEDURE sp_recordar_renovacion_membresias()
BEGIN
    INSERT INTO recordatorios (membership_id, period_id, mensaje)
    SELECT membership_id, period_id,
           CONCAT('Su plan vence pronto (', end_date, ')')
    FROM membershipperiods
    WHERE end_date BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY;
END //
DELIMITER ;

CREATE EVENT ev_recordar_renovacion_membresias
ON SCHEDULE EVERY 1 DAY
DO
    CALL sp_recordar_renovacion_membresias();

-- 16. Reordenar estadísticas generales cada semana

DELIMITER //

CREATE PROCEDURE sp_reordenar_estadisticas()
BEGIN
    INSERT INTO estadisticas (fecha, total_productos, total_empresas, total_clientes)
    VALUES (
        CURDATE(),
        (SELECT COUNT(*) FROM products),
        (SELECT COUNT(*) FROM companies),
        (SELECT COUNT(*) FROM customers)
    );
END //
DELIMITER ;

CREATE EVENT ev_reordenar_estadisticas
ON SCHEDULE EVERY 1 WEEK
DO
    CALL sp_reordenar_estadisticas();

-- 17. Crear resúmenes temporales de uso por categoría

DELIMITER //
CREATE PROCEDURE sp_resumen_categoria_temporal()
BEGIN
    DELETE FROM resumen_categoria_temporal;
    INSERT INTO resumen_categoria_temporal (category_id, cantidad)
    SELECT p.category_id, COUNT(qp.product_id)
    FROM quality_products qp
    JOIN products p ON p.id = qp.product_id
    GROUP BY p.category_id;
END //
DELIMITER ;

CREATE EVENT ev_resumen_categoria_temporal
ON SCHEDULE EVERY 1 WEEK
DO
    CALL sp_resumen_categoria_temporal();

-- 18. Actualizar beneficios caducados

ALTER TABLE benefits ADD COLUMN expires_at DATE;
ALTER TABLE benefits ADD COLUMN is_active BOOLEAN DEFAULT TRUE;

DELIMITER //
CREATE PROCEDURE sp_actualizar_beneficios_caducados()
BEGIN
    UPDATE benefits
    SET is_active = FALSE
    WHERE expires_at IS NOT NULL AND expires_at < CURDATE();
END //
DELIMITER ;

CREATE EVENT ev_actualizar_beneficios_caducados
ON SCHEDULE EVERY 1 DAY
DO
    CALL sp_actualizar_beneficios_caducados();

-- 19. Alertar productos sin evaluación anual

DELIMITER //
CREATE PROCEDURE sp_alertar_productos_sin_evaluacion()
BEGIN
    INSERT INTO alertas_productos (product_id, mensaje)
    SELECT p.id, 'Producto sin evaluación en el último año'
    FROM products p
    WHERE p.id NOT IN (
        SELECT DISTINCT qp.product_id
        FROM quality_products qp
        WHERE qp.daterating >= NOW() - INTERVAL 1 YEAR
    );
END //
DELIMITER ;

CREATE EVENT ev_alertar_productos_sin_evaluacion
ON SCHEDULE EVERY 1 MONTH
DO
    CALL sp_alertar_productos_sin_evaluacion();

-- 20. Actualizar precios con índice externo

INSERT INTO inflacion_indice (fecha_aplicacion, factor)
VALUES (CURDATE(), 1.04);

DELIMITER //
CREATE PROCEDURE sp_actualizar_precios_por_indice()
BEGIN
    DECLARE factor_actual DECIMAL(5,3);
    
    SELECT factor INTO factor_actual
    FROM inflacion_indice
    ORDER BY fecha_aplicacion DESC
    LIMIT 1;

    UPDATE companyproducts
    SET price = price * factor_actual;
END //
DELIMITER ;

CREATE EVENT ev_actualizar_precios_por_indice
ON SCHEDULE EVERY 1 MONTH
DO
    CALL sp_actualizar_precios_por_indice();
