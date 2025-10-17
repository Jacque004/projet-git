-- Tables d'audit et journalisation d'accès

USE `MedicalDB`;

-- 1) Journal des accès/logs applicatifs (central minimal)
CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actor_type` ENUM('USER','SERVICE','SYSTEM') NOT NULL,
  `actor_id` VARCHAR(128) NULL,
  `source_ip` VARCHAR(45) NULL,
  `action` VARCHAR(128) NOT NULL,
  `object_type` VARCHAR(64) NULL,
  `object_id` VARCHAR(128) NULL,
  `status` ENUM('SUCCESS','DENY','ERROR') NOT NULL DEFAULT 'SUCCESS',
  `details` JSON NULL,
  PRIMARY KEY (`id`),
  KEY `idx_audit_event_time` (`event_time`),
  KEY `idx_audit_actor` (`actor_type`, `actor_id`),
  KEY `idx_audit_object` (`object_type`, `object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2) Journal d'accès aux données patients (lecture/écriture)
CREATE TABLE IF NOT EXISTS `patient_access_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `patient_id` BIGINT UNSIGNED NOT NULL,
  `access_type` ENUM('READ','WRITE','DELETE') NOT NULL,
  `performed_by_personnel_id` BIGINT UNSIGNED NULL,
  `source_ip` VARCHAR(45) NULL,
  `app_name` VARCHAR(128) NULL,
  `purpose` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pal_time` (`event_time`),
  KEY `idx_pal_patient` (`patient_id`),
  KEY `idx_pal_personnel` (`performed_by_personnel_id`),
  CONSTRAINT `fk_pal_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pal_personnel` FOREIGN KEY (`performed_by_personnel_id`) REFERENCES `personnels`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
