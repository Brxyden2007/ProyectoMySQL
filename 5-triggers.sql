-- 5. Triggers

-- 1. Actualizar la fecha de modificación de un producto
 
ALTER TABLE products ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

DELIMITER $$
CREATE TRIGGER trg_update_product_timestamp
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
  SET NEW.updated_at = NOW();
END$$
DELIMITER ;

-- 2. Registrar log cuando un cliente califica un producto

DELIMITER $$
CREATE TRIGGER trg_log_rating
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
  INSERT INTO log_acciones (customer_id, company_id, poll_id, accion)
  VALUES (NEW.customer_id, NEW.company_id, NEW.poll_id, 'Calificación registrada');
END$$
DELIMITER ;

-- 3. Impedir insertar productos sin unidad de medida

DELIMITER $$
CREATE TRIGGER trg_prevent_null_unit
BEFORE INSERT ON companyproducts
FOR EACH ROW
BEGIN
  IF NEW.unitmeasure_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se permite insertar productos sin unidad de medida.';
  END IF;
END$$
DELIMITER ;

-- 4. Validar calificaciones no mayores a 5

DELIMITER $$
CREATE TRIGGER trg_max_rating_value
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
  IF NEW.rating > 5 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'La calificación no puede ser mayor a 5.';
  END IF;
END$$
DELIMITER ;

-- 5. Actualizar estado de membresía cuando vence

ALTER TABLE membershipperiods ADD COLUMN end_date DATE;

DELIMITER $$
CREATE TRIGGER trg_check_membership_expiration
BEFORE UPDATE ON membershipperiods
FOR EACH ROW
BEGIN
  IF NEW.end_date < CURDATE() THEN
    SET NEW.status = 'INACTIVA';
  END IF;
END$$
DELIMITER ;

--  6. Evitar duplicados de productos por empresa

DELIMITER //
CREATE TRIGGER trg_prevent_duplicate_product_per_company
BEFORE INSERT ON companyproducts
FOR EACH ROW
BEGIN
    DECLARE existe INT;
    SELECT COUNT(*) INTO existe
    FROM companyproducts
    WHERE company_id = NEW.company_id AND product_id = NEW.product_id;

    IF existe > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ya existe este producto para esta empresa.';
    END IF;
END //
DELIMITER ;

-- 7. Enviar notificación al añadir un favorito

DELIMITER //
CREATE TRIGGER trg_notificar_favorito
AFTER INSERT ON details_favorites
FOR EACH ROW
BEGIN
    INSERT INTO notificaciones (mensaje)
    VALUES (CONCAT('Se añadió el producto ID ', NEW.product_id, ' a favoritos.'));
END //
DELIMITER ;

-- 8. Insertar fila en quality_products tras calificación

DELIMITER //
CREATE TRIGGER trg_insert_quality_after_rate
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    INSERT INTO quality_products (product_id, customer_id, poll_id, company_id, daterating, rating)
    SELECT cp.product_id, NEW.customer_id, NEW.poll_id, NEW.company_id, NEW.daterating, NEW.rating
    FROM companyproducts cp
    WHERE cp.company_id = NEW.company_id
    LIMIT 1;
END //
DELIMITER ;

-- 9. Eliminar favoritos si se elimina el producto

DELIMITER //
CREATE TRIGGER trg_delete_favorites_on_product_delete
AFTER DELETE ON products
FOR EACH ROW
BEGIN
    DELETE FROM details_favorites
    WHERE product_id = OLD.id;
END //
DELIMITER ;

-- 10. Bloquear modificación de audiencias activas

DELIMITER //
CREATE TRIGGER trg_prevent_audience_update
BEFORE UPDATE ON audiences
FOR EACH ROW
BEGIN
    DECLARE usos_empresa INT DEFAULT 0;
    DECLARE usos_cliente INT DEFAULT 0;
    DECLARE usos_beneficios INT DEFAULT 0;
    DECLARE total_usos INT DEFAULT 0;

    SELECT COUNT(*) INTO usos_empresa
    FROM companies
    WHERE audience_id = OLD.id;

    SELECT COUNT(*) INTO usos_cliente
    FROM customers
    WHERE audience_id = OLD.id;

    SELECT COUNT(*) INTO usos_beneficios
    FROM audiencebenefits
    WHERE audience_id = OLD.id;

    SET total_usos = usos_empresa + usos_cliente + usos_beneficios;

    IF total_usos > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede modificar una audiencia que ya está asignada.';
    END IF;
END //
DELIMITER ;

-- 11. Recalcular promedio de calidad del producto tras nueva evaluación

DELIMITER //
CREATE TRIGGER trg_update_avg_quality
AFTER INSERT ON quality_products
FOR EACH ROW
BEGIN
    DECLARE avg_rating DECIMAL(3,2);

    SELECT AVG(rating)
    INTO avg_rating
    FROM quality_products
    WHERE product_id = NEW.product_id;

    UPDATE products
    SET price = avg_rating
    WHERE id = NEW.product_id;
END //
DELIMITER ;

--  12. Registrar asignación de nuevo beneficio

DELIMITER //
CREATE TRIGGER trg_log_new_benefit_membership
AFTER INSERT ON membershipbenefits
FOR EACH ROW
BEGIN
    INSERT INTO bitacora_beneficios (tabla_afectada, registro_id, accion)
    VALUES ('membershipbenefits',
            CONCAT(NEW.membership_id, '-', NEW.period_id, '-', NEW.audience_id, '-', NEW.benefit_id),
            'INSERT');
END //
DELIMITER ;

-- 13. Impedir doble calificación por parte del cliente

DELIMITER //
CREATE TRIGGER trg_prevent_duplicate_rating
BEFORE INSERT ON rates
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM rates
        WHERE customer_id = NEW.customer_id
          AND company_id = NEW.company_id
          AND poll_id = NEW.poll_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Este cliente ya ha calificado este producto en esta encuesta.';
    END IF;
END //
DELIMITER ;

--  14. Validar correos duplicados en clientes

DELIMITER //
CREATE TRIGGER trg_validate_duplicate_email
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM customers WHERE email = NEW.email
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electrónico ya está registrado.';
    END IF;
END //
DELIMITER ;

-- 15. Eliminar detalles de favoritos huérfanos

DELIMITER //
CREATE TRIGGER trg_delete_details_when_favorite_deleted
AFTER DELETE ON favorites
FOR EACH ROW
BEGIN
    DELETE FROM details_favorites
    WHERE favorite_id = OLD.id;
END //
DELIMITER ;

-- 16. Actualizar campo updated_at en companies

ALTER TABLE companies ADD COLUMN updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

DELIMITER //
CREATE TRIGGER trg_update_timestamp_companies
BEFORE UPDATE ON companies
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END //
DELIMITER ;

--  17. Impedir borrar ciudad si hay empresas activas

DELIMITER //
CREATE TRIGGER trg_prevent_delete_city_with_companies
BEFORE DELETE ON citiesormunicipalities
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM companies WHERE city_id = OLD.code
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar la ciudad: existen empresas registradas en ella.';
    END IF;
END //
DELIMITER ;

-- 18. Registrar cambios de estado en encuestas

DELIMITER //
CREATE TRIGGER trg_log_status_change_polls
BEFORE UPDATE ON polls
FOR EACH ROW
BEGIN
    IF OLD.isactive <> NEW.isactive THEN
        INSERT INTO log_estado_polls (poll_id, estado_anterior, estado_nuevo)
        VALUES (OLD.id, OLD.isactive, NEW.isactive);
    END IF;
END //
DELIMITER ;

-- 19. Sincronizar rates y quality_products

DELIMITER //
CREATE TRIGGER trg_sync_quality_products
AFTER INSERT ON rates
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM quality_products
        WHERE customer_id = NEW.customer_id
          AND company_id = NEW.company_id
          AND poll_id = NEW.poll_id
    ) THEN
        INSERT INTO quality_products (product_id, customer_id, poll_id, company_id, daterating, rating)
        VALUES (
            (SELECT cp.product_id
             FROM companyproducts cp
             WHERE cp.company_id = NEW.company_id
             LIMIT 1),
            NEW.customer_id,
            NEW.poll_id,
            NEW.company_id,
            NEW.daterating,
            NEW.rating
        );
    END IF;
END //
DELIMITER ;

-- 20. Eliminar productos sin relación a empresas

DELIMITER //
CREATE TRIGGER trg_delete_product_if_no_companies
AFTER DELETE ON companyproducts
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM companyproducts WHERE product_id = OLD.product_id
    ) THEN
        DELETE FROM products WHERE id = OLD.product_id;
    END IF;
END //
DELIMITER ;
