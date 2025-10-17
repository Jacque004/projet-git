-- Rôles et privilèges RBAC MySQL (MySQL 8+)
-- Catégories: admin_data, medecin, infirmier, secretaire, tech_labo, analyst, readonly, app_service

USE `MedicalDB`;

-- Nettoyage préalable (idempotent)
DROP ROLE IF EXISTS `r_admin_data`, `r_medecin`, `r_infirmier`, `r_secretaire`, `r_tech_labo`, `r_analyst`, `r_readonly`, `r_app_service`;

CREATE ROLE `r_admin_data`;
CREATE ROLE `r_medecin`;
CREATE ROLE `r_infirmier`;
CREATE ROLE `r_secretaire`;
CREATE ROLE `r_tech_labo`;
CREATE ROLE `r_analyst`;
CREATE ROLE `r_readonly`;
CREATE ROLE `r_app_service`;

-- Base: lecture
GRANT SELECT ON `MedicalDB`.* TO `r_readonly`;

-- Analyste: accès aux vues anonymisées + lecture sélective
GRANT SELECT ON `MedicalDB`.`v_patients_anonymes` TO `r_analyst`;
GRANT SELECT ON `MedicalDB`.`v_rencontres_anon` TO `r_analyst`;
GRANT SELECT ON `MedicalDB`.`v_analyses_anon` TO `r_analyst`;

-- Secrétariat: gestion rdv, lecture patients
GRANT SELECT, INSERT, UPDATE ON `MedicalDB`.`rendez_vous` TO `r_secretaire`;
GRANT SELECT ON `MedicalDB`.`patients` TO `r_secretaire`;
GRANT SELECT ON `MedicalDB`.`etablissements` TO `r_secretaire`;

-- Médecin: CRUD dossiers, lecture patients/rencontres/analyses, écrire accès patient
GRANT SELECT, INSERT, UPDATE ON `MedicalDB`.`dossiers_medicaux` TO `r_medecin`;
GRANT SELECT ON `MedicalDB`.`patients` TO `r_medecin`;
GRANT SELECT ON `MedicalDB`.`rencontres` TO `r_medecin`;
GRANT SELECT ON `MedicalDB`.`analyses_labo` TO `r_medecin`;
GRANT INSERT ON `MedicalDB`.`patient_access_logs` TO `r_medecin`;

-- Infirmier: lecture principaux, création notes basiques
GRANT SELECT ON `MedicalDB`.`patients` TO `r_infirmier`;
GRANT SELECT ON `MedicalDB`.`rencontres` TO `r_infirmier`;
GRANT SELECT ON `MedicalDB`.`analyses_labo` TO `r_infirmier`;
GRANT SELECT, INSERT ON `MedicalDB`.`dossiers_medicaux` TO `r_infirmier`;
GRANT INSERT ON `MedicalDB`.`patient_access_logs` TO `r_infirmier`;

-- Tech labo: CRUD analyses, lecture patients
GRANT SELECT ON `MedicalDB`.`patients` TO `r_tech_labo`;
GRANT SELECT, INSERT, UPDATE ON `MedicalDB`.`analyses_labo` TO `r_tech_labo`;
GRANT INSERT ON `MedicalDB`.`patient_access_logs` TO `r_tech_labo`;

-- App service: droits restreints pour services backend
GRANT SELECT ON `MedicalDB`.`patients` TO `r_app_service`;
GRANT SELECT ON `MedicalDB`.`personnels` TO `r_app_service`;
GRANT SELECT ON `MedicalDB`.`etablissements` TO `r_app_service`;
GRANT INSERT ON `MedicalDB`.`audit_logs` TO `r_app_service`;

-- Admin data: tout sur le schéma (hors admin serveur)
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE, CREATE, ALTER, INDEX, DROP
  ON `MedicalDB`.* TO `r_admin_data`;
