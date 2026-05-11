-- =============================================================
-- PROYECTO: Convocatoria Selección Española — Mundial 2026
-- ARCHIVO: analisis.sql
-- DESCRIPCIÓN: Consultas realizadas para el análisis, limpieza
--              y exploración de datos. El archivo está organizado
--              en cinco secciones que reflejan la evolución del
--              análisis desde las métricas puras hasta el sistema
--              de ponderación final.
--
-- SECCIONES:
--   1. Análisis exploratorio y métricas puras por posición
--   2. Sistema de ponderación 60/20/20
--   3. Consultas de convocatoria con sistema ponderado
--   4. Modelo estrella — carga y verificación de datos
--   5. Sistema de puntuación unificada
--
-- AUTOR: Martín López | Unicorn Academy | 2026
-- =============================================================


-- =============================================================
-- SECCIÓN 1: Análisis exploratorio y métricas puras por posición
-- Consultas realizadas sobre la base de datos seleccion_espana
-- para explorar los datos y obtener rankings por posición
-- basados únicamente en estadísticas de liga local.
-- =============================================================

USE seleccion_espana;

-- Verificación de tablas y registros importados
SHOW TABLES;

SELECT 'Porteros'             AS posicion, COUNT(*) AS total FROM porteros
UNION SELECT 'Laterales Derechos',          COUNT(*) FROM laterales_derechos
UNION SELECT 'Laterales Izquierdos',        COUNT(*) FROM laterales_izquierdos
UNION SELECT 'Defensas Centrales',          COUNT(*) FROM defensas_centrales
UNION SELECT 'Mediocampistas',              COUNT(*) FROM mediocampistas
UNION SELECT 'Extremos',                    COUNT(*) FROM extremos
UNION SELECT 'Delanteros',                  COUNT(*) FROM delanteros;

-- -------------------------------------------------------------
-- 1.1 Ranking de porteros por métricas puras
-- Métricas evaluadas: disparos a puerta, % salvadas, % permitidos
-- Se calculan los porcentajes como métricas derivadas ya que
-- reflejan el rendimiento del portero de forma más objetiva
-- que los valores absolutos.
-- -------------------------------------------------------------
SELECT
    jugador,
    partidos_jugados,
    partidos_titular,
    minutos_disputados,
    disparos_a_puerta,
    ROUND(goles_salvados * 100.0 / disparos_a_puerta, 1) AS porcentaje_salvadas,
    ROUND(goles_en_contra * 100.0 / disparos_a_puerta, 1) AS porcentaje_permitidos
FROM porteros
ORDER BY porcentaje_salvadas DESC, porcentaje_permitidos ASC
LIMIT 5;

-- -------------------------------------------------------------
-- 1.2 Ranking de laterales derechos por métricas puras
-- Métricas evaluadas: duelos ganados (50%), intercepciones (30%),
-- asistencias (20%) — perfil 80% defensivo / 20% ofensivo
-- según el planteamiento táctico de Luis de la Fuente.
-- -------------------------------------------------------------
SELECT
    jugador,
    sub_posicion,
    partidos_jugados,
    partidos_titular,
    minutos_disputados,
    goles,
    asistencias,
    duelos_ganados,
    intercepciones
FROM laterales_derechos
ORDER BY duelos_ganados DESC, intercepciones DESC, asistencias DESC;

-- -------------------------------------------------------------
-- 1.3 Ranking de laterales izquierdos por métricas puras
-- Mismos criterios que laterales derechos.
-- -------------------------------------------------------------
SELECT
    jugador,
    sub_posicion,
    partidos_jugados,
    partidos_titular,
    minutos_disputados,
    goles,
    asistencias,
    duelos_ganados,
    intercepciones
FROM laterales_izquierdos
ORDER BY duelos_ganados DESC, intercepciones DESC, asistencias DESC;

-- -------------------------------------------------------------
-- 1.4 Ranking de defensas centrales por métricas puras
-- Métricas evaluadas: duelos ganados, intercepciones,
-- minutos disputados — posición puramente defensiva.
-- -------------------------------------------------------------
SELECT
    jugador,
    sub_posicion,
    partidos_jugados,
    partidos_titular,
    minutos_disputados,
    duelos_ganados,
    intercepciones
FROM defensas_centrales
ORDER BY duelos_ganados DESC, intercepciones DESC, minutos_disputados DESC;

-- -------------------------------------------------------------
-- 1.5 Ranking de mediocampistas defensivos por métricas puras
-- Métricas evaluadas: duelos ganados (35%), intercepciones (35%),
-- asistencias (30%) — equilibrio entre recuperación y creación.
-- -------------------------------------------------------------
SELECT
    jugador,
    sub_posicion,
    partidos_jugados,
    partidos_titular,
    minutos_disputados,
    goles,
    asistencias,
    duelos_ganados,
    intercepciones
FROM mediocampistas
WHERE sub_posicion = 'Medio_centro_defensivo'
ORDER BY duelos_ganados DESC, intercepciones DESC, asistencias DESC;

-- -------------------------------------------------------------
-- 1.6 Ranking de mediocampistas ofensivos por métricas puras
-- Métricas evaluadas: goles (40%), asistencias (40%),
-- duelos ganados (20%) — perfil creador y goleador.
-- -------------------------------------------------------------
SELECT
    jugador,
    sub_posicion,
    partidos_jugados,
    partidos_titular,
    minutos_disputados,
    goles,
    asistencias,
    duelos_ganados,
    intercepciones
FROM mediocampistas
WHERE sub_posicion = 'Medio_centro_ofensivo'
ORDER BY goles DESC, asistencias DESC, duelos_ganados DESC;

-- -------------------------------------------------------------
-- 1.7 Ranking de extremos por métricas puras
-- Métricas evaluadas: promedio simple de goles, duelos ganados
-- y asistencias — las tres dimensiones tienen igual peso.
-- -------------------------------------------------------------
SELECT
    jugador,
    sub_posicion,
    partidos_jugados,
    partidos_titular,
    minutos_disputados,
    goles,
    asistencias,
    duelos_ganados,
    intercepciones
FROM extremos
ORDER BY goles DESC, duelos_ganados DESC, asistencias DESC;

-- -------------------------------------------------------------
-- 1.8 Ranking de delanteros por métricas puras
-- Métricas evaluadas: goles (50%), asistencias (30%),
-- duelos ganados (20%) — el gol es la métrica principal.
-- -------------------------------------------------------------
SELECT
    jugador,
    sub_posicion,
    partidos_jugados,
    partidos_titular,
    minutos_disputados,
    goles,
    asistencias,
    duelos_ganados,
    intercepciones
FROM delanteros
ORDER BY goles DESC, asistencias DESC, duelos_ganados DESC;


-- =============================================================
-- SECCIÓN 2: Sistema de ponderación 60/20/20
-- Consultas realizadas sobre seleccion_espana_modelo para
-- añadir las columnas de experiencia internacional y aplicar
-- el sistema de ponderación 60/20/20:
--   60% → métricas estadísticas normalizadas por posición
--   20% → participación en UEFA Champions League (1/0)
--   20% → experiencia con la Selección Española (1/0)
--
-- La normalización divide cada métrica entre su valor máximo
-- dentro de la misma posición, llevando todos los valores
-- a una escala común de 0 a 1.
-- =============================================================

USE seleccion_espana_modelo;

-- Añadir columnas de experiencia a dim_jugadores
ALTER TABLE dim_jugadores
ADD COLUMN champions     INT DEFAULT 0,
ADD COLUMN internacional INT DEFAULT 0;

-- Actualizar jugadores que participaron en Champions League
-- (ejecutar sin modo seguro)
SET SQL_SAFE_UPDATES = 0;

UPDATE dim_jugadores SET champions = 1
WHERE jugador IN (
    'Joan Garcia', 'David Raya', 'Robert Sanchez', 'Unai Simon',
    'Jesus Areso', 'Marcos Llorente', 'Pau Navarro', 'Pedro Porro',
    'Alejandro Balde', 'Sergi Cardona', 'Alvaro Carreras',
    'Marc Cucurella', 'Alex Grimaldo', 'Alfonso Pedraza',
    'Marcos Alonso', 'Raul Asencio', 'Pau Cubarsi', 'Eric Garcia',
    'Mario Hermoso', 'Dean Huijsen', 'Aymeric Laporte',
    'Robin Le Normand', 'Rafa Marin', 'Gerard Martin',
    'Aitor Paredes', 'Daniel Vivian', 'Pablo Barrios',
    'Antonio Blanco', 'Santi Comesana', 'Inigo Ruiz de Galarreta',
    'Aleix Garcia', 'Mikel Jauregizar', 'Koke', 'Fermin Lopez',
    'Dani Olmo', 'Daniel Parejo', 'Pedri', 'Rodri', 'Oihan Sancet',
    'Martin Zubimendi', 'Alex Baena', 'Alex Berenguer',
    'Alberto Moleiro', 'Nico Williams', 'Lamine Yamal',
    'Gorka Guruzeta', 'Mikel Oyarzabal', 'Ferran Torres'
);

-- Actualizar jugadores con internacionalidades con España
UPDATE dim_jugadores SET internacional = 1
WHERE jugador IN (
    'Joan Garcia', 'David de Gea', 'David Raya', 'Alex Remiro',
    'Robert Sanchez', 'Unai Simon', 'Hector Bellerin',
    'Oscar Mingueza', 'Marcos Llorente', 'Pedro Porro',
    'Alejandro Balde', 'Yuri Berchiche', 'Marc Cucurella',
    'Alex Grimaldo', 'Jose Luis Gaya', 'Juan Miranda',
    'Alfonso Pedraza', 'Sergio Gomez', 'Marcos Alonso',
    'Marc Bartra', 'Jonny Castro', 'Pau Cubarsi', 'Eric Garcia',
    'Mario Hermoso', 'Dean Huijsen', 'Aymeric Laporte',
    'Robin Le Normand', 'Unai Nunez', 'Aitor Paredes',
    'Pau Torres', 'Daniel Vivian', 'Pablo Barrios',
    'Adrian Bernabe', 'Antonio Blanco', 'Pablo Fornals',
    'Aleix Garcia', 'Koke', 'Fermin Lopez', 'Dani Olmo',
    'Daniel Parejo', 'Pedri', 'Rodri', 'Oihan Sancet',
    'Carlos Soler', 'Martin Zubimendi', 'Alex Baena',
    'Ander Barrenetxea', 'Bryan Gil', 'Victor Munoz',
    'Jesus Rodriguez', 'Nico Williams', 'Lamine Yamal',
    'Borja Iglesias', 'Jorge de Frutos', 'Bryan Zaragoza',
    'Yeremi Pino', 'Ferran Torres', 'Brais Mendez', 'Yuri Berchiche',
    'Mario Hermoso'
);

SET SQL_SAFE_UPDATES = 1;


-- =============================================================
-- SECCIÓN 3: Consultas de convocatoria con sistema ponderado
-- Cada consulta normaliza las métricas dividiéndolas entre el
-- valor máximo de su posición y aplica los pesos correspondientes.
-- La puntuación final combina estadísticas (60%) + champions (20%)
-- + internacional (20%).
-- =============================================================

USE seleccion_espana_modelo;

-- -------------------------------------------------------------
-- 3.1 Convocatoria de porteros — Sistema ponderado
-- Métricas estadísticas: goles salvados (50%) +
--                        salvadas por partido (50%)
-- -------------------------------------------------------------
SELECT
    d.jugador,
    d.sub_posicion,
    d.champions,
    d.internacional,
    ROUND(
        (
            (
                f.goles_salvados /
                (SELECT MAX(f2.goles_salvados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Portero')
            ) * 0.50 +
            (
                f.salvadas_por_partido /
                (SELECT MAX(f2.salvadas_por_partido)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Portero')
            ) * 0.50
        ) * 0.60 +
        d.champions     * 0.20 +
        d.internacional * 0.20
    , 3) AS puntuacion_final
FROM dim_jugadores d
JOIN fact_estadisticas f ON d.jugador = f.jugador
WHERE d.sub_posicion = 'Portero'
ORDER BY puntuacion_final DESC;

-- -------------------------------------------------------------
-- 3.2 Convocatoria de laterales derechos — Sistema ponderado
-- Métricas estadísticas: duelos ganados (50%) +
--                        intercepciones (30%) + asistencias (20%)
-- -------------------------------------------------------------
SELECT
    d.jugador,
    d.sub_posicion,
    d.champions,
    d.internacional,
    ROUND(
        (
            (f.duelos_ganados /
                (SELECT MAX(f2.duelos_ganados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Lateral_derecho')
            ) * 0.50 +
            (f.intercepciones /
                (SELECT MAX(f2.intercepciones)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Lateral_derecho')
            ) * 0.30 +
            (f.asistencias /
                (SELECT MAX(f2.asistencias)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Lateral_derecho')
            ) * 0.20
        ) * 0.60 +
        d.champions     * 0.20 +
        d.internacional * 0.20
    , 3) AS puntuacion_final
FROM dim_jugadores d
JOIN fact_estadisticas f ON d.jugador = f.jugador
WHERE d.sub_posicion = 'Lateral_derecho'
ORDER BY puntuacion_final DESC;

-- -------------------------------------------------------------
-- 3.3 Convocatoria de laterales izquierdos — Sistema ponderado
-- Mismos criterios que laterales derechos.
-- -------------------------------------------------------------
SELECT
    d.jugador,
    d.sub_posicion,
    d.champions,
    d.internacional,
    ROUND(
        (
            (f.duelos_ganados /
                (SELECT MAX(f2.duelos_ganados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Lateral_izquierdo')
            ) * 0.50 +
            (f.intercepciones /
                (SELECT MAX(f2.intercepciones)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Lateral_izquierdo')
            ) * 0.30 +
            (f.asistencias /
                (SELECT MAX(f2.asistencias)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Lateral_izquierdo')
            ) * 0.20
        ) * 0.60 +
        d.champions     * 0.20 +
        d.internacional * 0.20
    , 3) AS puntuacion_final
FROM dim_jugadores d
JOIN fact_estadisticas f ON d.jugador = f.jugador
WHERE d.sub_posicion = 'Lateral_izquierdo'
ORDER BY puntuacion_final DESC;

-- -------------------------------------------------------------
-- 3.4 Convocatoria de defensas centrales — Sistema ponderado
-- Métricas estadísticas: duelos ganados (50%) +
--                        intercepciones (30%) +
--                        minutos disputados (20%)
-- -------------------------------------------------------------
SELECT
    d.jugador,
    d.sub_posicion,
    d.champions,
    d.internacional,
    ROUND(
        (
            (f.duelos_ganados /
                (SELECT MAX(f2.duelos_ganados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Defensa_central')
            ) * 0.50 +
            (f.intercepciones /
                (SELECT MAX(f2.intercepciones)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Defensa_central')
            ) * 0.30 +
            (f.minutos_disputados /
                (SELECT MAX(f2.minutos_disputados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Defensa_central')
            ) * 0.20
        ) * 0.60 +
        d.champions     * 0.20 +
        d.internacional * 0.20
    , 3) AS puntuacion_final
FROM dim_jugadores d
JOIN fact_estadisticas f ON d.jugador = f.jugador
WHERE d.sub_posicion = 'Defensa_central'
ORDER BY puntuacion_final DESC;

-- -------------------------------------------------------------
-- 3.5 Convocatoria de mediocampistas defensivos — Sistema ponderado
-- Métricas estadísticas: duelos ganados (35%) +
--                        intercepciones (35%) + asistencias (30%)
-- -------------------------------------------------------------
SELECT
    d.jugador,
    d.sub_posicion,
    d.champions,
    d.internacional,
    ROUND(
        (
            (f.duelos_ganados /
                (SELECT MAX(f2.duelos_ganados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Medio_centro_defensivo')
            ) * 0.35 +
            (f.intercepciones /
                (SELECT MAX(f2.intercepciones)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Medio_centro_defensivo')
            ) * 0.35 +
            (f.asistencias /
                (SELECT MAX(f2.asistencias)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Medio_centro_defensivo')
            ) * 0.30
        ) * 0.60 +
        d.champions     * 0.20 +
        d.internacional * 0.20
    , 3) AS puntuacion_final
FROM dim_jugadores d
JOIN fact_estadisticas f ON d.jugador = f.jugador
WHERE d.sub_posicion = 'Medio_centro_defensivo'
ORDER BY puntuacion_final DESC;

-- -------------------------------------------------------------
-- 3.6 Convocatoria de mediocampistas ofensivos — Sistema ponderado
-- Métricas estadísticas: goles (40%) +
--                        asistencias (40%) + duelos ganados (20%)
-- -------------------------------------------------------------
SELECT
    d.jugador,
    d.sub_posicion,
    d.champions,
    d.internacional,
    ROUND(
        (
            (f.goles /
                (SELECT MAX(f2.goles)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Medio_centro_ofensivo')
            ) * 0.40 +
            (f.asistencias /
                (SELECT MAX(f2.asistencias)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Medio_centro_ofensivo')
            ) * 0.40 +
            (f.duelos_ganados /
                (SELECT MAX(f2.duelos_ganados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Medio_centro_ofensivo')
            ) * 0.20
        ) * 0.60 +
        d.champions     * 0.20 +
        d.internacional * 0.20
    , 3) AS puntuacion_final
FROM dim_jugadores d
JOIN fact_estadisticas f ON d.jugador = f.jugador
WHERE d.sub_posicion = 'Medio_centro_ofensivo'
ORDER BY puntuacion_final DESC;

-- -------------------------------------------------------------
-- 3.7 Convocatoria de extremos derechos — Sistema ponderado
-- Métricas estadísticas: promedio simple de goles,
--                        duelos ganados y asistencias
-- -------------------------------------------------------------
SELECT
    d.jugador,
    d.sub_posicion,
    d.champions,
    d.internacional,
    ROUND(
        (
            (f.goles /
                (SELECT MAX(f2.goles)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Extremo_derecho')
            ) / 3 +
            (f.duelos_ganados /
                (SELECT MAX(f2.duelos_ganados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Extremo_derecho')
            ) / 3 +
            (f.asistencias /
                (SELECT MAX(f2.asistencias)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Extremo_derecho')
            ) / 3
        ) * 0.60 +
        d.champions     * 0.20 +
        d.internacional * 0.20
    , 3) AS puntuacion_final
FROM dim_jugadores d
JOIN fact_estadisticas f ON d.jugador = f.jugador
WHERE d.sub_posicion = 'Extremo_derecho'
ORDER BY puntuacion_final DESC;

-- -------------------------------------------------------------
-- 3.8 Convocatoria de extremos izquierdos — Sistema ponderado
-- Mismos criterios que extremos derechos.
-- -------------------------------------------------------------
SELECT
    d.jugador,
    d.sub_posicion,
    d.champions,
    d.internacional,
    ROUND(
        (
            (f.goles /
                (SELECT MAX(f2.goles)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Extremo_izquierdo')
            ) / 3 +
            (f.duelos_ganados /
                (SELECT MAX(f2.duelos_ganados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Extremo_izquierdo')
            ) / 3 +
            (f.asistencias /
                (SELECT MAX(f2.asistencias)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Extremo_izquierdo')
            ) / 3
        ) * 0.60 +
        d.champions     * 0.20 +
        d.internacional * 0.20
    , 3) AS puntuacion_final
FROM dim_jugadores d
JOIN fact_estadisticas f ON d.jugador = f.jugador
WHERE d.sub_posicion = 'Extremo_izquierdo'
ORDER BY puntuacion_final DESC;

-- -------------------------------------------------------------
-- 3.9 Convocatoria de delanteros — Sistema ponderado
-- Métricas estadísticas: goles (50%) +
--                        asistencias (30%) + duelos ganados (20%)
-- -------------------------------------------------------------
SELECT
    d.jugador,
    d.sub_posicion,
    d.champions,
    d.internacional,
    ROUND(
        (
            (f.goles /
                (SELECT MAX(f2.goles)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Delantero_centro')
            ) * 0.50 +
            (f.asistencias /
                (SELECT MAX(f2.asistencias)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Delantero_centro')
            ) * 0.30 +
            (f.duelos_ganados /
                (SELECT MAX(f2.duelos_ganados)
                 FROM fact_estadisticas f2
                 JOIN dim_jugadores d2 ON f2.jugador = d2.jugador
                 WHERE d2.sub_posicion = 'Delantero_centro')
            ) * 0.20
        ) * 0.60 +
        d.champions     * 0.20 +
        d.internacional * 0.20
    , 3) AS puntuacion_final
FROM dim_jugadores d
JOIN fact_estadisticas f ON d.jugador = f.jugador
WHERE d.sub_posicion = 'Delantero_centro'
ORDER BY puntuacion_final DESC;


-- =============================================================
-- SECCIÓN 4: Modelo estrella — carga y verificación de datos
-- Consultas para poblar las tablas del modelo estrella y
-- verificar la integridad de los datos cargados.
-- =============================================================

USE seleccion_espana_estrella;

-- Insertar datos en las tablas de dimensiones desde
-- la base de datos anterior seleccion_espana_modelo
INSERT INTO dim_jugadores (jugador, nacionalidad)
SELECT jugador, nacionalidad
FROM seleccion_espana_modelo.dim_jugadores;

INSERT INTO dim_posiciones (posicion, sub_posicion)
SELECT DISTINCT posicion, sub_posicion
FROM seleccion_espana_modelo.dim_jugadores;

INSERT INTO dim_experiencia (champions, internacional)
SELECT DISTINCT champions, internacional
FROM seleccion_espana_modelo.dim_jugadores;

INSERT INTO dim_convocatoria (convocado, puntuacion_final)
VALUES
    ('Convocado',    NULL),
    ('Contingencia', NULL),
    ('No convocado', NULL);

-- Insertar datos en la tabla de hechos
INSERT INTO fact_estadisticas (
    id_jugador, id_posicion, id_experiencia, id_convocatoria,
    partidos_jugados, partidos_titular, minutos_disputados,
    goles, asistencias, duelos_ganados, intercepciones,
    disparos_a_puerta, goles_en_contra, goles_salvados,
    goles_en_contra_por_partido, intentos_penalty,
    penaltys_permitidos, penaltys_salvados,
    porcentaje_penaltys_salvados, salvadas_por_partido
)
SELECT
    dj.id_jugador,
    dp.id_posicion,
    de.id_experiencia,
    dc.id_convocatoria,
    f.partidos_jugados, f.partidos_titular, f.minutos_disputados,
    f.goles, f.asistencias, f.duelos_ganados, f.intercepciones,
    f.disparos_a_puerta, f.goles_en_contra, f.goles_salvados,
    f.goles_en_contra_por_partido, f.intentos_penalty,
    f.penaltys_permitidos, f.penaltys_salvados,
    f.porcentaje_penaltys_salvados, f.salvadas_por_partido
FROM seleccion_espana_modelo.fact_estadisticas f
JOIN seleccion_espana_modelo.dim_jugadores d  ON f.jugador      = d.jugador
JOIN dim_jugadores dj                         ON d.jugador      = dj.jugador
JOIN dim_posiciones dp                        ON d.sub_posicion = dp.sub_posicion
JOIN dim_experiencia de                       ON d.champions    = de.champions
                                             AND d.internacional = de.internacional
JOIN dim_convocatoria dc                      ON dc.convocado   = 'No convocado';

-- Actualizar estado de convocatoria — jugadores convocados
SET SQL_SAFE_UPDATES = 0;

UPDATE fact_estadisticas f
JOIN dim_jugadores dj ON f.id_jugador = dj.id_jugador
SET f.id_convocatoria = 1
WHERE dj.jugador IN (
    'Unai Simon', 'Robert Sanchez', 'Joan Garcia',
    'Marcos Llorente', 'Pedro Porro',
    'Marc Cucurella', 'Alfonso Pedraza',
    'Eric Garcia', 'Daniel Vivian', 'Pau Cubarsi', 'Marcos Alonso',
    'Antonio Blanco', 'Pedri', 'Martin Zubimendi', 'Aleix Garcia',
    'Dani Olmo', 'Fermin Lopez', 'Pablo Fornals', 'Oihan Sancet',
    'Lamine Yamal', 'Yeremi Pino',
    'Alberto Moleiro', 'Nico Williams',
    'Ferran Torres', 'Mikel Oyarzabal', 'Borja Iglesias'
);

-- Actualizar estado de convocatoria — jugadores de contingencia
UPDATE fact_estadisticas f
JOIN dim_jugadores dj ON f.id_jugador = dj.id_jugador
SET f.id_convocatoria = 2
WHERE dj.jugador IN (
    'David de Gea', 'Iglesias', 'Alex Grimaldo',
    'Jonny Castro', 'Koke', 'Brais Mendez',
    'Ruben Garcia', 'Alex Baena', 'Jorge de Frutos'
);

SET SQL_SAFE_UPDATES = 1;

-- Verificación del modelo estrella — conteo por posición y estado
SELECT
    dp.sub_posicion,
    dc.convocado,
    COUNT(*) AS total
FROM fact_estadisticas f
JOIN dim_posiciones  dp ON f.id_posicion     = dp.id_posicion
JOIN dim_convocatoria dc ON f.id_convocatoria = dc.id_convocatoria
GROUP BY dp.sub_posicion, dc.convocado
ORDER BY dp.sub_posicion, dc.convocado;


-- =============================================================
-- SECCIÓN 5: Sistema de puntuación unificada
-- Consultas UPDATE para calcular y almacenar la puntuación
-- final de cada jugador directamente en fact_estadisticas.
-- Se aplica el mismo sistema de ponderación 60/20/20 pero
-- los resultados se persisten en la base de datos para
-- ser consumidos directamente por Power BI.
-- =============================================================

USE seleccion_espana_estrella;

SET SQL_SAFE_UPDATES = 0;

-- 5.1 Puntuación de porteros
UPDATE fact_estadisticas f
JOIN dim_jugadores dj  ON f.id_jugador  = dj.id_jugador
JOIN dim_posiciones dp ON f.id_posicion = dp.id_posicion
SET f.puntuacion_final = ROUND(
    (
        (f.goles_salvados /
            (SELECT MAX(f2.goles_salvados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Portero')
        ) * 0.50 +
        (f.salvadas_por_partido /
            (SELECT MAX(f2.salvadas_por_partido)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Portero')
        ) * 0.50
    ) * 0.60 +
    (SELECT champions    FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20 +
    (SELECT internacional FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20
, 3)
WHERE dp.sub_posicion = 'Portero';

-- 5.2 Puntuación de laterales derechos
UPDATE fact_estadisticas f
JOIN dim_jugadores dj  ON f.id_jugador  = dj.id_jugador
JOIN dim_posiciones dp ON f.id_posicion = dp.id_posicion
SET f.puntuacion_final = ROUND(
    (
        (f.duelos_ganados /
            (SELECT MAX(f2.duelos_ganados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Lateral_derecho')
        ) * 0.50 +
        (f.intercepciones /
            (SELECT MAX(f2.intercepciones)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Lateral_derecho')
        ) * 0.30 +
        (f.asistencias /
            (SELECT MAX(f2.asistencias)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Lateral_derecho')
        ) * 0.20
    ) * 0.60 +
    (SELECT champions    FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20 +
    (SELECT internacional FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20
, 3)
WHERE dp.sub_posicion = 'Lateral_derecho';

-- 5.3 Puntuación de laterales izquierdos
UPDATE fact_estadisticas f
JOIN dim_jugadores dj  ON f.id_jugador  = dj.id_jugador
JOIN dim_posiciones dp ON f.id_posicion = dp.id_posicion
SET f.puntuacion_final = ROUND(
    (
        (f.duelos_ganados /
            (SELECT MAX(f2.duelos_ganados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Lateral_izquierdo')
        ) * 0.50 +
        (f.intercepciones /
            (SELECT MAX(f2.intercepciones)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Lateral_izquierdo')
        ) * 0.30 +
        (f.asistencias /
            (SELECT MAX(f2.asistencias)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Lateral_izquierdo')
        ) * 0.20
    ) * 0.60 +
    (SELECT champions    FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20 +
    (SELECT internacional FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20
, 3)
WHERE dp.sub_posicion = 'Lateral_izquierdo';

-- 5.4 Puntuación de defensas centrales
UPDATE fact_estadisticas f
JOIN dim_jugadores dj  ON f.id_jugador  = dj.id_jugador
JOIN dim_posiciones dp ON f.id_posicion = dp.id_posicion
SET f.puntuacion_final = ROUND(
    (
        (f.duelos_ganados /
            (SELECT MAX(f2.duelos_ganados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Defensa_central')
        ) * 0.50 +
        (f.intercepciones /
            (SELECT MAX(f2.intercepciones)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Defensa_central')
        ) * 0.30 +
        (f.minutos_disputados /
            (SELECT MAX(f2.minutos_disputados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Defensa_central')
        ) * 0.20
    ) * 0.60 +
    (SELECT champions    FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20 +
    (SELECT internacional FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20
, 3)
WHERE dp.sub_posicion = 'Defensa_central';

-- 5.5 Puntuación de mediocampistas defensivos
UPDATE fact_estadisticas f
JOIN dim_jugadores dj  ON f.id_jugador  = dj.id_jugador
JOIN dim_posiciones dp ON f.id_posicion = dp.id_posicion
SET f.puntuacion_final = ROUND(
    (
        (f.duelos_ganados /
            (SELECT MAX(f2.duelos_ganados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Medio_centro_defensivo')
        ) * 0.35 +
        (f.intercepciones /
            (SELECT MAX(f2.intercepciones)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Medio_centro_defensivo')
        ) * 0.35 +
        (f.asistencias /
            (SELECT MAX(f2.asistencias)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Medio_centro_defensivo')
        ) * 0.30
    ) * 0.60 +
    (SELECT champions    FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20 +
    (SELECT internacional FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20
, 3)
WHERE dp.sub_posicion = 'Medio_centro_defensivo';

-- 5.6 Puntuación de mediocampistas ofensivos
UPDATE fact_estadisticas f
JOIN dim_jugadores dj  ON f.id_jugador  = dj.id_jugador
JOIN dim_posiciones dp ON f.id_posicion = dp.id_posicion
SET f.puntuacion_final = ROUND(
    (
        (f.goles /
            (SELECT MAX(f2.goles)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Medio_centro_ofensivo')
        ) * 0.40 +
        (f.asistencias /
            (SELECT MAX(f2.asistencias)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Medio_centro_ofensivo')
        ) * 0.40 +
        (f.duelos_ganados /
            (SELECT MAX(f2.duelos_ganados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Medio_centro_ofensivo')
        ) * 0.20
    ) * 0.60 +
    (SELECT champions    FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20 +
    (SELECT internacional FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20
, 3)
WHERE dp.sub_posicion = 'Medio_centro_ofensivo';

-- 5.7 Puntuación de extremos derechos
UPDATE fact_estadisticas f
JOIN dim_jugadores dj  ON f.id_jugador  = dj.id_jugador
JOIN dim_posiciones dp ON f.id_posicion = dp.id_posicion
SET f.puntuacion_final = ROUND(
    (
        (f.goles /
            (SELECT MAX(f2.goles)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Extremo_derecho')
        ) / 3 +
        (f.duelos_ganados /
            (SELECT MAX(f2.duelos_ganados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Extremo_derecho')
        ) / 3 +
        (f.asistencias /
            (SELECT MAX(f2.asistencias)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Extremo_derecho')
        ) / 3
    ) * 0.60 +
    (SELECT champions    FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20 +
    (SELECT internacional FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20
, 3)
WHERE dp.sub_posicion = 'Extremo_derecho';

-- 5.8 Puntuación de extremos izquierdos
UPDATE fact_estadisticas f
JOIN dim_jugadores dj  ON f.id_jugador  = dj.id_jugador
JOIN dim_posiciones dp ON f.id_posicion = dp.id_posicion
SET f.puntuacion_final = ROUND(
    (
        (f.goles /
            (SELECT MAX(f2.goles)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Extremo_izquierdo')
        ) / 3 +
        (f.duelos_ganados /
            (SELECT MAX(f2.duelos_ganados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Extremo_izquierdo')
        ) / 3 +
        (f.asistencias /
            (SELECT MAX(f2.asistencias)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Extremo_izquierdo')
        ) / 3
    ) * 0.60 +
    (SELECT champions    FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20 +
    (SELECT internacional FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20
, 3)
WHERE dp.sub_posicion = 'Extremo_izquierdo';

-- 5.9 Puntuación de delanteros
UPDATE fact_estadisticas f
JOIN dim_jugadores dj  ON f.id_jugador  = dj.id_jugador
JOIN dim_posiciones dp ON f.id_posicion = dp.id_posicion
SET f.puntuacion_final = ROUND(
    (
        (f.goles /
            (SELECT MAX(f2.goles)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Delantero_centro')
        ) * 0.50 +
        (f.asistencias /
            (SELECT MAX(f2.asistencias)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Delantero_centro')
        ) * 0.30 +
        (f.duelos_ganados /
            (SELECT MAX(f2.duelos_ganados)
             FROM seleccion_espana_modelo.fact_estadisticas f2
             JOIN seleccion_espana_modelo.dim_jugadores d2 ON f2.jugador = d2.jugador
             WHERE d2.sub_posicion = 'Delantero_centro')
        ) * 0.20
    ) * 0.60 +
    (SELECT champions    FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20 +
    (SELECT internacional FROM seleccion_espana_modelo.dim_jugadores WHERE jugador = dj.jugador) * 0.20
, 3)
WHERE dp.sub_posicion = 'Delantero_centro';

SET SQL_SAFE_UPDATES = 1;

-- Consulta final de verificación — convocatoria completa ordenada
SELECT
    dp.sub_posicion,
    dj.jugador,
    dc.convocado,
    f.puntuacion_final
FROM fact_estadisticas f
JOIN dim_jugadores   dj ON f.id_jugador     = dj.id_jugador
JOIN dim_posiciones  dp ON f.id_posicion    = dp.id_posicion
JOIN dim_convocatoria dc ON f.id_convocatoria = dc.id_convocatoria
WHERE dc.convocado IN ('Convocado', 'Contingencia')
ORDER BY dp.sub_posicion, dc.convocado, f.puntuacion_final DESC;
