-- Step 3z (OPCIONAL) Relajar los required de segmentation_series
--
-- QUIEN NO QUIERA ESTA DIVERGENCIA SOLO TIENE QUE BORRAR ESTE FICHERO.
--
-- El CDM v4.1 marca como required source_series_uid y segmentation_algorithm_type de
-- eucaim_cdm_output.segmentation_series. Los dos salen de dentro del objeto DICOM SEG
-- (ReferencedSeriesSequence y SegmentAlgorithmType), y el extractor actual solo emite
-- metadatos a nivel de serie: mientras siga asi, exigirlos deja la tabla permanentemente
-- vacia aunque las segmentaciones se esten ingestando bien.
--
-- Este paso cambia ese compromiso para quien lo aplique: prefiere publicar la serie de
-- segmentacion incompleta a no publicarla. Es temporal y esta pendiente de negociar.
--
-- eucaim_etl_aux.transform_dataset_v001 NO asume cual de los dos modos esta activo: lo
-- consulta en information_schema y filtra en consecuencia. Con este paso aplicado publica
-- tambien las incompletas; sin el, publica solo las completas. En ambos casos avisa de
-- cuantas quedan en cada situacion, y en ninguno falla. Por eso borrar este fichero es
-- suficiente, sin tocar nada mas.

ALTER TABLE eucaim_cdm_output.segmentation_series
    ALTER COLUMN source_series_uid DROP NOT NULL;

ALTER TABLE eucaim_cdm_output.segmentation_series
    ALTER COLUMN segmentation_algorithm_type DROP NOT NULL;
