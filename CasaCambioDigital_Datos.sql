USE DB_CasaCambio;

INSERT INTO categoria_usuario (nombre, limite_transaccion_diario_usd, activo) VALUES
('Regular', 1000.00, TRUE),
('Premium', NULL, TRUE),
('VIP', NULL, TRUE);

INSERT INTO moneda (codigo, nombre, activo) VALUES
('USD', 'Dólar Estadounidense', TRUE),
('CLP', 'Peso Chileno', TRUE),
('BTC', 'Bitcoin', TRUE),
('EUR', 'Euro', TRUE),
('ETH', 'Ethereum', TRUE),
('LTC', 'Litecoin', TRUE),
('BCH', 'Bitcoin Cash', TRUE);

INSERT INTO pais (nombre, codigo_iso, moneda_oficial, activo) VALUES
('Chile', 'CL', (SELECT id_moneda FROM moneda WHERE codigo = 'CLP'), TRUE),
('Estados Unidos', 'US', (SELECT id_moneda FROM moneda WHERE codigo = 'USD'), TRUE),
('España', 'ES', (SELECT id_moneda FROM moneda WHERE codigo = 'EUR'), TRUE),
('Argentina', 'AR', NULL, TRUE),
('Perú', 'PE', NULL, TRUE),
('Colombia', 'CO', NULL, TRUE),
('México', 'MX', NULL, TRUE),
('Brasil', 'BR', NULL, TRUE),
('Alemania', 'DE', (SELECT id_moneda FROM moneda WHERE codigo = 'EUR'), TRUE),
('Francia', 'FR', (SELECT id_moneda FROM moneda WHERE codigo = 'EUR'), TRUE);

INSERT INTO usuario (nombre, rut, pais, correo, telefono, id_categoria) VALUES
('Juan Pérez', '12345678-9', 1, 'juan@email.com', '+56912345678', 1),
('María García', '98765432-1', 4, 'maria@email.com', '+5491154321', 2),
('Carlos López', '45678912-3', 1, 'carlos@email.com', '+56987654321', 3),
('Ana Silva', '11222333-4', 1, 'ana@email.com', '+56911223344', 1),
('Pedro Rodríguez', '55666777-8', 5, 'pedro@email.com', '+51987654321', 1),
('Laura Martínez', '99888777-6', 1, 'laura@email.com', '+56999887766', 2),
('Diego Fernández', '44333222-1', 4, 'diego@email.com', '+5491144332211', 3),
('Sofía González', '77666555-4', 1, 'sofia@email.com', '+56977665544', 1),
('Elena Vargas', '33444555-6', 6, 'elena@email.com', '+573001234567', 3),
('Roberto Castro', '88999777-5', 7, 'roberto@email.com', '+525512345678', 3);

INSERT INTO tipo_transaccion (nombre, descripcion, activo) VALUES
('INGRESO', 'Depósito de fondos a la billetera desde medio de pago externo', TRUE),
('RETIRO', 'Extracción de fondos desde la billetera a medio de pago externo', TRUE),
('CONVERSION', 'Cambio de una moneda a otra dentro de la plataforma', TRUE),
('TRANSFERENCIA', 'Envío de fondos entre billeteras de diferentes usuarios', TRUE);

INSERT INTO comision (id_categoria, id_tipo_transaccion, porcentaje, activo) VALUES
-- REGULAR
(1, 1, 0.00, TRUE),  -- INGRESO
(1, 2, 1.50, TRUE),  -- RETIRO
(1, 3, 1.25, TRUE),  -- CONVERSION  
(1, 4, 0.25, TRUE),  -- TRANSFERENCIA

-- PREMIUM
(2, 1, 0.00, TRUE),  -- INGRESO
(2, 2, 0.75, TRUE),  -- RETIRO
(2, 3, 0.75, TRUE),  -- CONVERSION
(2, 4, 0.00, TRUE),  -- TRANSFERENCIA

-- VIP
(3, 1, 0.00, TRUE),  -- INGRESO
(3, 2, 0.25, TRUE),  -- RETIRO
(3, 3, 0.25, TRUE),  -- CONVERSION
(3, 4, 0.00, TRUE);  -- TRANSFERENCIA

INSERT INTO billetera (id_usuario, id_moneda, saldo, ultima_actualizacion, activo) VALUES
-- Usuario 1 
(1, 2, 500000.00000000, NOW(), TRUE),  -- CLP
(1, 1, 1500.00000000, NOW(), TRUE),    -- USD

-- Usuario 2 
(2, 2, 1200000.00000000, NOW(), TRUE), -- CLP  
(2, 1, 8500.00000000, NOW(), TRUE),    -- USD
(2, 4, 3200.00000000, NOW(), TRUE),    -- EUR

-- Usuario 3 
(3, 2, 3500000.00000000, NOW(), TRUE), -- CLP
(3, 1, 25000.00000000, NOW(), TRUE),   -- USD
(3, 3, 1.50000000, NOW(), TRUE),       -- BTC
(3, 5, 15.00000000, NOW(), TRUE),      -- ETH

-- Usuario 4 
(4, 2, 250000.00000000, NOW(), TRUE),  -- CLP
(4, 1, 800.00000000, NOW(), TRUE),     -- USD

-- Usuario 5 
(5, 2, 180000.00000000, NOW(), TRUE),  -- CLP
(5, 1, 1200.00000000, NOW(), TRUE),    -- USD

-- Usuario 6 
(6, 2, 950000.00000000, NOW(), TRUE),  -- CLP
(6, 1, 4200.00000000, NOW(), TRUE),    -- USD
(6, 6, 25.00000000, NOW(), TRUE),      -- LTC

-- Usuario 7 
(7, 2, 2800000.00000000, NOW(), TRUE), -- CLP
(7, 1, 18000.00000000, NOW(), TRUE),   -- USD
(7, 3, 0.75000000, NOW(), TRUE),       -- BTC
(7, 5, 8.50000000, NOW(), TRUE),       -- ETH
(7, 4, 1500.00000000, NOW(), TRUE),    -- EUR

-- Usuario 8 
(8, 2, 320000.00000000, NOW(), TRUE),  -- CLP
(8, 1, 950.00000000, NOW(), TRUE),     -- USD

-- Usuario 9 
(9, 2, 4100000.00000000, NOW(), TRUE), -- CLP
(9, 1, 32000.00000000, NOW(), TRUE),   -- USD
(9, 3, 2.25000000, NOW(), TRUE),       -- BTC
(9, 7, 12.00000000, NOW(), TRUE),      -- BCH

-- Usuario 10 
(10, 2, 5200000.00000000, NOW(), TRUE), -- CLP
(10, 1, 45000.00000000, NOW(), TRUE),   -- USD
(10, 3, 3.10000000, NOW(), TRUE),       -- BTC
(10, 5, 22.00000000, NOW(), TRUE),      -- ETH
(10, 6, 45.00000000, NOW(), TRUE);      -- LTC

INSERT INTO medio_pago (id_usuario, tipo_medio, banco_nombre, ultimos_digitos, nombre_titular, fecha_vencimiento, activo, fecha_creacion) VALUES
-- Usuario 1 
(1, 'CREDITO', 'Banco de Chile', '1234', 'JUAN PEREZ', '2026-05-01', TRUE, NOW()),

-- Usuario 2 
(2, 'DEBITO', 'Santander', '5678', 'MARIA GARCIA', '2027-08-01', TRUE, NOW()),

-- Usuario 3 
(3, 'DEBITO', 'Itaú', '3456', 'CARLOS LOPEZ', '2028-03-01', TRUE, NOW()),
(3, 'CREDITO', 'Scotiabank', '7890', 'CARLOS LOPEZ', '2026-11-01', TRUE, NOW()),

-- Usuario 4 
(4, 'CREDITO', 'Banco Estado', '1122', 'ANA SILVA', '2027-02-01', TRUE, NOW()),

-- Usuario 5 
(5, 'DEBITO', 'BBVA', '3344', 'PEDRO RODRIGUEZ', '2026-09-01', TRUE, NOW()),

-- Usuario 6 
(6, 'CREDITO', 'Santander', '7788', 'LAURA MARTINEZ', '2027-07-01', TRUE, NOW()),

-- Usuario 7 
(7, 'DEBITO', 'BCI', '9900', 'DIEGO FERNANDEZ', '2029-04-01', TRUE, NOW()),
(7, 'CREDITO', 'Itaú', '2233', 'DIEGO FERNANDEZ', '2026-06-01', TRUE, NOW()),

-- Usuario 8 
(8, 'DEBITO', 'Scotiabank', '4455', 'SOFIA GONZALEZ', '2027-10-01', TRUE, NOW()),

-- Usuario 9 
(9, 'CREDITO', 'BBVA', '8899', 'ELENA VARGAS', '2027-05-01', TRUE, NOW()),

-- Usuario 10 
(10, 'DEBITO', 'Santander', '0011', 'ROBERTO CASTRO', '2029-08-01', TRUE, NOW()),
(10, 'CREDITO', 'Banco de Chile', '0022', 'ROBERTO CASTRO', '2026-02-01', TRUE, NOW());

INSERT INTO tasa_cambio_usd (id_moneda, tasa_usd, fecha_actualizacion, activa) VALUES
(1, 1.00000000, NOW(), TRUE),      -- USD
(2, 0.00105000, NOW(), TRUE),      -- CLP  
(3, 45000.00000000, NOW(), TRUE),  -- BTC
(4, 1.08000000, NOW(), TRUE),      -- EUR
(5, 3500.00000000, NOW(), TRUE),   -- ETH
(6, 150.00000000, NOW(), TRUE),    -- LTC
(7, 600.00000000, NOW(), TRUE);    -- BCH


INSERT INTO verificacion_tarjeta (id_medio_pago, id_usuario, estado, intentos_verificacion, codigo_verificacion, fecha_solicitud) VALUES
-- APROBADOS 
(1, 1, 'APROBADA', 1, '1234', NOW() - INTERVAL 5 DAY),
(2, 2, 'APROBADA', 1, '5678', NOW() - INTERVAL 4 DAY),
(3, 3, 'APROBADA', 1, '9012', NOW() - INTERVAL 3 DAY),
(4, 3, 'APROBADA', 1, '3456', NOW() - INTERVAL 6 DAY),
(5, 4, 'APROBADA', 1, '7890', NOW() - INTERVAL 2 DAY),
(6, 5, 'APROBADA', 1, '1122', NOW() - INTERVAL 1 DAY),
(12, 10, 'APROBADA', 1, '3344', NOW() - INTERVAL 5 DAY),
(13, 10, 'APROBADA', 1, '5566', NOW() - INTERVAL 4 DAY),

-- PROCESO 
(7, 6, 'EN_PROCESO', 2, NULL, NOW() - INTERVAL 1 DAY),
(8, 7, 'EN_PROCESO', 1, NULL, NOW() - INTERVAL 1 DAY),

-- PENDIENTES
(9, 7, 'PENDIENTE', 0, NULL, NOW()),
(10, 8, 'PENDIENTE', 0, NULL, NOW()),

-- RECHAZADO
(11, 9, 'RECHAZADA', 3, '9999', NOW() - INTERVAL 7 DAY);

-- Transacciones Datos de ejemplo
INSERT INTO transaccion (fecha, id_usuario, id_tipo_transaccion, id_moneda_in, id_moneda_out, id_billetera_entrada, id_billetera_salida, monto_entrada, monto_salida, comision_aplicada) VALUES
-- TRANSACCION 1: Conversión CLP → USD 
(NOW() - INTERVAL 5 DAY, 1, 3, 1, 2, 2, 1, 103.68750000, 100000.00000000, 1.31250000),

-- TRANSACCION 2: Conversión USD → BTC 
(NOW() - INTERVAL 4 DAY, 2, 3, 3, 1, 5, 4, 0.02205555, 1000.00000000, 0.00016667),

-- TRANSACCION 3: Conversión CLP → ETH 
(NOW() - INTERVAL 3 DAY, 3, 3, 5, 2, 9, 6, 0.31421250, 1050000.00000000, 0.00078750),

-- TRANSACCION 4: Transferencia CLP entre usuarios 
(NOW() - INTERVAL 2 DAY, 4, 4, 2, 2, 12, 10, 49875.00000000, 50000.00000000, 125.00000000),

-- TTRANSACCION 5: Conversión EUR → USD 
(NOW() - INTERVAL 1 DAY, 6, 3, 1, 4, 15, 14, 1071.90000000, 1000.00000000, 8.10000000),

-- TRANSACCION 6: Conversión BTC → LTC 
(NOW() - INTERVAL 12 HOUR, 7, 3, 6, 3, 21, 19, 299.25000000, 1.00000000, 0.75000000),

-- TRANSACCION 7: Ingreso CLP a billetera 
(NOW() - INTERVAL 6 HOUR, 8, 1, 2, NULL, 22, NULL, 200000.00000000, NULL, 0.00000000),

-- TRANSACCION 8: Retiro USD a medio de pago 
(NOW() - INTERVAL 3 HOUR, 9, 2, NULL, 1, NULL, 25, 5000.00000000, 5000.00000000, 12.50000000),

-- TRANSACCION 9: Conversión ETH → BCH 
(NOW() - INTERVAL 1 HOUR, 10, 3, 7, 5, 32, 31, 58.18750000, 10.00000000, 0.14583333),

-- TRANSACCION 10: Transferencia USD entre usuarios 
(NOW(), 3, 4, 1, 1, 18, 7, 5000.00000000, 5000.00000000, 0.00000000);

-- Transacciones por SP
CALL sp_realizar_transaccion_uf('12345678-9', 'CLP', 'USD', 100000.00, 'CONVERSION');

-- Transfiere CLP a otro usuario
CALL sp_realizar_transaccion_uf('45678912-3', 'CLP', 'CLP', 50000.00, 'TRANSFERENCIA');

-- Ingresa CLP a su billetera 
CALL sp_realizar_transaccion_uf('11222333-4', 'CLP', 'CLP', 200000.00, 'INGRESO');

-- Retira USD 
CALL sp_realizar_transaccion_uf('55666777-8', 'USD', 'USD', 500.00, 'RETIRO');

-- Conversión normal
CALL sp_realizar_transaccion_uf('12345678-9', 'CLP', 'USD', 50000.00, 'CONVERSION');

-- Transferencia entre usuarios
CALL sp_realizar_transaccion_uf('12345678-9', 'CLP', 'CLP', 50000.00, 'TRANSFERENCIA');

-- Error por trigger: Mismas monedas en conversión
CALL sp_realizar_transaccion_uf('12345678-9', 'CLP', 'CLP', 100000.00, 'CONVERSION');

-- Errores por Sp
-- Usuario no existe
CALL sp_realizar_transaccion_uf('00000000-0', 'CLP', 'USD', 100000.00, 'CONVERSION');

-- Moneda origen no existe
CALL sp_realizar_transaccion_uf('12345678-9', 'CLPX', 'USD', 100000.00, 'CONVERSION');

-- Moneda destino no existe  
CALL sp_realizar_transaccion_uf('12345678-9', 'CLP', 'USDD', 100000.00, 'CONVERSION');

-- Tipo transacción no existe
CALL sp_realizar_transaccion_uf('12345678-9', 'CLP', 'USD', 100000.00, 'CONVERSIO');

