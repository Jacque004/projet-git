-- Utilisateurs applicatifs et attribution des rôles
-- Remplacez les mots de passe avant exécution en production

USE `MedicalDB`;

-- Idempotence: supprimer utilisateurs si besoin (optionnel, à manier avec prudence)
-- DROP USER IF EXISTS 'app_reader'@'%';
-- DROP USER IF EXISTS 'app_analyst'@'%';
-- DROP USER IF EXISTS 'medecin_app'@'%';
-- DROP USER IF EXISTS 'infirmier_app'@'%';
-- DROP USER IF EXISTS 'secretaire_app'@'%';
-- DROP USER IF EXISTS 'tech_labo_app'@'%';
-- DROP USER IF EXISTS 'admin_data'@'%';

CREATE USER IF NOT EXISTS 'app_reader'@'%' IDENTIFIED BY 'ChangeMe_reader_!2025';
CREATE USER IF NOT EXISTS 'app_analyst'@'%' IDENTIFIED BY 'ChangeMe_analyst_!2025';
CREATE USER IF NOT EXISTS 'medecin_app'@'%' IDENTIFIED BY 'ChangeMe_medecin_!2025';
CREATE USER IF NOT EXISTS 'infirmier_app'@'%' IDENTIFIED BY 'ChangeMe_infirmier_!2025';
CREATE USER IF NOT EXISTS 'secretaire_app'@'%' IDENTIFIED BY 'ChangeMe_secretaire_!2025';
CREATE USER IF NOT EXISTS 'tech_labo_app'@'%' IDENTIFIED BY 'ChangeMe_techlabo_!2025';
CREATE USER IF NOT EXISTS 'admin_data'@'%' IDENTIFIED BY 'ChangeMe_admin_!2025';

GRANT `r_readonly` TO 'app_reader'@'%';
GRANT `r_analyst` TO 'app_analyst'@'%';
GRANT `r_medecin` TO 'medecin_app'@'%';
GRANT `r_infirmier` TO 'infirmier_app'@'%';
GRANT `r_secretaire` TO 'secretaire_app'@'%';
GRANT `r_tech_labo` TO 'tech_labo_app'@'%';
GRANT `r_admin_data` TO 'admin_data'@'%';

-- Définir rôle par défaut pour faciliter les connexions
SET DEFAULT ROLE `r_readonly` FOR 'app_reader'@'%';
SET DEFAULT ROLE `r_analyst` FOR 'app_analyst'@'%';
SET DEFAULT ROLE `r_medecin` FOR 'medecin_app'@'%';
SET DEFAULT ROLE `r_infirmier` FOR 'infirmier_app'@'%';
SET DEFAULT ROLE `r_secretaire` FOR 'secretaire_app'@'%';
SET DEFAULT ROLE `r_tech_labo` FOR 'tech_labo_app'@'%';
SET DEFAULT ROLE `r_admin_data` FOR 'admin_data'@'%';
