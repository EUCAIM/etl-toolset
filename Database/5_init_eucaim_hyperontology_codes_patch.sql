-- Step 5 Eucaim Hyperontology temporary patches (to be removed)

CREATE SEQUENCE IF NOT EXISTS eucaim_hyperontology_codes.eucaim_concept_id_seq;

SELECT setval('eucaim_hyperontology_codes.eucaim_concept_id_seq', (SELECT MAX(concept_id) FROM eucaim_hyperontology_codes.concept));

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001366', 'https://cancerimage.eu/ontology/EUCAIM#COM1001366', 'MALE');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001370', 'https://cancerimage.eu/ontology/EUCAIM#COM1001370', 'FEMALE');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1016670', 'https://cancerimage.eu/ontology/EUCAIM#IMG1016670', 'Left');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1016682', 'https://cancerimage.eu/ontology/EUCAIM#IMG1016682', 'Right');


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1007990', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1007990', 'Glioblastoma');


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1000069', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1000069', 'Epithelioid');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1000082', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1000082', 'Gliosarcoma');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1000073', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1000073', 'Giant cells');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1000081', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1000081', 'Oligodendroglioma component');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1059392', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1059392', 'Thyroid cancer');


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'BP1000420', 'https://cancerimage.eu/ontology/EUCAIM#BP1000420', 'Frontal brain region');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'BP1000421', 'https://cancerimage.eu/ontology/EUCAIM#BP1000421', 'Temporal brain region');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'BP1000422', 'https://cancerimage.eu/ontology/EUCAIM#BP1000422', 'Parietal brain region');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'BP1000419', 'https://cancerimage.eu/ontology/EUCAIM#BP1000419', 'Occipital brain region');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'BP1000419', 'https://cancerimage.eu/ontology/EUCAIM#BP1000419', 'Occipital brain region');


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1000022', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000022', 'MRI');


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1022113', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1022113', 'Grade 1 tumor');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1022150', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1022150', 'Grade 2 tumor');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1022188', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1022188', 'Grade 3 tumor');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1022227', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1022227', 'Grade 4 tumor');


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1047414', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1047414', 'ASA Classification');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1052872', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052872', 'ASA physical status class 1');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1052871', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052871', 'ASA physical status class 2');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1052870', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1047414', 'ASA physical status class 3');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1052869', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052869', 'ASA physical status class 4');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1052868', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052868', 'ASA physical status class 5');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1052867', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1052867', 'ASA physical status class 6');


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1049762', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1049762', 'Percent of cell nuclei positive for proliferation marker protein Ki-67 in primary malignant neoplasm by immunohistochemistry');


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1000026', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000026', 'Computed tomography');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1000079', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000079', 'Scintigraphy');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1000146', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000146', 'Axial scan mode');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1005453', 'https://cancerimage.eu/ontology/EUCAIM#IMG1005453', 'Imaging (Procedure)');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001954', 'https://cancerimage.eu/ontology/EUCAIM#COM1001954', 'centimeter');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1000022', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000038', 'Magnetic resonance imaging');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1000030', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000030', 'Mammography');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001087', 'https://cancerimage.eu/ontology/EUCAIM#COM1001087', 'Patient with Cancer');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001950', 'https://cancerimage.eu/ontology/EUCAIM#COM1001950', 'Gy');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001035', 'https://cancerimage.eu/ontology/EUCAIM#COM1001035', 'Father');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001036', 'https://cancerimage.eu/ontology/EUCAIM#COM1001036', 'Mother');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1005507', 'https://cancerimage.eu/ontology/EUCAIM#IMG1005507', 'MRI of prostate');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1016659', 'https://cancerimage.eu/ontology/EUCAIM#IMG1016659', 'Bilateral');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001313', 'https://cancerimage.eu/ontology/EUCAIM#COM1001313', 'Mutated');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001887', 'https://cancerimage.eu/ontology/EUCAIM#COM1001887', 'Not mutated');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001889', 'https://cancerimage.eu/ontology/EUCAIM#COM1001889', 'Not methylated');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001314', 'https://cancerimage.eu/ontology/EUCAIM#COM1001314', 'Methylated');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001099', 'https://cancerimage.eu/ontology/EUCAIM#COM1001099', 'Surgery');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1047415', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1047415', 'Karnofsky performance status');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1035837', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1035837', 'Bevacizumab');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'BP1000419', 'https://cancerimage.eu/ontology/EUCAIM#BP1000419', 'Occipital region');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'BP1000421', 'https://cancerimage.eu/ontology/EUCAIM#BP1000421', 'Temporal brain region');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'BP1000422', 'https://cancerimage.eu/ontology/EUCAIM#BP1000422', 'Parietal region');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'BP1000420', 'https://cancerimage.eu/ontology/EUCAIM#BP1000420', 'Frontal brain region');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '45552258', 'https://cancerimage.eu/ontology/EUCAIM#45552258', 'C49');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '3357489', 'https://cancerimage.eu/ontology/EUCAIM#3357489', '409063005');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '45934692', 'https://cancerimage.eu/ontology/EUCAIM#45934692', 'VMAT');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '4242373', 'https://cancerimage.eu/ontology/EUCAIM#4242373', 'C-arm LINAC');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '45561808', 'https://cancerimage.eu/ontology/EUCAIM#45561808', 'C48');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '1243937', 'https://cancerimage.eu/ontology/EUCAIM#1243937', 'SBRT');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '4245119', 'https://cancerimage.eu/ontology/EUCAIM#4245119', 'CyberKnife');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '4264018', 'https://cancerimage.eu/ontology/EUCAIM#4264018', 'Left Thigh');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '4008238', 'https://cancerimage.eu/ontology/EUCAIM#4008238', 'Right Thigh');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '36770706', 'https://cancerimage.eu/ontology/EUCAIM#36770706', 'Retroperitoneum');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '1448029', 'https://cancerimage.eu/ontology/EUCAIM#1448029', 'Right tibia');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '36714295', 'https://cancerimage.eu/ontology/EUCAIM#36714295', 'Left Humerus');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '4284053', 'https://cancerimage.eu/ontology/EUCAIM#4284053', 'Right forearm');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '37528190', 'https://cancerimage.eu/ontology/EUCAIM#37528190', 'Right glute');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '1448030', 'https://cancerimage.eu/ontology/EUCAIM#1448030', 'Left tibia');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '45595663', 'https://cancerimage.eu/ontology/EUCAIM#45595663', 'C49.21');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), '45552260', 'https://cancerimage.eu/ontology/EUCAIM#45552260', 'C49.22');















