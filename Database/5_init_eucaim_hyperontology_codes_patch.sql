-- Step 4 Eucaim Hyperontology temporary patches (to be removed)

CREATE SEQUENCE eucaim_hyperontology_codes.eucaim_concept_id_seq;

SELECT setval('eucaim_hyperontology_codes.eucaim_concept_id_seq', (SELECT MAX(concept_id) FROM eucaim_hyperontology_codes.concept));


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1016670', 'https://cancerimage.eu/ontology/EUCAIM#IMG1016670', 'Left');

INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1016682', 'https://cancerimage.eu/ontology/EUCAIM#IMG1016682', 'Right');


INSERT INTO eucaim_hyperontology_codes.concept (concept_id, concept_code, concept_uri, concept_name)
VALUES (nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1007991', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1007991', 'Glioblastoma');


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
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'IMG1000038', 'https://cancerimage.eu/ontology/EUCAIM#IMG1000038', 'Magnetic resonance imaging');

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
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1000068', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1000068', 'Primary malignant neoplasm of breast');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001186', 'https://cancerimage.eu/ontology/EUCAIM#COM1001186', 'Partial response');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001310', 'https://cancerimage.eu/ontology/EUCAIM#COM1001310', 'Positive');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001332', 'https://cancerimage.eu/ontology/EUCAIM#COM1001332', 'Negative');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1002025', 'https://cancerimage.eu/ontology/EUCAIM#COM1002025', 'High');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1001718', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1001718', 'Sentinel lymph node biopsy');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1001312', 'https://cancerimage.eu/ontology/EUCAIM#COM1001312', 'Complete response');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1034672', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1034672', 'Excision of breast');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1063529', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1063529', 'Invasive ductal carcinoma with an extensive intraductal component');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1001717', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1001717', 'Biopsy of lymph node');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1034673', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1034673', 'Breast Conservation Treatment');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1005277', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1005277', 'External beam radiation therapy procedure');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'COM1002172', 'https://cancerimage.eu/ontology/EUCAIM#COM1002172', 'Low');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1035832', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1035832', 'Fulvestrant');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1035831', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1035831', 'IPATASERTIB');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1035061', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1035061', 'Nab paclitaxel');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1035830', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1035830', 'Granulocyte colony-stimulating factor');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1035833', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1035833', 'Anthracycline');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1065557', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1065557', 'AJCC/UICC 8th clinical T0 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1063940', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1063940', 'AJCC/UICC 8th clinical T1 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1070457', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1070457', 'AJCC/UICC 8th clinical T1a Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1110758', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1110758', 'AJCC/UICC 8th clinical T1a1 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1111065', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1111065', 'AJCC/UICC 8th clinical T1a2 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1070115', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1070115', 'AJCC/UICC 8th clinical T1b Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1099833', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1099833', 'AJCC/UICC 8th clinical T1b1 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1099298', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1099298', 'AJCC/UICC 8th clinical T1b2 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1099565', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1099565', 'AJCC/UICC 8th clinical T1b3 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1070573', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1070573', 'AJCC/UICC 8th clinical T1c Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1113242', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1113242', 'AJCC/UICC 8th clinical T1c1 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1113557', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1113557', 'AJCC/UICC 8th clinical T1c2 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1113873', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1113873', 'AJCC/UICC 8th clinical T1c3 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1070342', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1070342', 'AJCC/UICC 8th clinical T1d Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1070228', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1070228', 'AJCC/UICC 8th clinical T1mi Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1063997', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1063997', 'AJCC/UICC 8th clinical N0 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1071662', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1071662', 'AJCC/UICC 8th clinical N0a Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1071537', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1071537', 'AJCC/UICC 8th clinical N0b Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1063842', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1063842', 'AJCC/UICC 8th clinical N1 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1067703', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1067703', 'AJCC/UICC 8th clinical N1a Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1067882', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1067882', 'AJCC/UICC 8th clinical N1b Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1115147', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1115147', 'AJCC/UICC 8th clinical N1b1 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1114827', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1114827', 'AJCC/UICC 8th clinical N1b2 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1114190', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1114190', 'AJCC/UICC 8th clinical N1b3 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1114508', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1114508', 'AJCC/UICC 8th clinical N1b4 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1067615', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1067615', 'AJCC/UICC 8th clinical N1c Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1067792', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1067792', 'AJCC/UICC 8th clinical N1mi Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1063907', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1063907', 'AJCC/UICC 8th clinical N2 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1069673', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1069673', 'AJCC/UICC 8th clinical N2a Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1069458', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1069458', 'AJCC/UICC 8th clinical N2b Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1069352', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1069352', 'AJCC/UICC 8th clinical N2c Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1069565', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1069565', 'AJCC/UICC 8th clinical N2mi Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1063923', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1063923', 'AJCC/UICC 8th clinical N3 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1069892', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1069892', 'AJCC/UICC 8th clinical N3a Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1070003', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1070003', 'AJCC/UICC 8th clinical N3b Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1069782', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1069782', 'AJCC/UICC 8th clinical N3c Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1072967', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1072967', 'AJCC/UICC 8th clinical NX Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1064417', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1064417', 'AJCC/UICC 8th clinical M0 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1063977', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1063977', 'AJCC/UICC 8th clinical M1 Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1071413', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1071413', 'AJCC/UICC 8th clinical M1a Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1071047', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1071047', 'AJCC/UICC 8th clinical M1b Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1071168', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1071168', 'AJCC/UICC 8th clinical M1c Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1071290', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1071290', 'AJCC/UICC 8th clinical M1d Category');

INSERT INTO eucaim_hyperontology_codes.concept(concept_id, concept_code, concept_uri, concept_name)
VALUES(nextval('eucaim_hyperontology_codes.eucaim_concept_id_seq'), 'CLIN1073798', 'https://cancerimage.eu/ontology/EUCAIM#CLIN1073798', 'AJCC/UICC 8th clinical MX Category');




