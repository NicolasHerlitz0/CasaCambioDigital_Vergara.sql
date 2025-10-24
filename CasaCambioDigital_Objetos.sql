CREATE SCHEMA DB_CasaCambio;
USE DB_CasaCambio;

-- Tablas: 
CREATE TABLE categoria_usuario (
  id_categoria INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  limite_transaccion_diario_usd DECIMAL(20,2),
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE moneda (
  id_moneda INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  codigo VARCHAR(10) NOT NULL UNIQUE,
  nombre VARCHAR(40) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE pais (
  id_pais INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(60) NOT NULL,
  codigo_iso VARCHAR(2) NOT NULL UNIQUE,
  moneda_oficial INT NULL,  -- Será FK a moneda
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE usuario (
  id_usuario INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  rut VARCHAR(12) NOT NULL UNIQUE,
  pais INT NOT NULL,  -- ← CORREGIDO: INT para FK
  correo VARCHAR(120) NOT NULL UNIQUE,
  telefono VARCHAR(30) NULL,
  id_categoria INT NULL  
);

CREATE TABLE tipo_transaccion (
  id_tipo INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nombre ENUM('INGRESO', 'RETIRO', 'CONVERSION', 'TRANSFERENCIA') NOT NULL,
  descripcion VARCHAR(200),
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE comision (
  id_comision INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  id_categoria INT NOT NULL,
  id_tipo_transaccion INT NOT NULL,
  porcentaje DECIMAL(5,2) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE billetera (
  id_billetera INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  id_usuario INT NOT NULL,
  id_moneda INT NOT NULL,
  saldo DECIMAL(20,8) NOT NULL DEFAULT 0.00000000,
  ultima_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE medio_pago (
  id_medio_pago INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  id_usuario INT NOT NULL,
  tipo_medio ENUM('DEBITO', 'CREDITO') NOT NULL,
  banco_nombre VARCHAR(100) NOT NULL,
  ultimos_digitos VARCHAR(4) NOT NULL,
  nombre_titular VARCHAR(100) NOT NULL,
  fecha_vencimiento DATE NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tasa_cambio_usd (
  id_tasa INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  id_moneda INT NOT NULL,                
  tasa_usd DECIMAL(20,8) NOT NULL,        -- 1 moneda = X USD
  fecha_actualizacion DATETIME NOT NULL,
  activa BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE verificacion_tarjeta (
  id_verificacion INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  id_medio_pago INT NOT NULL,
  id_usuario INT NOT NULL,
  estado ENUM('PENDIENTE', 'EN_PROCESO', 'APROBADA', 'RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  intentos_verificacion INT NOT NULL DEFAULT 0,
  codigo_verificacion VARCHAR(10) NULL,
  fecha_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE transaccion (
  id_transaccion INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  fecha DATETIME NOT NULL,
  id_usuario INT NOT NULL,
  id_tipo_transaccion INT NOT NULL,
  id_moneda_in INT NULL,
  id_moneda_out INT NULL,
  id_billetera_entrada INT NULL,
  id_billetera_salida INT NULL,
  monto_entrada DECIMAL(20,8) NOT NULL,
  monto_salida DECIMAL(20,8) NULL,
  comision_aplicada DECIMAL(20,8) NULL  -- ← LA MANTENEMOS
);



-- BLOQUES FK
ALTER TABLE pais
  ADD CONSTRAINT fk_pais_moneda_oficial
    FOREIGN KEY (moneda_oficial) REFERENCES moneda(id_moneda);

ALTER TABLE usuario
  ADD CONSTRAINT fk_usuario_pais
    FOREIGN KEY (pais) REFERENCES pais(id_pais);

ALTER TABLE usuario
  ADD CONSTRAINT fk_usuario_categoria
    FOREIGN KEY (id_categoria) REFERENCES categoria_usuario(id_categoria);

ALTER TABLE comision
  ADD CONSTRAINT fk_comision_categoria
    FOREIGN KEY (id_categoria) REFERENCES categoria_usuario(id_categoria);

ALTER TABLE comision
  ADD CONSTRAINT fk_comision_tipo_transaccion
    FOREIGN KEY (id_tipo_transaccion) REFERENCES tipo_transaccion(id_tipo);

ALTER TABLE comision
  ADD CONSTRAINT uk_comision_unica
    UNIQUE KEY (id_categoria, id_tipo_transaccion);

ALTER TABLE billetera
  ADD CONSTRAINT fk_billetera_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario);

ALTER TABLE billetera
  ADD CONSTRAINT fk_billetera_moneda
    FOREIGN KEY (id_moneda) REFERENCES moneda(id_moneda);

ALTER TABLE billetera
  ADD CONSTRAINT uk_billetera_unica
    UNIQUE KEY (id_usuario, id_moneda);

ALTER TABLE medio_pago
  ADD CONSTRAINT fk_medio_pago_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario);

ALTER TABLE tasa_cambio_usd
  ADD CONSTRAINT fk_tasa_moneda
    FOREIGN KEY (id_moneda) REFERENCES moneda(id_moneda);

ALTER TABLE verificacion_tarjeta
  ADD CONSTRAINT fk_verificacion_medio_pago
    FOREIGN KEY (id_medio_pago) REFERENCES medio_pago(id_medio_pago),
  ADD CONSTRAINT fk_verificacion_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario);

ALTER TABLE transaccion
  ADD CONSTRAINT fk_transaccion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  ADD CONSTRAINT fk_transaccion_tipo FOREIGN KEY (id_tipo_transaccion) REFERENCES tipo_transaccion(id_tipo),
  ADD CONSTRAINT fk_transaccion_moneda_in FOREIGN KEY (id_moneda_in) REFERENCES moneda(id_moneda),
  ADD CONSTRAINT fk_transaccion_moneda_out FOREIGN KEY (id_moneda_out) REFERENCES moneda(id_moneda),
  ADD CONSTRAINT fk_transaccion_billetera_entrada FOREIGN KEY (id_billetera_entrada) REFERENCES billetera(id_billetera),
  ADD CONSTRAINT fk_transaccion_billetera_salida FOREIGN KEY (id_billetera_salida) REFERENCES billetera(id_billetera);

USE DB_CasaCambio;

-- FUNCIONES
-- FUNCION 1: Convertir Usd a monedas
DELIMITER //

CREATE FUNCTION convertir_usd_a_moneda(
    p_monto_usd DECIMAL(20,8),
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
    
    IF v_tasa_origen IS NULL OR v_tasa_destino IS NULL 
    OR v_tasa_origen = 0 OR v_tasa_destino = 0 THEN
        RETURN NULL;
    END IF;
    
    RETURN (p_monto * v_tasa_origen) / v_tasa_destino;
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
    t.comision_aplicada,
    convertir_moneda_a_moneda(t.monto_entrada, t.id_moneda_in, 1) as equivalente_usd_entrada,
    convertir_moneda_a_moneda(COALESCE(t.monto_salida, 0), t.id_moneda_out, 1) as equivalente_usd_salida
FROM transaccion t
JOIN usuario u ON u.id_usuario = t.id_usuario
JOIN moneda m_in ON t.id_moneda_in = m_in.id_moneda
JOIN moneda m_out ON t.id_moneda_out = m_out.id_moneda
JOIN pais p ON u.pais = p.id_pais  
WHERE p.nombre = 'Chile'; 

-- Vista2 Transacciones BTC
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
    convertir_moneda_a_moneda(t.monto_entrada, t.id_moneda_in, 1) as equivalente_usd_entrada
FROM transaccion t
JOIN moneda m_in ON t.id_moneda_in = m_in.id_moneda
JOIN moneda m_out ON t.id_moneda_out = m_out.id_moneda
WHERE convertir_moneda_a_moneda(t.monto_entrada, t.id_moneda_in, 1) > 1000;

-- Vista4 Top de volumen usuarios vip
CREATE VIEW v_top10_volumen_vip AS
SELECT 
    u.id_usuario,
    u.nombre,
    cu.nombre as categoria,
    COUNT(t.id_transaccion) as total_transacciones,
    SUM(convertir_moneda_a_moneda(t.monto_entrada, t.id_moneda_in, 1)) as volumen_total_usd
FROM usuario u
JOIN categoria_usuario cu ON u.id_categoria = cu.id_categoria
LEFT JOIN transaccion t ON u.id_usuario = t.id_usuario
WHERE cu.nombre = 'VIP'
GROUP BY u.id_usuario, u.nombre, cu.nombre
ORDER BY volumen_total_usd DESC
LIMIT 10;

-- Vista5 Saldos en usd usuarios
CREATE VIEW v_saldos_usuarios AS
SELECT 
    u.id_usuario,
    u.nombre as nombre_usuario,
    u.rut,
    cu.nombre as categoria,
    m.codigo as moneda,
    m.nombre as nombre_moneda,
    b.saldo as saldo_actual,
    convertir_moneda_a_moneda(b.saldo, b.id_moneda, 1) as saldo_usd,
    b.ultima_actualizacion
FROM usuario u
JOIN billetera b ON u.id_usuario = b.id_usuario
JOIN moneda m ON b.id_moneda = m.id_moneda
JOIN categoria_usuario cu ON u.id_categoria = cu.id_categoria
WHERE b.activo = TRUE;

-- Stores procedures
-- SP1 Realizar transaccion
DELIMITER //

CREATE PROCEDURE sp_realizar_transaccion(
    IN p_id_usuario INT,
    IN p_id_moneda_in INT,
    IN p_id_moneda_out INT,
    IN p_monto_entrada DECIMAL(20,8),
    IN p_id_tipo_transaccion INT
)
BEGIN
    DECLARE v_id_billetera_entrada INT;
    DECLARE v_id_billetera_salida INT;
    DECLARE v_saldo_salida DECIMAL(20,8);
    DECLARE v_monto_salida DECIMAL(20,8);
    DECLARE v_comision_porcentaje DECIMAL(5,2);
    DECLARE v_comision_aplicada DECIMAL(20,8);
    DECLARE v_id_categoria INT;
    
    SELECT id_billetera INTO v_id_billetera_entrada
    FROM billetera 
    WHERE id_usuario = p_id_usuario AND id_moneda = p_id_moneda_in;
    
    SELECT id_billetera, saldo INTO v_id_billetera_salida, v_saldo_salida
    FROM billetera 
    WHERE id_usuario = p_id_usuario AND id_moneda = p_id_moneda_out;
    
    IF v_id_billetera_entrada IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe billetera para moneda entrada';
    END IF;
    
    IF v_id_billetera_salida IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No existe billetera para moneda salida';
    END IF;
    
    IF v_saldo_salida < p_monto_entrada THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente en billetera de salida';
    END IF;
   
    SELECT id_categoria INTO v_id_categoria
    FROM usuario WHERE id_usuario = p_id_usuario;
    
    SELECT porcentaje INTO v_comision_porcentaje
    FROM comision 
    WHERE id_categoria = v_id_categoria 
      AND id_tipo_transaccion = p_id_tipo_transaccion
      AND activo = TRUE;
    
    IF v_comision_porcentaje IS NULL THEN
        SET v_comision_porcentaje = 0;
    END IF;
  
    SET v_monto_salida = convertir_moneda_a_moneda(
        p_monto_entrada, p_id_moneda_out, p_id_moneda_in
    );
    
    SET v_comision_aplicada = v_monto_salida * (v_comision_porcentaje / 100);
    SET v_monto_salida = v_monto_salida - v_comision_aplicada;
    
    UPDATE billetera 
    SET saldo = saldo - p_monto_entrada,
        ultima_actualizacion = NOW()
    WHERE id_billetera = v_id_billetera_salida;
    
    UPDATE billetera 
    SET saldo = saldo + v_monto_salida,
        ultima_actualizacion = NOW()
    WHERE id_billetera = v_id_billetera_entrada;
    
    -- 7. INSERTAR TRANSACCIÓN
    INSERT INTO transaccion (
        fecha, id_usuario, id_tipo_transaccion,
        id_moneda_in, id_moneda_out,
        id_billetera_entrada, id_billetera_salida,
        monto_entrada, monto_salida, comision_aplicada
    ) VALUES (
        NOW(), p_id_usuario, p_id_tipo_transaccion,
        p_id_moneda_in, p_id_moneda_out,
        v_id_billetera_entrada, v_id_billetera_salida,
        v_monto_salida, p_monto_entrada, v_comision_aplicada
    );
    
END//

DELIMITER ;

DELIMITER //
-- SP2 Realizar transaccion userFriendly
CREATE PROCEDURE sp_realizar_transaccion_uf(
    IN p_rut_usuario VARCHAR(12),          
    IN p_codigo_moneda_origen VARCHAR(10),  
    IN p_codigo_moneda_destino VARCHAR(10), 
    IN p_monto DECIMAL(20,8),           
    IN p_nombre_tipo_transaccion VARCHAR(20) 
)
BEGIN
    DECLARE v_id_usuario INT;
    DECLARE v_id_moneda_origen INT;
    DECLARE v_id_moneda_destino INT;
    DECLARE v_id_tipo_transaccion INT;
    
    SELECT id_usuario INTO v_id_usuario
    FROM usuario 
    WHERE rut = p_rut_usuario;
    
    IF v_id_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
    
    SELECT id_moneda INTO v_id_moneda_origen
    FROM moneda 
    WHERE codigo = p_codigo_moneda_origen AND activo = TRUE;
    
    IF v_id_moneda_origen IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Moneda origen no encontrada';
    END IF;
    
    SELECT id_moneda INTO v_id_moneda_destino
    FROM moneda 
    WHERE codigo = p_codigo_moneda_destino AND activo = TRUE;
    
    IF v_id_moneda_destino IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Moneda destino no encontrada';
    END IF;
    
    SELECT id_tipo INTO v_id_tipo_transaccion
    FROM tipo_transaccion 
    WHERE nombre = p_nombre_tipo_transaccion AND activo = TRUE;
    
    IF v_id_tipo_transaccion IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo transacción no encontrado';
    END IF;
    
    CALL sp_realizar_transaccion(
        v_id_usuario,
        v_id_moneda_destino,    
        v_id_moneda_origen,     
        p_monto,
        v_id_tipo_transaccion
    );
    
END//

DELIMITER ;

-- SP3 Actualizar tasa
DELIMITER //

CREATE PROCEDURE sp_actualizar_tasas(
    IN p_id_moneda INT,
    IN p_nueva_tasa_usd DECIMAL(20,8)
)
BEGIN
    DECLARE v_existe_moneda INT DEFAULT 0;
    DECLARE v_tasas_actualizadas INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_existe_moneda
    FROM moneda 
    WHERE id_moneda = p_id_moneda AND activo = TRUE;
    
    IF v_existe_moneda = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'La moneda especificada no existe o no está activa';
    END IF;
    
    IF p_nueva_tasa_usd <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'La tasa debe ser un valor positivo mayor a cero';
    END IF;
    
    UPDATE tasa_cambio_usd 
    SET activa = FALSE 
    WHERE id_moneda = p_id_moneda 
      AND activa = TRUE
      AND id_tasa = (
          SELECT id_tasa FROM (
              SELECT id_tasa 
              FROM tasa_cambio_usd 
              WHERE id_moneda = p_id_moneda AND activa = TRUE
              ORDER BY fecha_actualizacion DESC 
              LIMIT 1
          ) AS latest_tasa
      );
    
    SELECT ROW_COUNT() INTO v_tasas_actualizadas;
    
    INSERT INTO tasa_cambio_usd (
        id_moneda, tasa_usd, fecha_actualizacion, activa
    ) VALUES (
        p_id_moneda, p_nueva_tasa_usd, NOW(), TRUE
    );
    
    SELECT 
        v_tasas_actualizadas as tasas_desactivadas,
        LAST_INSERT_ID() as nueva_tasa_id,
        'Tasa actualizada exitosamente' as mensaje;
        
END//

DELIMITER ;

-- Triggers
-- Trigger1 Validar diferencia de monedas
DELIMITER //

CREATE TRIGGER validar_monedas_diferentes
BEFORE INSERT ON transaccion
FOR EACH ROW
BEGIN
    DECLARE v_nombre_tipo VARCHAR(50);
    
    -- Obtener el nombre del tipo de transacción
    SELECT nombre INTO v_nombre_tipo
    FROM tipo_transaccion
    WHERE id_tipo = NEW.id_tipo_transaccion;
    
    -- Solo validar para conversiones
    IF v_nombre_tipo = 'CONVERSION' THEN
        IF NEW.id_moneda_in = NEW.id_moneda_out THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'No se puede realizar una conversión con la misma moneda de entrada y salida';
        END IF;
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
    DECLARE v_gasto_hoy DECIMAL(20,2);
    DECLARE v_monto_entrada_usd DECIMAL(20,8);
    
    SELECT cu.limite_transaccion_diario_usd INTO v_limite
    FROM usuario u
    LEFT JOIN categoria_usuario cu ON u.id_categoria = cu.id_categoria
    WHERE u.id_usuario = NEW.id_usuario;
    
    IF v_limite IS NOT NULL THEN
        SELECT COALESCE(SUM(
            convertir_moneda_a_moneda(t.monto_entrada, t.id_moneda_in, 1)
        ), 0) INTO v_gasto_hoy
        FROM transaccion t
        WHERE t.id_usuario = NEW.id_usuario AND DATE(t.fecha) = CURDATE();
        
        -- Convertir monto de entrada de la nueva transacción a USD
        SET v_monto_entrada_usd = convertir_moneda_a_moneda(
            NEW.monto_entrada, NEW.id_moneda_in, 1
        );
        
        -- Validar si excede el límite
        IF (v_gasto_hoy + v_monto_entrada_usd) > v_limite THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Límite diario excedido';
        END IF;
    END IF;
END//

DELIMITER ;
