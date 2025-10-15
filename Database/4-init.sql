-- Step 4 Eucaim Hyperontology temporary patches (to be removed)

CREATE SEQUENCE eucaim_concept_id_seq;

SELECT setval('eucaim_concept_id_seq', (SELECT MAX(concept_id) FROM concept));


INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'IMG1016670', 'https://cancerimage.eu/ontology/EUCAIM#IMG1016670', 'Left');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'IMG1016682', 'https://cancerimage.eu/ontology/EUCAIM#IMG1016682', 'Right');


INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1007991', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1007991', 'Glioblastoma');


INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1000069', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1000069', 'Epithelioid');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1000082', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1000082', 'Gliosarcoma');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1000073', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1000073', 'Giant cells');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1000081', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1000081', 'Oligodendroglioma component');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1059392', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1059392', 'Thyroid cancer');


INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'BP1000420', 'https://cancerimage.eu/ontology/EUCAIM#BP1000420', 'Frontal brain region');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'BP1000421', 'https://cancerimage.eu/ontology/EUCAIM#BP1000421', 'Temporal brain region');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'BP1000422', 'https://cancerimage.eu/ontology/EUCAIM#BP1000422', 'Parietal brain region');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'BP1000419', 'https://cancerimage.eu/ontology/EUCAIM#BP1000419', 'Occipital brain region');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'BP1000419', 'https://cancerimage.eu/ontology/EUCAIM#BP1000419', 'Occipital brain region');


INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'IMG1000022', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000022', 'MRI');


INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1022113', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1022113', 'Grade 1 tumor');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1022150', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1022150', 'Grade 2 tumor');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1022188', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1022188', 'Grade 3 tumor');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1022227', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1022227', 'Grade 4 tumor');


INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1047414', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1047414', 'ASA Classification');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1052872', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052872', 'ASA physical status class 1');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1052871', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052871', 'ASA physical status class 2');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1052870', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1047414', 'ASA physical status class 3');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1052869', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052869', 'ASA physical status class 4');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1052868', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052868', 'ASA physical status class 5');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1052867', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052867', 'ASA physical status class 6');


INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'CLIN1049762', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1049762', 'Percent of cell nuclei positive for proliferation marker protein Ki-67 in primary malignant neoplasm by immunohistochemistry');


INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'IMG1000026', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000026', 'Computed tomography');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'IMG1000079', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000079', 'Scintigraphy');

INSERT INTO concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_concept_id_seq'), 'IMG1000146', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000146', 'Axial scan mode');

INSERT INTO concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_concept_id_seq'), 'IMG1005453', 'https://cancerimage.eu/ontology/EUCAIM#IMG1005453', 'Imaging (Procedure)');

INSERT INTO concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_concept_id_seq'), 'COM1001954', 'https://cancerimage.eu/ontology/EUCAIM#COM1001954', 'centimeter');

INSERT INTO concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_concept_id_seq'), 'IMG1000038', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000038', 'Magnetic resonance imaging');

INSERT INTO concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_concept_id_seq'), 'COM1001087', 'https://cancerimage.eu/ontology/EUCAIM#COM1001087', 'Patient with Cancer');

INSERT INTO concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_concept_id_seq'), 'COM1001950', 'https://cancerimage.eu/ontology/EUCAIM#COM1001950', 'Gy');
