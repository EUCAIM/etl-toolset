-- Step 5z Eucaim Hyperontology: deduplicación de concept
--
-- Los pasos 1, 5_patch y 5_update insertan los conceptos sin comprobar si ya estaban:
-- 6.454 INSERT para 4.224 códigos distintos, con 2.222 códigos repetidos. MALE
-- (COM1001366) y FEMALE (COM1001370) acaban con tres filas cada uno, una por fichero.
--
-- No es solo ruido en la tabla. CodeableConceptLookupService resuelve por nombre:
--
--     SELECT c.concept_code FROM concept c
--     WHERE lower(c.concept_name) = lower(?) ORDER BY c.concept_id
--
-- y, si la consulta devuelve más de una fila, emite un WARN de "AMBIGUOUS term" por cada
-- lookup. Con las copias idénticas ese aviso es falso -- las tres filas llevan el mismo
-- concept_code -- y ahoga en el log los avisos de ambigüedad reales, que son los nombres
-- compartidos por códigos DISTINTOS (47 casos, ver más abajo).
--
-- Qué borra este paso: solo las filas que repiten (concept_code, nombre) de otra fila con
-- un concept_id menor. Como el servicio ya se queda con el concept_id más bajo, el código
-- que resuelve cada término no cambia: es una limpieza sin cambio de comportamiento.
--
-- Qué NO borra: 34 códigos cuyas copias traen nombres distintos. Ahí la fila repetida está
-- haciendo de sinónimo y borrarla dejaría de resolver un término que hoy funciona --
-- 'Radiotherapy' y 'Radiation oncology AND/OR radiotherapy' apuntan los dos a CLIN1014933.
-- Su sitio es eucaim_hyperontology_codes.concept_synonym, que está cargada con 2.264
-- sinónimos y que el ETL no consulta todavía. Mientras siga sin consultarla, estas filas
-- se quedan donde están.
--
-- Nada fuera de concept referencia los concept_id que se borran: concept_relationship,
-- concept_synonym y concept_external_mapping solo apuntan a ids <= 2333, cargados en el
-- paso 1, y los duplicados que caen aquí nacieron de nextval() en los pasos 5, con ids
-- por encima de 2361.

-- 1. Duplicados exactos de (código, nombre): se queda el concept_id más bajo.
DELETE FROM eucaim_hyperontology_codes.concept c
WHERE EXISTS (
    SELECT 1
    FROM eucaim_hyperontology_codes.concept keep
    WHERE keep.concept_code = c.concept_code
      AND lower(keep.concept_name) IS NOT DISTINCT FROM lower(c.concept_name)
      AND keep.concept_id < c.concept_id
);

-- 2. concept_synonym viene del paso 1 y no tiene clave: le quitamos las filas repetidas
--    para que el fallback por sinónimo, cuando se active, no herede el mismo problema.
DELETE FROM eucaim_hyperontology_codes.concept_synonym s
WHERE EXISTS (
    SELECT 1
    FROM eucaim_hyperontology_codes.concept_synonym keep
    WHERE keep.concept_id = s.concept_id
      AND lower(keep.synonym) = lower(s.synonym)
      AND keep.ctid < s.ctid
);

-- 3. Que no vuelva a pasar. No se puede exigir UNIQUE(concept_code) mientras los 34 códigos
--    con nombre alternativo sigan en esta tabla, así que la unicidad se pide sobre el par
--    (código, nombre), que deja pasar la fila-sinónimo legítima. Ojo: el índice no hace
--    idempotentes los pasos 5 -- son INSERT pelados, sin ON CONFLICT --, los hace fallar.
--    Volver a lanzar 5_update a mano aborta con "duplicate key value violates unique
--    constraint" en vez de duplicar la tabla en silencio, que es el comportamiento que
--    queremos. En el arranque normal no salta: initdb.d corre cada fichero una sola vez y
--    este paso va después de los INSERT.
CREATE UNIQUE INDEX IF NOT EXISTS concept_code_name_uq
    ON eucaim_hyperontology_codes.concept (concept_code, lower(concept_name));

CREATE UNIQUE INDEX IF NOT EXISTS concept_synonym_uq
    ON eucaim_hyperontology_codes.concept_synonym (concept_id, lower(synonym));

-- 4. Aviso sobre lo que queda: ambigüedad real (un nombre, varios códigos) y las
--    filas-sinónimo pendientes de mover a concept_synonym.
DO $$
DECLARE n_amb INTEGER; n_alias INTEGER;
BEGIN
    SELECT count(*) INTO n_amb FROM (
        SELECT lower(concept_name) FROM eucaim_hyperontology_codes.concept
        GROUP BY lower(concept_name) HAVING count(DISTINCT concept_code) > 1
    ) t;
    SELECT count(*) INTO n_alias FROM (
        SELECT concept_code FROM eucaim_hyperontology_codes.concept
        GROUP BY concept_code HAVING count(*) > 1
    ) t;
    RAISE NOTICE 'concept: % nombres resuelven a mas de un concept_code (el lookup se queda '
                 'con el concept_id mas bajo); % codigos conservan una fila-sinonimo.',
                 n_amb, n_alias;
END$$;
