-- =============================================================
-- PROYECTO: Convocatoria Selección Española — Mundial 2026
-- ARCHIVO: ddl.sql
-- DESCRIPCIÓN: Definición de la estructura completa de la base
--              de datos. Contiene únicamente los CREATE TABLE
--              sin inserción de datos.
--
-- EVOLUCIÓN DEL MODELO DE DATOS:
--   1. seleccion_espana         → Primera versión. Una tabla por
--                                 posición, sin relaciones formales.
--   2. seleccion_espana_modelo  → Segunda versión. Dos tablas
--                                 relacionadas (dim + fact), sin
--                                 modelo estrella completo.
--   3. seleccion_espana_estrella → Versión final. Modelo estrella
--                                  con múltiples dimensiones y una
--                                  tabla de hechos central.
--
-- AUTOR: Martín López | Unicorn Academy | 2026
-- =============================================================


-- =============================================================
-- BASE DE DATOS 1: seleccion_espana
-- Primera versión del modelo de datos. Se creó una tabla
-- independiente por cada posición para almacenar las métricas
-- de los jugadores elegibles exportadas desde Python.
-- Limitación: tablas sin relación entre sí, no sigue el
-- modelo relacional estándar.
-- =============================================================

CREATE DATABASE IF NOT EXISTS seleccion_espana;
USE seleccion_espana;

CREATE TABLE porteros (
    id                           INT AUTO_INCREMENT PRIMARY KEY,
    jugador                      VARCHAR(100),
    nacionalidad                 VARCHAR(20),
    posicion                     VARCHAR(50),
    sub_posicion                 VARCHAR(50),
    partidos_jugados             INT,
    partidos_titular             INT,
    minutos_disputados           INT,
    partidos_completos           VARCHAR(10),
    disparos_a_puerta            INT,
    goles_en_contra              INT,
    goles_salvados               INT,
    goles_en_contra_por_partido  FLOAT,
    intentos_penalty             INT,
    penaltys_permitidos          INT,
    penaltys_salvados            INT,
    porcentaje_penaltys_salvados FLOAT,
    salvadas_por_partido         FLOAT
);

CREATE TABLE laterales_derechos (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    jugador            VARCHAR(100),
    nacionalidad       VARCHAR(20),
    posicion           VARCHAR(50),
    sub_posicion       VARCHAR(50),
    partidos_jugados   INT,
    partidos_titular   INT,
    minutos_disputados INT,
    partidos_completos VARCHAR(10),
    goles              INT,
    asistencias        INT,
    duelos_ganados     INT,
    intercepciones     INT
);

CREATE TABLE laterales_izquierdos (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    jugador            VARCHAR(100),
    nacionalidad       VARCHAR(20),
    posicion           VARCHAR(50),
    sub_posicion       VARCHAR(50),
    partidos_jugados   INT,
    partidos_titular   INT,
    minutos_disputados INT,
    partidos_completos VARCHAR(10),
    goles              INT,
    asistencias        INT,
    duelos_ganados     INT,
    intercepciones     INT
);

CREATE TABLE defensas_centrales (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    jugador            VARCHAR(100),
    nacionalidad       VARCHAR(20),
    posicion           VARCHAR(50),
    sub_posicion       VARCHAR(50),
    partidos_jugados   INT,
    partidos_titular   INT,
    minutos_disputados INT,
    partidos_completos VARCHAR(10),
    duelos_ganados     INT,
    intercepciones     INT
);

CREATE TABLE mediocampistas (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    jugador            VARCHAR(100),
    nacionalidad       VARCHAR(20),
    posicion           VARCHAR(50),
    sub_posicion       VARCHAR(50),
    partidos_jugados   INT,
    partidos_titular   INT,
    minutos_disputados INT,
    partidos_completos VARCHAR(10),
    goles              INT,
    asistencias        INT,
    duelos_ganados     INT,
    intercepciones     INT
);

CREATE TABLE extremos (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    jugador            VARCHAR(100),
    nacionalidad       VARCHAR(20),
    posicion           VARCHAR(50),
    sub_posicion       VARCHAR(50),
    partidos_jugados   INT,
    partidos_titular   INT,
    minutos_disputados INT,
    partidos_completos VARCHAR(10),
    goles              INT,
    asistencias        INT,
    duelos_ganados     INT,
    intercepciones     INT
);

CREATE TABLE delanteros (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    jugador            VARCHAR(100),
    nacionalidad       VARCHAR(20),
    posicion           VARCHAR(50),
    sub_posicion       VARCHAR(50),
    partidos_jugados   INT,
    partidos_titular   INT,
    minutos_disputados INT,
    partidos_completos VARCHAR(10),
    goles              INT,
    asistencias        INT,
    duelos_ganados     INT,
    intercepciones     INT
);


-- =============================================================
-- BASE DE DATOS 2: seleccion_espana_modelo
-- Segunda versión del modelo de datos. Se unificaron todas las
-- tablas de posición en dos tablas relacionadas mediante una
-- clave foránea. Primera aproximación al modelo relacional.
-- Limitación: solo dos tablas, sin modelo estrella completo.
-- =============================================================

CREATE DATABASE IF NOT EXISTS seleccion_espana_modelo;
USE seleccion_espana_modelo;

-- Tabla de dimensión con información descriptiva del jugador.
-- Las columnas champions e internacional fueron añadidas
-- posteriormente para implementar el sistema de ponderación 60/20/20.
CREATE TABLE dim_jugadores (
    id            INT          AUTO_INCREMENT PRIMARY KEY,
    jugador       VARCHAR(100),
    nacionalidad  VARCHAR(20),
    posicion      VARCHAR(50),
    sub_posicion  VARCHAR(50),
    champions     INT          DEFAULT 0,
    internacional INT          DEFAULT 0
);

-- Tabla de hechos con todas las métricas estadísticas.
-- Las métricas de porteros tienen valor NULL para jugadores de campo
-- y las métricas de campo tienen valor NULL para porteros.
CREATE TABLE fact_estadisticas (
    id                           INT AUTO_INCREMENT PRIMARY KEY,
    jugador                      VARCHAR(100),
    partidos_jugados             INT,
    partidos_titular             INT,
    minutos_disputados           INT,
    goles                        INT,
    asistencias                  INT,
    duelos_ganados               INT,
    intercepciones               INT,
    disparos_a_puerta            INT,
    goles_en_contra              INT,
    goles_salvados               INT,
    goles_en_contra_por_partido  FLOAT,
    intentos_penalty             INT,
    penaltys_permitidos          INT,
    penaltys_salvados            INT,
    porcentaje_penaltys_salvados FLOAT,
    salvadas_por_partido         FLOAT,
    jugador_id                   INT,
    FOREIGN KEY (jugador_id) REFERENCES dim_jugadores(id)
);


-- =============================================================
-- BASE DE DATOS 3: seleccion_espana_estrella
-- Versión final del modelo de datos. Implementa el modelo
-- estrella con una tabla de hechos central y cuatro tablas
-- de dimensiones. Este modelo se conecta a Power BI para
-- la construcción del dashboard interactivo.
-- =============================================================

CREATE DATABASE IF NOT EXISTS seleccion_espana_estrella;
USE seleccion_espana_estrella;

-- Dimensión: Información básica del jugador
CREATE TABLE dim_jugadores (
    id_jugador   INT          AUTO_INCREMENT PRIMARY KEY,
    jugador      VARCHAR(100) NOT NULL,
    nacionalidad VARCHAR(20)
);

-- Dimensión: Posición y sub-posición del jugador
CREATE TABLE dim_posiciones (
    id_posicion  INT         AUTO_INCREMENT PRIMARY KEY,
    posicion     VARCHAR(50),
    sub_posicion VARCHAR(50)
);

-- Dimensión: Experiencia en competiciones de alto nivel
-- champions     → 1 si el jugador disputó la UEFA Champions League en la temporada 2025/2026
-- internacional → 1 si el jugador ha representado a España en competencias oficiales
CREATE TABLE dim_experiencia (
    id_experiencia INT AUTO_INCREMENT PRIMARY KEY,
    champions      INT DEFAULT 0,
    internacional  INT DEFAULT 0
);

-- Dimensión: Estado de convocatoria del jugador
-- convocado puede tomar los valores:
--   'Convocado'    → jugador seleccionado para la convocatoria final
--   'Contingencia' → jugador de reserva en caso de lesión o baja
--   'No convocado' → jugador elegible no seleccionado
CREATE TABLE dim_convocatoria (
    id_convocatoria  INT         AUTO_INCREMENT PRIMARY KEY,
    convocado        VARCHAR(20),
    puntuacion_final FLOAT
);

-- Tabla de hechos central del modelo estrella.
-- Contiene todas las métricas estadísticas y las claves foráneas
-- que conectan con las cuatro tablas de dimensiones.
-- Las métricas de porteros tienen NULL para jugadores de campo
-- y las métricas de campo tienen NULL para porteros.
CREATE TABLE fact_estadisticas (
    id                           INT AUTO_INCREMENT PRIMARY KEY,

    -- Claves foráneas (modelo estrella)
    id_jugador                   INT,
    id_posicion                  INT,
    id_experiencia               INT,
    id_convocatoria              INT,

    -- Métricas de participación (comunes a todas las posiciones)
    partidos_jugados             INT,
    partidos_titular             INT,
    minutos_disputados           INT,

    -- Métricas de jugadores de campo (NULL para porteros)
    goles                        INT,
    asistencias                  INT,
    duelos_ganados               INT,
    intercepciones               INT,

    -- Métricas específicas de porteros (NULL para jugadores de campo)
    disparos_a_puerta            INT,
    goles_en_contra              INT,
    goles_salvados               INT,
    goles_en_contra_por_partido  FLOAT,
    intentos_penalty             INT,
    penaltys_permitidos          INT,
    penaltys_salvados            INT,
    porcentaje_penaltys_salvados FLOAT,
    salvadas_por_partido         FLOAT,

    -- Puntuación del sistema de ponderación 60/20/20
    puntuacion_final             FLOAT,

    -- Definición de claves foráneas
    FOREIGN KEY (id_jugador)      REFERENCES dim_jugadores(id_jugador),
    FOREIGN KEY (id_posicion)     REFERENCES dim_posiciones(id_posicion),
    FOREIGN KEY (id_experiencia)  REFERENCES dim_experiencia(id_experiencia),
    FOREIGN KEY (id_convocatoria) REFERENCES dim_convocatoria(id_convocatoria)
);
