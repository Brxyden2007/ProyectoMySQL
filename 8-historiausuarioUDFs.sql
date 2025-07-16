-- 8. Historias de Usuario con Funciones Definidas por el Usuario (UDF)

-- 1. Como analista, quiero una función que calcule el promedio ponderado de calidad de un producto basado en sus calificaciones y fecha de evaluación.

DELIMITER $$
CREATE FUNCTION calcular_promedio_ponderado(p_product_id INT)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE resultado DOUBLE;
    SELECT SUM(rating * DATEDIFF(CURDATE(), daterating)) / SUM(DATEDIFF(CURDATE(), daterating))
    INTO resultado
    FROM quality_products
    WHERE product_id = p_product_id;
    RETURN resultado;
END $$
DELIMITER ;

-- 2. Como auditor, deseo una función que determine si un producto ha sido calificado recientemente (últimos 30 días).

DELIMITER $$
CREATE FUNCTION es_calificacion_reciente(p_fecha DATE)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    RETURN DATEDIFF(CURDATE(), p_fecha) <= 30;
END $$
DELIMITER ;

-- 3. Como desarrollador, quiero una función que reciba un product_id y devuelva el nombre completo de la empresa que lo vende.

DELIMITER $$
CREATE FUNCTION obtener_empresa_producto(p_product_id INT)
RETURNS VARCHAR(80)
DETERMINISTIC
BEGIN
    DECLARE empresa_nombre VARCHAR(80);
    SELECT c.name INTO empresa_nombre
    FROM companies c
    JOIN companyproducts cp ON cp.company_id = c.id
    WHERE cp.product_id = p_product_id
    LIMIT 1;
    RETURN empresa_nombre;
END $$
DELIMITER ;

-- 4. Como operador, deseo una función que, dado un customer_id, me indique si el cliente tiene una membresía activa.

DELIMITER $$
CREATE FUNCTION tiene_membresia_activa(p_customer_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM membershipperiods mp
        JOIN memberships m ON m.id = mp.membership_id
        WHERE CURRENT_DATE() BETWEEN mp.start_date AND mp.end_date
    );
END $$
DELIMITER ;

-- 5. Como administrador, quiero una función que valide si una ciudad tiene más de X empresas registradas, recibiendo la ciudad y el número como parámetros. 

DELIMITER $$
CREATE FUNCTION ciudad_supera_empresas(p_city_id VARCHAR(6), p_limite INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total FROM companies WHERE city_id = p_city_id;
    RETURN total > p_limite;
END $$
DELIMITER ;

-- 6. Como gerente, deseo una función que, dado un rate_id, me devuelva una descripción textual de la calificación (por ejemplo, “Muy bueno”, “Regular”).

DELIMITER $$
CREATE FUNCTION descripcion_calificacion(p_valor INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    CASE
        WHEN p_valor = 5 THEN RETURN 'Excelente';
        WHEN p_valor = 4 THEN RETURN 'Muy bueno';
        WHEN p_valor = 3 THEN RETURN 'Bueno';
        WHEN p_valor = 2 THEN RETURN 'Regular';
        WHEN p_valor = 1 THEN RETURN 'Malo';
        ELSE RETURN 'Desconocido';
    END CASE;
END $$
DELIMITER ;

-- 7. Como técnico, quiero una función que devuelva el estado de un producto en función de su evaluación (ej. “Aceptable”, “Crítico”).

DELIMITER $$
CREATE FUNCTION estado_producto(p_product_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE promedio DOUBLE;
    SELECT AVG(rating) INTO promedio FROM quality_products WHERE product_id = p_product_id;
    IF promedio >= 4 THEN RETURN 'Optimo';
    ELSEIF promedio >= 2.5 THEN RETURN 'Aceptable';
    ELSE RETURN 'Critico';
    END IF;
END $$
DELIMITER ;

-- 8. Como cliente, deseo una función que indique si un producto está entre mis favoritos, recibiendo el product_id y mi customer_id.

DELIMITER $$
CREATE FUNCTION es_favorito(p_customer_id INT, p_product_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM favorites f
        JOIN details_favorites df ON df.favorite_id = f.id
        WHERE f.customer_id = p_customer_id AND df.product_id = p_product_id
    );
END $$
DELIMITER ;

-- 9. Como gestor de beneficios, quiero una función que determine si un beneficio está asignado a una audiencia específica, retornando verdadero o falso.

DELIMITER $$
CREATE FUNCTION beneficio_asignado_audiencia(p_benefit_id INT, p_audience_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM audiencebenefits
        WHERE benefit_id = p_benefit_id AND audience_id = p_audience_id
    );
END $$
DELIMITER ;

-- 10. Como auditor, deseo una función que reciba una fecha y determine si se encuentra dentro de un rango de membresía activa.

DELIMITER $$
CREATE FUNCTION fecha_en_membresia(p_fecha DATE, p_customer_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM membershipperiods
        WHERE p_fecha BETWEEN '2024-01-01' AND '2024-12-31'
    );
END $$
DELIMITER ;

-- 11. Como desarrollador, quiero una función que calcule el porcentaje de calificaciones positivas de un producto respecto al total.

DELIMITER $$
CREATE FUNCTION porcentaje_positivas(p_product_id INT)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE total INT;
    DECLARE positivas INT;
    SELECT COUNT(*) INTO total FROM quality_products WHERE product_id = p_product_id;
    SELECT COUNT(*) INTO positivas FROM quality_products WHERE product_id = p_product_id AND rating >= 4;
    IF total = 0 THEN RETURN 0;
    ELSE RETURN (positivas / total) * 100;
    END IF;
END $$
DELIMITER ;

-- 12. Como supervisor, deseo una función que calcule la edad de una calificación, en días, desde la fecha actual.

DELIMITER $$
CREATE FUNCTION edad_calificacion(p_fecha DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN DATEDIFF(CURRENT_DATE(), p_fecha);
END $$
DELIMITER ;

-- 13. Como operador, quiero una función que, dado un company_id, devuelva la cantidad de productos únicos asociados a esa empresa.

DELIMITER $$
CREATE FUNCTION productos_por_empresa(p_company_id VARCHAR(20))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE cantidad INT;
    SELECT COUNT(DISTINCT product_id) INTO cantidad FROM companyproducts WHERE company_id = p_company_id;
    RETURN cantidad;
END $$
DELIMITER ;

-- 14. Como gerente, deseo una función que retorne el nivel de actividad de un cliente (frecuente, esporádico, inactivo), según su número de calificaciones.

DELIMITER $$
CREATE FUNCTION nivel_actividad_cliente(p_customer_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE cantidad INT;
    SELECT COUNT(*) INTO cantidad FROM rates WHERE customer_id = p_customer_id;
    IF cantidad >= 10 THEN RETURN 'Frecuente';
    ELSEIF cantidad >= 3 THEN RETURN 'Esporadico';
    ELSE RETURN 'Inactivo';
    END IF;
END $$
DELIMITER ;

-- 15. Como administrador, quiero una función que calcule el precio promedio ponderado de un producto, tomando en cuenta su uso en favoritos.

DELIMITER $$
CREATE FUNCTION precio_ponderado_favoritos(p_product_id INT)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE total DOUBLE;
    DECLARE cantidad INT;
    SELECT SUM(p.price), COUNT(*)
    INTO total, cantidad
    FROM details_favorites df
    JOIN favorites f ON f.id = df.favorite_id
    JOIN companyproducts p ON p.product_id = df.product_id
    WHERE df.product_id = p_product_id;
    IF cantidad = 0 THEN RETURN 0;
    ELSE RETURN total / cantidad;
    END IF;
END $$
DELIMITER ;

-- 16. Como técnico, deseo una función que me indique si un benefit_id está asignado a más de una audiencia o membresía (valor booleano).

DELIMITER $$
CREATE FUNCTION beneficio_mas_de_una_asignacion(p_benefit_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SELECT COUNT(*) INTO total FROM (
        SELECT benefit_id FROM audiencebenefits WHERE benefit_id = p_benefit_id
        UNION ALL
        SELECT benefit_id FROM membershipbenefits WHERE benefit_id = p_benefit_id
    ) AS combinados;
    RETURN total > 1;
END $$
DELIMITER ;

-- 17. Como cliente, quiero una función que, dada mi ciudad, retorne un índice de variedad basado en número de empresas y productos.

DELIMITER $$
CREATE FUNCTION indice_variedad_ciudad(p_city_id VARCHAR(6))
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE empresas INT;
    DECLARE productos INT;
    SELECT COUNT(*) INTO empresas FROM companies WHERE city_id = p_city_id;
    SELECT COUNT(DISTINCT cp.product_id) INTO productos
    FROM companies c
    JOIN companyproducts cp ON c.id = cp.company_id
    WHERE c.city_id = p_city_id;
    IF empresas = 0 THEN RETURN 0;
    ELSE RETURN productos / empresas;
    END IF;
END $$
DELIMITER ;

-- 18. Como gestor de calidad, deseo una función que evalúe si un producto debe ser desactivado por tener baja calificación histórica.

DELIMITER $$
CREATE FUNCTION desactivar_por_baja_calidad(p_product_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE promedio DOUBLE;
    SELECT AVG(rating) INTO promedio FROM quality_products WHERE product_id = p_product_id;
    RETURN promedio < 2;
END $$
DELIMITER ;

-- 19. Como desarrollador, quiero una función que calcule el índice de popularidad de un producto (combinando favoritos y ratings).

DELIMITER $$
CREATE FUNCTION indice_popularidad(p_product_id INT)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    DECLARE favoritos INT;
    DECLARE calificaciones INT;
    SELECT COUNT(*) INTO favoritos
    FROM details_favorites WHERE product_id = p_product_id;
    SELECT COUNT(*) INTO calificaciones
    FROM quality_products WHERE product_id = p_product_id;
    RETURN favoritos + calificaciones;
END $$
DELIMITER ;

-- 20. Como auditor, deseo una función que genere un código único basado en el nombre del producto y su fecha de creación.

DELIMITER $$
CREATE FUNCTION codigo_unico_producto(p_product_id INT)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE nombre VARCHAR(60);
    DECLARE creado DATETIME;
    DECLARE codigo_final VARCHAR(100);
    SELECT name INTO nombre FROM products WHERE id = p_product_id;
    SET creado = NOW();
    SET codigo_final = CONCAT(UCASE(LEFT(nombre, 3)), '-', DATE_FORMAT(creado, '%Y%m%d%H%i%s'));
    RETURN codigo_final;
END $$
DELIMITER ;
