-- Vues anonymisées pour usages analytiques / conformité RGPD

USE `MedicalDB`;

-- Masque des identifiants directs et pseudonymisation basique
-- NB: Pour une anonymisation robuste, prévoir une table de mappage salée et rotation des clés

CREATE OR REPLACE VIEW `v_patients_anonymes` AS
SELECT 
  p.id AS patient_id,
  p.etablissement_id,
  SHA2(CONCAT(p.id, ':', p.etablissement_id, ':', 'static_salt_change_me'), 256) AS patient_hash,
  YEAR(CURDATE()) - YEAR(p.date_naissance) - (DATE_FORMAT(CURDATE(),'%m%d') < DATE_FORMAT(p.date_naissance, '%m%d')) AS age,
  p.sexe,
  p.created_at,
  p.updated_at
FROM `patients` p;

CREATE OR REPLACE VIEW `v_rencontres_anon` AS
SELECT 
  r.id AS rencontre_id,
  r.etablissement_id,
  r.patient_id,
  r.type,
  r.debut,
  r.fin,
  r.diagnostic_principal,
  r.created_at,
  r.updated_at
FROM `rencontres` r;

CREATE OR REPLACE VIEW `v_analyses_anon` AS
SELECT 
  a.id AS analyse_id,
  a.etablissement_id,
  a.patient_id,
  a.test_code,
  a.test_nom,
  a.resultat_num,
  a.unite,
  a.ref_min,
  a.ref_max,
  a.statut,
  a.resultat_at
FROM `analyses_labo` a;
