-- Triggers d'audit simples sur tables sensibles

USE `MedicalDB`;

DELIMITER $$

-- Exemple: journaliser accès en écriture sur dossiers_medicaux
CREATE TRIGGER `trg_dm_insert` AFTER INSERT ON `dossiers_medicaux`
FOR EACH ROW
BEGIN
  INSERT INTO `audit_logs`(`actor_type`, `actor_id`, `action`, `object_type`, `object_id`, `status`, `details`)
  VALUES ('USER', NEW.created_by, 'INSERT', 'dossier_medical', NEW.id, 'SUCCESS', JSON_OBJECT('titre', NEW.titre));
END $$

CREATE TRIGGER `trg_dm_update` AFTER UPDATE ON `dossiers_medicaux`
FOR EACH ROW
BEGIN
  INSERT INTO `audit_logs`(`actor_type`, `actor_id`, `action`, `object_type`, `object_id`, `status`, `details`)
  VALUES ('USER', NEW.created_by, 'UPDATE', 'dossier_medical', NEW.id, 'SUCCESS', JSON_OBJECT('titre', NEW.titre));
END $$

CREATE TRIGGER `trg_dm_delete` AFTER DELETE ON `dossiers_medicaux`
FOR EACH ROW
BEGIN
  INSERT INTO `audit_logs`(`actor_type`, `actor_id`, `action`, `object_type`, `object_id`, `status`, `details`)
  VALUES ('USER', OLD.created_by, 'DELETE', 'dossier_medical', OLD.id, 'SUCCESS', JSON_OBJECT('titre', OLD.titre));
END $$

DELIMITER ;
