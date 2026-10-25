
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `ar_internal_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `facilities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `facilities` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `source` varchar(255) NOT NULL,
  `source_record_no` varchar(255) NOT NULL,
  `data_as_of` date DEFAULT NULL,
  `office_number` varchar(10) DEFAULT NULL,
  `service_type` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `name_kana` varchar(255) DEFAULT NULL,
  `corporation_name` varchar(255) DEFAULT NULL,
  `prefecture` varchar(255) NOT NULL,
  `municipality` varchar(255) NOT NULL,
  `address_line` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `website_url` varchar(255) DEFAULT NULL,
  `capacity` int DEFAULT NULL,
  `hours_weekday` varchar(255) DEFAULT NULL,
  `hours_saturday` varchar(255) DEFAULT NULL,
  `hours_sunday` varchar(255) DEFAULT NULL,
  `hours_holiday` varchar(255) DEFAULT NULL,
  `open_weekday` tinyint(1) NOT NULL DEFAULT '0',
  `open_saturday` tinyint(1) NOT NULL DEFAULT '0',
  `open_sunday` tinyint(1) NOT NULL DEFAULT '0',
  `open_holiday` tinyint(1) NOT NULL DEFAULT '0',
  `closed_days` text,
  `availability_notes` text,
  `pickup_available` tinyint(1) DEFAULT NULL,
  `description` text,
  `search_text` text,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_facilities_on_source_and_source_record_no` (`source`,`source_record_no`),
  KEY `index_facilities_on_office_number` (`office_number`),
  KEY `index_facilities_on_prefecture_and_municipality` (`prefecture`,`municipality`),
  KEY `index_facilities_on_service_type` (`service_type`),
  FULLTEXT KEY `index_facilities_on_search_text` (`search_text`) /*!50100 WITH PARSER `ngram` */ 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `ip_address` varchar(255) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_758836b4f0` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_batch_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_batch_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `batch_id` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_batch_executions_on_job_id` (`job_id`),
  KEY `index_solid_queue_batch_executions_on_batch_id` (`batch_id`),
  CONSTRAINT `fk_rails_7c5e073422` FOREIGN KEY (`batch_id`) REFERENCES `solid_queue_batches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_bc9f981155` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_batches` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `active_job_batch_id` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `on_finish` text,
  `on_success` text,
  `on_failure` text,
  `metadata` text,
  `total_jobs` int NOT NULL DEFAULT '0',
  `completed_jobs` int NOT NULL DEFAULT '0',
  `failed_jobs` int NOT NULL DEFAULT '0',
  `enqueued_at` datetime(6) DEFAULT NULL,
  `finished_at` datetime(6) DEFAULT NULL,
  `failed_at` datetime(6) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_batches_on_active_job_batch_id` (`active_job_batch_id`),
  KEY `index_solid_queue_batches_on_finished_at` (`finished_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_blocked_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_blocked_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `queue_name` varchar(255) NOT NULL,
  `priority` int NOT NULL DEFAULT '0',
  `concurrency_key` varchar(255) NOT NULL,
  `expires_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_blocked_executions_on_job_id` (`job_id`),
  KEY `index_solid_queue_blocked_executions_for_release` (`concurrency_key`,`priority`,`job_id`),
  KEY `index_solid_queue_blocked_executions_for_maintenance` (`expires_at`,`concurrency_key`),
  CONSTRAINT `fk_rails_4cd34e2228` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_claimed_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_claimed_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `process_id` bigint DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_claimed_executions_on_job_id` (`job_id`),
  KEY `index_solid_queue_claimed_executions_on_process_id_and_job_id` (`process_id`,`job_id`),
  CONSTRAINT `fk_rails_9cfe4d4944` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_failed_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_failed_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `error` text,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_failed_executions_on_job_id` (`job_id`),
  CONSTRAINT `fk_rails_39bbc7a631` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_jobs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `queue_name` varchar(255) NOT NULL,
  `class_name` varchar(255) NOT NULL,
  `arguments` text,
  `priority` int NOT NULL DEFAULT '0',
  `active_job_id` varchar(255) DEFAULT NULL,
  `scheduled_at` datetime(6) DEFAULT NULL,
  `finished_at` datetime(6) DEFAULT NULL,
  `concurrency_key` varchar(255) DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `batch_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_solid_queue_jobs_on_active_job_id` (`active_job_id`),
  KEY `index_solid_queue_jobs_on_batch_id` (`batch_id`),
  KEY `index_solid_queue_jobs_on_class_name` (`class_name`),
  KEY `index_solid_queue_jobs_on_finished_at` (`finished_at`),
  KEY `index_solid_queue_jobs_for_filtering` (`queue_name`,`finished_at`),
  KEY `index_solid_queue_jobs_for_alerting` (`scheduled_at`,`finished_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_pauses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_pauses` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `queue_name` varchar(255) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_pauses_on_queue_name` (`queue_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_processes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_processes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `kind` varchar(255) NOT NULL,
  `last_heartbeat_at` datetime(6) NOT NULL,
  `supervisor_id` bigint DEFAULT NULL,
  `pid` int NOT NULL,
  `hostname` varchar(255) DEFAULT NULL,
  `metadata` text,
  `created_at` datetime(6) NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_processes_on_name_and_supervisor_id` (`name`,`supervisor_id`),
  KEY `index_solid_queue_processes_on_last_heartbeat_at` (`last_heartbeat_at`),
  KEY `index_solid_queue_processes_on_supervisor_id` (`supervisor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_ready_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_ready_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `queue_name` varchar(255) NOT NULL,
  `priority` int NOT NULL DEFAULT '0',
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_ready_executions_on_job_id` (`job_id`),
  KEY `index_solid_queue_poll_all` (`priority`,`job_id`),
  KEY `index_solid_queue_poll_by_queue` (`queue_name`,`priority`,`job_id`),
  CONSTRAINT `fk_rails_81fcbd66af` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_recurring_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_recurring_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `task_key` varchar(255) NOT NULL,
  `run_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_recurring_executions_on_job_id` (`job_id`),
  UNIQUE KEY `index_solid_queue_recurring_executions_on_task_key_and_run_at` (`task_key`,`run_at`),
  CONSTRAINT `fk_rails_318a5533ed` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_recurring_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_recurring_tasks` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) NOT NULL,
  `schedule` varchar(255) NOT NULL,
  `command` varchar(2048) DEFAULT NULL,
  `class_name` varchar(255) DEFAULT NULL,
  `arguments` text,
  `queue_name` varchar(255) DEFAULT NULL,
  `priority` int DEFAULT '0',
  `static` tinyint(1) NOT NULL DEFAULT '1',
  `description` text,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_recurring_tasks_on_key` (`key`),
  KEY `index_solid_queue_recurring_tasks_on_static` (`static`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_scheduled_executions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_scheduled_executions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` bigint NOT NULL,
  `queue_name` varchar(255) NOT NULL,
  `priority` int NOT NULL DEFAULT '0',
  `scheduled_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_scheduled_executions_on_job_id` (`job_id`),
  KEY `index_solid_queue_dispatch_all` (`scheduled_at`,`priority`,`job_id`),
  CONSTRAINT `fk_rails_c4316f352d` FOREIGN KEY (`job_id`) REFERENCES `solid_queue_jobs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `solid_queue_semaphores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solid_queue_semaphores` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `key` varchar(255) NOT NULL,
  `value` int NOT NULL DEFAULT '1',
  `expires_at` datetime(6) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_solid_queue_semaphores_on_key` (`key`),
  KEY `index_solid_queue_semaphores_on_expires_at` (`expires_at`),
  KEY `index_solid_queue_semaphores_on_key_and_value` (`key`,`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `email_address` varchar(255) NOT NULL,
  `password_digest` varchar(255) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_email_address` (`email_address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
--
-- WARNING: can't read the INFORMATION_SCHEMA.libraries table. It's most probably an old server 8.0.46.
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

INSERT INTO `schema_migrations` (version) VALUES
('20261025051000'),
('20261025050000'),
('20261025043507'),
('20261025043506');

