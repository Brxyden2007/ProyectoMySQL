CREATE TABLE audiences (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) UNIQUE,
  description VARCHAR(100)
) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS benefits(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
description VARCHAR(80),
detail TEXT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS periods (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50),
  duration_in_months INT
) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS categories(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
description VARCHAR(60) UNIQUE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS memberships(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
name VARCHAR(50),
description TEXT
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS unitofmeasure(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
description VARCHAR(60) UNIQUE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS categories_polls(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
name VARCHAR(80) UNIQUE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS typesidentifications(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
description VARCHAR(60) UNIQUE,
sufix VARCHAR(5) UNIQUE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS subdivisioncategories(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
description VARCHAR(40) UNIQUE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS countries(
isocode VARCHAR(6) PRIMARY KEY NOT NULL,
name VARCHAR(50),
alfaisotwo VARCHAR(2),
alfaisothree VARCHAR(4)
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS stateorregions(
code VARCHAR(6) PRIMARY KEY NOT NULL,
name VARCHAR(60) UNIQUE,
country_id VARCHAR(6),
FOREIGN KEY (country_id) REFERENCES countries(isocode) ON DELETE CASCADE ON UPDATE CASCADE,
code3166 VARCHAR(10) UNIQUE,
subdivision_id INTEGER(11),
FOREIGN KEY (subdivision_id) REFERENCES subdivisioncategories(id) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS citiesormunicipalities(
code VARCHAR(6) PRIMARY KEY NOT NULL,
name VARCHAR(60),
statereg_id VARCHAR(6),
FOREIGN KEY (statereg_id) REFERENCES stateorregions(code) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS polls(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
name VARCHAR(80) UNIQUE,
description TEXT,
isactive BOOLEAN,
categorypoll_id INT,
FOREIGN KEY (categorypoll_id) REFERENCES categories_polls(id) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=INNODB;

CREATE TABLE audiencebenefits (
  audience_id INT,
  benefit_id INT,
  PRIMARY KEY (audience_id, benefit_id),
  FOREIGN KEY (audience_id) REFERENCES audiences(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (benefit_id) REFERENCES benefits(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE membershipperiods (
  membership_id INT,
  period_id INT,
  price DOUBLE,
  PRIMARY KEY (membership_id, period_id),
  FOREIGN KEY (membership_id) REFERENCES memberships(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (period_id) REFERENCES periods(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE membershipbenefits (
  membership_id INT,
  period_id INT,
  audience_id INT,
  benefit_id INT,
  PRIMARY KEY (membership_id, period_id, audience_id, benefit_id),
  FOREIGN KEY (membership_id) REFERENCES memberships(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (period_id) REFERENCES periods(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (audience_id) REFERENCES audiences(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (benefit_id) REFERENCES benefits(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS companies(
id VARCHAR(20) PRIMARY KEY NOT NULL,
type_id INT,
FOREIGN KEY (type_id) REFERENCES typesidentifications(id) ON DELETE CASCADE ON UPDATE CASCADE,
name VARCHAR(80),
category_id INTEGER(11),
FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE,
city_id VARCHAR(6),
FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(code) ON DELETE CASCADE ON UPDATE CASCADE,
audience_id INT,
FOREIGN KEY (audience_id) REFERENCES audiences(id) ON DELETE CASCADE ON UPDATE CASCADE,
cellphone VARCHAR(15) UNIQUE,
email VARCHAR(80) UNIQUE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS customers(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
name VARCHAR(80),
city_id VARCHAR(6),
FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(code) ON DELETE CASCADE ON UPDATE CASCADE,
audience_id INT,
FOREIGN KEY (audience_id) REFERENCES audiences(id) ON DELETE CASCADE ON UPDATE CASCADE,
cellphone VARCHAR(20) UNIQUE,
email VARCHAR(100) UNIQUE,
address VARCHAR(120)
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS favorites(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
customer_id INT,
FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE ON UPDATE CASCADE,
company_id VARCHAR(20),
FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS products(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
name VARCHAR(60) UNIQUE,
detail TEXT,
price DOUBLE,
category_id INTEGER(11),
FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE,
image VARCHAR(80)
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS details_favorites(
id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
favorite_id INT,
FOREIGN KEY (favorite_id) REFERENCES favorites(id) ON DELETE CASCADE ON UPDATE CASCADE,
product_id INT,
FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS quality_products(
product_id INT,
customer_id INT,
poll_id INT,
company_id VARCHAR(20),
PRIMARY KEY(product_id, customer_id, poll_id, company_id),
FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE ON UPDATE CASCADE,
daterating DATETIME,
rating DOUBLE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS companyproducts(
company_id VARCHAR(20),
product_id INT,
PRIMARY KEY (company_id, product_id),
price DOUBLE,
unitmeasure_id INT,
FOREIGN KEY (unitmeasure_id) REFERENCES unitofmeasure(id) ON DELETE CASCADE ON UPDATE CASCADE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS rates(
customer_id INT,
company_id VARCHAR(20),
poll_id INT,
PRIMARY KEY(customer_id, company_id, poll_id),
FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE ON UPDATE CASCADE,
daterating DATETIME,
rating DOUBLE
)ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS city_phone_codes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  city_name VARCHAR(100),
  phone_code VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS customers_addresses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE ON UPDATE CASCADE,
    city_id VARCHAR(6),
    FOREIGN KEY (city_id) REFERENCES citiesormunicipalities(code) ON DELETE CASCADE ON UPDATE CASCADE,
    address VARCHAR(120) NOT NULL
) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS resumen_calificaciones (
    company_id VARCHAR(20),
    mes_anio VARCHAR(7),
    promedio DECIMAL(3,2)
); --  Registrado para el punto 4 de Procedimientos Almacenados

CREATE TABLE poll_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    poll_id INT NOT NULL,
    question TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE ON UPDATE CASCADE
); -- Registrado para el punto 12 de Procedimientos Almacenados

CREATE TABLE IF NOT EXISTS errores_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    descripcion TEXT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
); -- Registrado para el punto 8 de Procedimientos Almacenados

CREATE TABLE IF NOT EXISTS historial_precios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_id VARCHAR(20),
    product_id INT,
    precio_anterior DOUBLE,
    precio_nuevo DOUBLE,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
); -- Registrado para el punto 15 de Procedimientos Almacenados

CREATE TABLE IF NOT EXISTS log_acciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT,
  company_id VARCHAR(20),
  poll_id INT,
  accion VARCHAR(100),
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); -- Registrado para el 2do punto de Triggers

