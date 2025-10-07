CREATE SCHEMA DB_CasaCambio;
USE DB_CasaCambio;
-- TABLAS
CREATE TABLE categoria_usuario (
  id_categoria INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  limite_transaccion_diario_usd DECIMAL(20,2),
  comision_porcentaje DECIMAL(5,2) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE usuario (
  id_usuario INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  rut VARCHAR(12) NOT NULL UNIQUE,
  pais VARCHAR(60) NOT NULL,
  correo VARCHAR(120) NOT NULL UNIQUE,
  telefono VARCHAR(30) NULL,
  id_categoria INT NULL  
);


CREATE TABLE moneda (
  id_moneda INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  codigo VARCHAR(10) NOT NULL UNIQUE,
  nombre VARCHAR(40) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE tasa_cambio_usd (
  id_tasa INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  id_moneda INT NOT NULL,                
  tasa_usd DECIMAL(20,8) NOT NULL,        -- 1 moneda = X USD
  fecha_actualizacion DATETIME NOT NULL,
  activa BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE transaccion (
  id_transaccion INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  fecha DATETIME NOT NULL,
  id_usuario INT NOT NULL,
  id_moneda_in INT NOT NULL,
  id_moneda_out INT NOT NULL,
  monto_entrada DECIMAL(20,8) NOT NULL,
  monto_salida DECIMAL(20,8) NOT NULL,
  tasa_in_usd INT NOT NULL,    
  tasa_out_usd INT NOT NULL     
);

ALTER TABLE usuario
  ADD CONSTRAINT fk_usuario_categoria
    FOREIGN KEY (id_categoria) REFERENCES categoria_usuario(id_categoria);
    
ALTER TABLE tasa_cambio_usd
  ADD CONSTRAINT fk_tasa_moneda
    FOREIGN KEY (id_moneda) REFERENCES moneda(id_moneda);

ALTER TABLE transaccion
  ADD CONSTRAINT fk_transaccion_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario);

ALTER TABLE transaccion
  ADD CONSTRAINT fk_transaccion_moneda_in
    FOREIGN KEY (id_moneda_in) REFERENCES moneda(id_moneda);

ALTER TABLE transaccion
  ADD CONSTRAINT fk_transaccion_moneda_out
    FOREIGN KEY (id_moneda_out) REFERENCES moneda(id_moneda);

ALTER TABLE transaccion
  ADD CONSTRAINT fk_transaccion_tasa_in
    FOREIGN KEY (tasa_in_usd) REFERENCES tasa_cambio_usd(id_tasa);

ALTER TABLE transaccion
  ADD CONSTRAINT fk_transaccion_tasa_out
    FOREIGN KEY (tasa_out_usd) REFERENCES tasa_cambio_usd(id_tasa);

-- FUNCIONES
 -- FUNCION 1: Convertir Usd a monedas
DELIMITER //

CREATE FUNCTION convertir_usd_a_moneda(
    p_monto_usd DECIMAL(14,2),
    p_id_moneda_destino INT
) 
RETURNS DECIMAL(20,8)
READS SQL DATA
BEGIN
    DECLARE v_tasa_usd DECIMAL(20,8);
    
    SELECT tasa_usd INTO v_tasa_usd
    FROM tasa_cambio_usd 
    WHERE id_moneda = p_id_moneda_destino
      AND activa = TRUE
    LIMIT 1;
    
    IF v_tasa_usd IS NULL OR v_tasa_usd = 0 THEN
        RETURN NULL;
    END IF;
    
    RETURN p_monto_usd / v_tasa_usd;
END//

DELIMITER ;

-- FUNCION 2: Convertir moneda a monedas
DELIMITER //

CREATE FUNCTION convertir_moneda_a_moneda(
    p_monto DECIMAL(20,8),
    p_id_moneda_origen INT,
    p_id_moneda_destino INT
) 
RETURNS DECIMAL(20,8)
READS SQL DATA
BEGIN
    DECLARE v_tasa_origen DECIMAL(20,8);
    DECLARE v_tasa_destino DECIMAL(20,8);
    
    SELECT tasa_usd INTO v_tasa_origen
    FROM tasa_cambio_usd 
    WHERE id_moneda = p_id_moneda_origen AND activa = TRUE
    LIMIT 1;
    
    SELECT tasa_usd INTO v_tasa_destino
    FROM tasa_cambio_usd 
    WHERE id_moneda = p_id_moneda_destino AND activa = TRUE
    LIMIT 1;
    
    IF v_tasa_origen IS NULL OR v_tasa_destino IS NULL OR v_tasa_destino = 0 THEN
        RETURN NULL;
    END IF;
    
    RETURN (p_monto * v_tasa_origen) / v_tasa_destino;
END//

DELIMITER ;

-- STORED PROCEDURES
 -- SP1 Realizar transaccion
DELIMITER //

CREATE PROCEDURE sp_realizar_transaccion(
    IN p_id_usuario INT,
    IN p_id_moneda_in INT,
    IN p_id_moneda_out INT,
    IN p_monto_entrada DECIMAL(20,8)
)
BEGIN
    DECLARE v_id_tasa_in INT;
    DECLARE v_id_tasa_out INT;
    DECLARE v_tasa_in DECIMAL(20,8);
    DECLARE v_tasa_out DECIMAL(20,8);
    DECLARE v_monto_salida DECIMAL(20,8);
    
    -- obtener tasas activas
    SELECT id_tasa, tasa_usd INTO v_id_tasa_in, v_tasa_in
    FROM tasa_cambio_usd 
    WHERE id_moneda = p_id_moneda_in AND activa = TRUE
    LIMIT 1;
    
    SELECT id_tasa, tasa_usd INTO v_id_tasa_out, v_tasa_out
    FROM tasa_cambio_usd 
    WHERE id_moneda = p_id_moneda_out AND activa = TRUE
    LIMIT 1;
    
    -- validaciones
    IF v_id_tasa_in IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe tasa activa para moneda entrada';
    END IF;
    
    IF v_id_tasa_out IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe tasa activa para moneda salida';
    END IF;
    
    IF v_tasa_out = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tasa de moneda salida no puede ser cero';
    END IF;
    
    --  Calcular monto_salida
    SET v_monto_salida = (p_monto_entrada * v_tasa_in) / v_tasa_out;
    
    -- Insertar transaccion
    INSERT INTO transaccion (
        fecha, id_usuario, id_moneda_in, id_moneda_out,
        monto_entrada, monto_salida, tasa_in_usd, tasa_out_usd
    ) VALUES (
        NOW(), p_id_usuario, p_id_moneda_in, p_id_moneda_out,
        p_monto_entrada, v_monto_salida, v_id_tasa_in, v_id_tasa_out
    );
END//

DELIMITER ;

-- SP2 Actualizar tasa

DELIMITER //

CREATE PROCEDURE sp_actualizar_tasas(
    IN p_id_moneda INT,
    IN p_nueva_tasa_usd DECIMAL(20,8)
)
BEGIN
    
    UPDATE tasa_cambio_usd 
    SET activa = FALSE 
    WHERE id_moneda = p_id_moneda AND activa = TRUE;
    

    INSERT INTO tasa_cambio_usd (
        id_moneda, tasa_usd, fecha_actualizacion, activa
    ) VALUES (
        p_id_moneda, p_nueva_tasa_usd, NOW(), TRUE
    );
END//

DELIMITER ;

-- VISTAS
-- Vista1 transacciones Chile
CREATE VIEW v_transacciones_chile AS
SELECT 
    t.id_transaccion,
    t.fecha,
    t.id_usuario,
    m_in.codigo as moneda_entrada,
    m_out.codigo as moneda_salida,
    t.monto_entrada,
    t.monto_salida,
    (t.monto_entrada * tc_in.tasa_usd) as equivalente_usd_entrada,
    (t.monto_salida * tc_out.tasa_usd) as equivalente_usd_salida
FROM transaccion t
JOIN usuario u ON u.id_usuario = t.id_usuario
JOIN moneda m_in ON t.id_moneda_in = m_in.id_moneda
JOIN moneda m_out ON t.id_moneda_out = m_out.id_moneda
JOIN tasa_cambio_usd tc_in ON t.tasa_in_usd = tc_in.id_tasa
JOIN tasa_cambio_usd tc_out ON t.tasa_out_usd = tc_out.id_tasa
WHERE u.pais = 'Chile';

-- Vista2 Operaciones BTC
CREATE VIEW v_transacciones_con_btc AS
SELECT *
FROM transaccion 
WHERE id_moneda_in = (SELECT id_moneda FROM moneda WHERE codigo = 'BTC')
   OR id_moneda_out = (SELECT id_moneda FROM moneda WHERE codigo = 'BTC');
   
   -- Vista3 transacciones mayores a 1000 usd 
   CREATE VIEW v_transacciones_mayores_1000_usd AS
SELECT 
    t.id_transaccion,
    t.fecha,
    t.id_usuario,
    m_in.codigo as moneda_entrada,
    m_out.codigo as moneda_salida,
    t.monto_entrada,
    t.monto_salida,
    (t.monto_entrada * tc_in.tasa_usd) as equivalente_usd_entrada
FROM transaccion t
JOIN moneda m_in ON t.id_moneda_in = m_in.id_moneda
JOIN moneda m_out ON t.id_moneda_out = m_out.id_moneda
JOIN tasa_cambio_usd tc_in ON t.tasa_in_usd = tc_in.id_tasa
WHERE (t.monto_entrada * tc_in.tasa_usd) > 1000;
   
-- Vista4 Top de volumen usuarios vip
CREATE VIEW v_top10_volumen_vip AS
SELECT 
    u.id_usuario,
    u.nombre,
    cu.nombre as categoria,
    COUNT(t.id_transaccion) as total_transacciones,
    SUM(t.monto_entrada * tc_in.tasa_usd) as volumen_total_usd
FROM usuario u
JOIN categoria_usuario cu ON u.id_categoria = cu.id_categoria
LEFT JOIN transaccion t ON u.id_usuario = t.id_usuario
LEFT JOIN tasa_cambio_usd tc_in ON t.tasa_in_usd = tc_in.id_tasa
WHERE cu.nombre = 'VIP'
GROUP BY u.id_usuario, u.nombre, cu.nombre
ORDER BY volumen_total_usd DESC
LIMIT 10;

-- Triggers

 -- Trigger1 Validar diferencia de monedas
 DELIMITER //

CREATE TRIGGER validar_monedas_diferentes
BEFORE INSERT ON transaccion
FOR EACH ROW
BEGIN
    IF NEW.id_moneda_in = NEW.id_moneda_out THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No se puede realizar transacción con la misma moneda de entrada y salida';
    END IF;
END//

DELIMITER ;
-- Trigger2 Validar limite diario
DELIMITER //

CREATE TRIGGER validar_limite_diario_usuario
BEFORE INSERT ON transaccion
FOR EACH ROW
BEGIN
    DECLARE v_limite DECIMAL(20,2);
    DECLARE v_gasto_hoy DECIMAL(14,2);
    DECLARE v_tasa_nueva DECIMAL(20,8);
    
    SELECT cu.limite_transaccion_diario_usd INTO v_limite
    FROM usuario u
    LEFT JOIN categoria_usuario cu ON u.id_categoria = cu.id_categoria
    WHERE u.id_usuario = NEW.id_usuario;
    
    IF v_limite IS NOT NULL THEN
        SELECT COALESCE(SUM(t.monto_entrada * tc.tasa_usd), 0) INTO v_gasto_hoy
        FROM transaccion t
        JOIN tasa_cambio_usd tc ON t.tasa_in_usd = tc.id_tasa
        WHERE t.id_usuario = NEW.id_usuario AND DATE(t.fecha) = CURDATE();
        
        SELECT tasa_usd INTO v_tasa_nueva
        FROM tasa_cambio_usd 
        WHERE id_tasa = NEW.tasa_in_usd;
        
        IF (v_gasto_hoy + (NEW.monto_entrada * v_tasa_nueva)) > v_limite THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Límite diario excedido';
        END IF;
    END IF;
END//

DELIMITER ;