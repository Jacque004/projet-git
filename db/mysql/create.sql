-- Création de la base de données MedicalDB
-- Encodage: utf8mb4, Collation: utf8mb4_0900_ai_ci (MySQL 8 par défaut)

-- Sécurise la création pour éviter les erreurs si elle existe déjà
CREATE DATABASE IF NOT EXISTS `MedicalDB`
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_0900_ai_ci;

-- Optionnel: définir le mode SQL et le timezone de session (à utiliser lors des imports)
-- SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
-- SET time_zone = '+00:00';
