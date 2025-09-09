CREATE SCHEMA DB_CasaCambio;
USE DB_CasaCambio;

CREATE TABLE usuario (
  id_usuario INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  rut VARCHAR(12) NOT NULL UNIQUE,
  pais VARCHAR(60) NOT NULL,
  correo VARCHAR(120) NOT NULL UNIQUE,
  telefono VARCHAR(30) NULL
);

CREATE TABLE moneda (
  id_moneda INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  codigo VARCHAR(10) NOT NULL UNIQUE,
  nombre VARCHAR(40) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE transaccion (
  id_transaccion INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  fecha DATETIME NOT NULL,
  id_usuario INT NOT NULL,
  id_moneda_in INT NOT NULL,
  id_moneda_out INT NOT NULL,
  monto_usd DECIMAL(14,2) NOT NULL
);

ALTER TABLE transaccion
  ADD CONSTRAINT fk_transaccion_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario);

ALTER TABLE transaccion
  ADD CONSTRAINT fk_transaccion_moneda_in
    FOREIGN KEY (id_moneda_in) REFERENCES moneda (id_moneda);

ALTER TABLE transaccion
  ADD CONSTRAINT fk_transaccion_moneda_out
    FOREIGN KEY (id_moneda_out) REFERENCES moneda (id_moneda);
    
CREATE VIEW v_transacciones_chile AS
SELECT t.*
FROM transaccion t
JOIN usuario u ON u.id_usuario = t.id_usuario
WHERE u.pais = 'Chile';

CREATE VIEW v_transacciones_salida_usd AS
SELECT t.*
FROM transaccion t
JOIN moneda m ON m.id_moneda = t.id_moneda_out
WHERE m.codigo = 'USD';

CREATE VIEW v_transacciones_salida_btc AS
SELECT t.*
FROM transaccion t
JOIN moneda m ON m.id_moneda = t.id_moneda_out
WHERE m.codigo = 'BTC';

CREATE VIEW v_transacciones_mayores_1000 AS
SELECT *
FROM transaccion
WHERE monto_usd > 1000;

