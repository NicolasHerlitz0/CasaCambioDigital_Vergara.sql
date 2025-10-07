USE DB_CasaCambio;

INSERT INTO categoria_usuario (nombre, limite_transaccion_diario_usd, comision_porcentaje, activo) VALUES
('Regular', 1000.00, 2.00, TRUE),
('Premium', NULL, 1.00, TRUE),
('VIP', NULL, 0.50, TRUE);

INSERT INTO usuario (nombre, rut, pais, correo, telefono, id_categoria) VALUES
('Juan Pérez', '12345678-9', 'Chile', 'juan@email.com', '+56912345678', 1),
('María García', '98765432-1', 'Argentina', 'maria@email.com', '+5491154321', 2),
('Carlos López', '45678912-3', 'Chile', 'carlos@email.com', '+56987654321', 3),
('Ana Silva', '11222333-4', 'Chile', 'ana@email.com', '+56911223344', 1),
('Pedro Rodríguez', '55666777-8', 'Perú', 'pedro@email.com', '+51987654321', 1),
('Laura Martínez', '99888777-6', 'Chile', 'laura@email.com', '+56999887766', 2),
('Diego Fernández', '44333222-1', 'Argentina', 'diego@email.com', '+5491144332211', 3),
('Sofía González', '77666555-4', 'Chile', 'sofia@email.com', '+56977665544', 1),
('Elena Vargas', '33444555-6', 'Colombia', 'elena@email.com', '+573001234567', 3),
('Roberto Castro', '88999777-5', 'México', 'roberto@email.com', '+525512345678', 3);

INSERT INTO moneda (codigo, nombre, activo) VALUES
('USD', 'Dólar Estadounidense', TRUE),
('CLP', 'Peso Chileno', TRUE),
('BTC', 'Bitcoin', TRUE),
('EUR', 'Euro', TRUE),
('ETH', 'Ethereum', TRUE),
('LTC', 'Litecoin', TRUE),
('BCH', 'Bitcoin Cash', TRUE);

INSERT INTO tasa_cambio_usd (id_moneda, tasa_usd, fecha_actualizacion, activa) VALUES
((SELECT id_moneda FROM moneda WHERE codigo = 'USD'), 1.00, NOW(), TRUE),
((SELECT id_moneda FROM moneda WHERE codigo = 'CLP'), 0.00105, NOW(), TRUE),
((SELECT id_moneda FROM moneda WHERE codigo = 'BTC'), 45000.00, NOW(), TRUE),
((SELECT id_moneda FROM moneda WHERE codigo = 'EUR'), 1.08, NOW(), TRUE),
((SELECT id_moneda FROM moneda WHERE codigo = 'ETH'), 3500.00, NOW(), TRUE),
((SELECT id_moneda FROM moneda WHERE codigo = 'LTC'), 150.00, NOW(), TRUE),
((SELECT id_moneda FROM moneda WHERE codigo = 'BCH'), 600.00, NOW(), TRUE);


-- Tramsacciones de referencia base
INSERT INTO transaccion (fecha, id_usuario, id_moneda_in, id_moneda_out, monto_entrada, monto_salida, tasa_in_usd, tasa_out_usd) VALUES
(NOW(), 3, 3, 1, 1.00000000, 124000.00, 3, 1),
(NOW(), 7, 3, 1, 0.10000000, 12400.00, 3, 1),
(NOW(), 8, 3, 1, 0.00100000, 124.00, 3, 1),
(NOW(), 2, 3, 1, 0.10000000, 12400.00, 3, 1),
(NOW(), 1, 3, 1, 0.00100000, 124.00, 3, 1),
(NOW(), 3, 1, 3, 124.00, 0.00100000, 1, 3),
(NOW(), 7, 1, 3, 124000.00, 1.00000000, 1, 3),
('2024-10-05 10:00:00', 3, 1, 3, 248000.00, 1.00000000, 1, 3),
(NOW(), 1, 1, 3, 372.00, 0.00300000, 1, 3),
(NOW(), 4, 2, 5, 100000.00, 10.00000000, 2, 5),
(NOW(), 5, 6, 4, 1.00000000, 100.00, 6, 4),
(NOW(), 2, 5, 6, 1.00000000, 23.33333333, 5, 6),
(NOW(), 9, 1, 6, 1000.00, 6.66666667, 1, 6),
(NOW(), 9, 5, 1, 1.00000000, 3500.00, 5, 1),
(NOW(), 9, 2, 1, 100000.00, 105.00, 2, 1);
