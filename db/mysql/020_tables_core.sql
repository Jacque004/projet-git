-- Tables cœur du SI médical
-- Hypothèses: MySQL 8.0+, InnoDB, utf8mb4

USE `MedicalDB`;

SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- 1) Établissements (hôpitaux, cliniques, labos)
CREATE TABLE IF NOT EXISTS `etablissements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(32) NOT NULL,
  `nom` VARCHAR(255) NOT NULL,
  `type` ENUM('CHU','CLINIQUE','LABO','AUTRE') NOT NULL DEFAULT 'AUTRE',
  `adresse_l1` VARCHAR(255) NULL,
  `adresse_l2` VARCHAR(255) NULL,
  `code_postal` VARCHAR(16) NULL,
  `ville` VARCHAR(128) NULL,
  `region` VARCHAR(128) NULL,
  `pays` CHAR(2) NOT NULL DEFAULT 'FR',
  `telephone` VARCHAR(32) NULL,
  `email` VARCHAR(255) NULL,
  `actif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_etab_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2) Personnels
CREATE TABLE IF NOT EXISTS `personnels` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `etablissement_id` BIGINT UNSIGNED NOT NULL,
  `role_metier` ENUM('MEDECIN','INFIRMIER','SECRETAIRE','TECH_LABO','ADMIN_METIER') NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `nom_affiche` VARCHAR(255) NOT NULL,
  `telephone` VARCHAR(32) NULL,
  `actif` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_personnels_email_etab` (`email`, `etablissement_id`),
  KEY `idx_personnels_etablissement_id` (`etablissement_id`),
  CONSTRAINT `fk_personnels_etablissement` FOREIGN KEY (`etablissement_id`) REFERENCES `etablissements`(`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3) Patients
CREATE TABLE IF NOT EXISTS `patients` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `etablissement_id` BIGINT UNSIGNED NOT NULL,
  `ipp` VARCHAR(64) NULL,
  `prenom` VARCHAR(128) NOT NULL,
  `nom` VARCHAR(128) NOT NULL,
  `date_naissance` DATE NULL,
  `sexe` ENUM('F','M','X','U') NULL DEFAULT 'U',
  `adresse_l1` VARCHAR(255) NULL,
  `adresse_l2` VARCHAR(255) NULL,
  `code_postal` VARCHAR(16) NULL,
  `ville` VARCHAR(128) NULL,
  `telephone` VARCHAR(32) NULL,
  `email` VARCHAR(255) NULL,
  `consentement_donne` TINYINT(1) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_patients_ipp_etab` (`ipp`, `etablissement_id`),
  KEY `idx_patients_etablissement_id` (`etablissement_id`),
  KEY `idx_patients_nom` (`nom`, `prenom`),
  CONSTRAINT `fk_patients_etablissement` FOREIGN KEY (`etablissement_id`) REFERENCES `etablissements`(`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4) Rendez-vous
CREATE TABLE IF NOT EXISTS `rendez_vous` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `etablissement_id` BIGINT UNSIGNED NOT NULL,
  `patient_id` BIGINT UNSIGNED NOT NULL,
  `personnel_id` BIGINT UNSIGNED NULL,
  `date_heure` DATETIME NOT NULL,
  `statut` ENUM('PLANIFIE','CONFIRME','HONORE','ANNULE','ABSENT','REPORTE') NOT NULL DEFAULT 'PLANIFIE',
  `motif` VARCHAR(255) NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rdv_patient_id` (`patient_id`),
  KEY `idx_rdv_etablissement_id` (`etablissement_id`),
  KEY `idx_rdv_personnel_id` (`personnel_id`),
  CONSTRAINT `fk_rdv_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rdv_personnel` FOREIGN KEY (`personnel_id`) REFERENCES `personnels`(`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_rdv_etablissement` FOREIGN KEY (`etablissement_id`) REFERENCES `etablissements`(`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 5) Rencontres (séjours/consultations)
CREATE TABLE IF NOT EXISTS `rencontres` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `etablissement_id` BIGINT UNSIGNED NOT NULL,
  `patient_id` BIGINT UNSIGNED NOT NULL,
  `personnel_id` BIGINT UNSIGNED NULL,
  `type` ENUM('CONSULTATION','HOSPITALISATION','URGENCE','TELECONSULTATION','AUTRE') NOT NULL DEFAULT 'CONSULTATION',
  `debut` DATETIME NOT NULL,
  `fin` DATETIME NULL,
  `diagnostic_principal` VARCHAR(64) NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rencontres_patient_id` (`patient_id`),
  KEY `idx_rencontres_etablissement_id` (`etablissement_id`),
  KEY `idx_rencontres_personnel_id` (`personnel_id`),
  CONSTRAINT `fk_rencontres_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_rencontres_personnel` FOREIGN KEY (`personnel_id`) REFERENCES `personnels`(`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_rencontres_etablissement` FOREIGN KEY (`etablissement_id`) REFERENCES `etablissements`(`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 6) Dossiers médicaux (notes/CR)
CREATE TABLE IF NOT EXISTS `dossiers_medicaux` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` BIGINT UNSIGNED NOT NULL,
  `rencontre_id` BIGINT UNSIGNED NULL,
  `titre` VARCHAR(255) NOT NULL,
  `contenu` MEDIUMTEXT NULL,
  `created_by` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dm_patient_id` (`patient_id`),
  KEY `idx_dm_rencontre_id` (`rencontre_id`),
  KEY `idx_dm_created_by` (`created_by`),
  CONSTRAINT `fk_dm_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_dm_rencontre` FOREIGN KEY (`rencontre_id`) REFERENCES `rencontres`(`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_dm_created_by` FOREIGN KEY (`created_by`) REFERENCES `personnels`(`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 7) Analyses de laboratoire
CREATE TABLE IF NOT EXISTS `analyses_labo` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `etablissement_id` BIGINT UNSIGNED NULL,
  `patient_id` BIGINT UNSIGNED NOT NULL,
  `rencontre_id` BIGINT UNSIGNED NULL,
  `test_code` VARCHAR(64) NULL,
  `test_nom` VARCHAR(255) NOT NULL,
  `resultat_valeur` VARCHAR(255) NULL,
  `resultat_num` DECIMAL(18,6) NULL,
  `unite` VARCHAR(32) NULL,
  `ref_min` DECIMAL(18,6) NULL,
  `ref_max` DECIMAL(18,6) NULL,
  `statut` ENUM('EN_ATTENTE','EN_COURS','TERMINE','ANORMAL','CRITIQUE','ANNULE') NOT NULL DEFAULT 'EN_ATTENTE',
  `resultat_at` DATETIME NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_labo_patient_id` (`patient_id`),
  KEY `idx_labo_rencontre_id` (`rencontre_id`),
  KEY `idx_labo_etablissement_id` (`etablissement_id`),
  KEY `idx_labo_test` (`test_code`,`test_nom`),
  CONSTRAINT `fk_labo_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_labo_rencontre` FOREIGN KEY (`rencontre_id`) REFERENCES `rencontres`(`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_labo_etablissement` FOREIGN KEY (`etablissement_id`) REFERENCES `etablissements`(`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
