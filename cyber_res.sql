CREATE DATABASE  IF NOT EXISTS `cyber_res` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `cyber_res`;
-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: cyber_res
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `alerts`
--

DROP TABLE IF EXISTS `alerts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alerts` (
  `alert_id` int NOT NULL AUTO_INCREMENT,
  `incident_id` int NOT NULL,
  `alert_type` varchar(50) DEFAULT NULL,
  `priority` enum('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'MEDIUM',
  `message` text,
  `triggered_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `acknowledged` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`alert_id`),
  KEY `incident_id` (`incident_id`),
  CONSTRAINT `alerts_ibfk_1` FOREIGN KEY (`incident_id`) REFERENCES `incidents` (`incident_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alerts`
--

LOCK TABLES `alerts` WRITE;
/*!40000 ALTER TABLE `alerts` DISABLE KEYS */;
INSERT INTO `alerts` VALUES (1,1,'MALWARE_DETECTED','CRITICAL','Ransomware binary executed on DC-01 — isolate immediately','2024-11-10 02:14:05',0),(2,1,'C2_TRAFFIC','CRITICAL','C2 beacon detected to 185.220.101.5 — block at firewall','2024-11-10 02:16:10',0),(3,2,'BRUTE_FORCE','HIGH','500+ failed logins from 192.168.99.45 in under 10 minutes','2024-11-10 08:30:05',0),(4,3,'SQLI_ATTEMPT','HIGH','SQL injection payloads detected on /api/auth endpoint','2024-11-09 15:22:05',0),(5,4,'DATA_EXFIL','MEDIUM','Abnormal outbound transfer volume — possible data theft','2024-11-08 11:00:10',0),(6,5,'AUTO_GENERATED','HIGH','New HIGH incident logged: ransomware detected on server 01','2026-04-11 16:51:16',0),(7,6,'AUTO_GENERATED','CRITICAL','New CRITICAL incident logged: ransomware','2026-04-11 16:52:45',0),(10,9,'AUTO_GENERATED','HIGH','New HIGH incident logged: ransomware ','2026-04-13 15:07:55',0);
/*!40000 ALTER TABLE `alerts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `events` (
  `event_id` int NOT NULL AUTO_INCREMENT,
  `incident_id` int NOT NULL,
  `event_type` varchar(50) DEFAULT NULL,
  `source_ip` varchar(45) DEFAULT NULL,
  `destination_ip` varchar(45) DEFAULT NULL,
  `payload` text,
  `timestamp` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`event_id`),
  KEY `incident_id` (`incident_id`),
  CONSTRAINT `events_ibfk_1` FOREIGN KEY (`incident_id`) REFERENCES `incidents` (`incident_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events`
--

LOCK TABLES `events` WRITE;
/*!40000 ALTER TABLE `events` DISABLE KEYS */;
INSERT INTO `events` VALUES (1,1,'MALWARE_EXEC','10.0.0.5','10.0.0.1','ransom.exe execution detected','2024-11-10 02:14:00'),(2,1,'FILE_ENCRYPT','10.0.0.1',NULL,'Mass file rename to .locked extension','2024-11-10 02:15:30'),(3,1,'C2_CONNECT','10.0.0.1','185.220.101.5','Outbound connection to known C2 server','2024-11-10 02:16:00'),(4,2,'LOGIN_FAILURE','192.168.99.45','10.0.0.20','Invalid credentials: root','2024-11-10 08:30:00'),(5,2,'LOGIN_FAILURE','192.168.99.45','10.0.0.20','Invalid credentials: admin','2024-11-10 08:30:15'),(6,2,'PORT_SCAN','192.168.99.45','10.0.0.0/24','SYN scan on ports 22,80,443,3306','2024-11-10 08:28:00'),(7,3,'SQL_INJECTION','203.0.113.42','10.0.0.10','\' OR 1=1 -- in username field','2024-11-09 15:22:00'),(8,3,'SQL_INJECTION','203.0.113.42','10.0.0.10','UNION SELECT attack on orders table','2024-11-09 15:23:10'),(9,4,'DATA_EXFIL','10.0.0.8','91.108.4.100','2.3GB transfer to unknown IP','2024-11-08 11:00:00'),(10,5,'MALWARE_EXEC','192.165.23','10.0.0.2','30 failed logins in 10 min','2026-04-11 16:51:16'),(11,6,'MALWARE_EXEC','192.165.23','10.0.0.2','30 failed logins in 10 min','2026-04-11 16:52:45');
/*!40000 ALTER TABLE `events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `incidents`
--

DROP TABLE IF EXISTS `incidents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `incidents` (
  `incident_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `description` text,
  `severity` enum('LOW','MEDIUM','HIGH','CRITICAL') NOT NULL,
  `status` enum('OPEN','IN_PROGRESS','RESOLVED','CLOSED') DEFAULT 'OPEN',
  `detected_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `resolved_at` datetime DEFAULT NULL,
  PRIMARY KEY (`incident_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `incidents`
--

LOCK TABLES `incidents` WRITE;
/*!40000 ALTER TABLE `incidents` DISABLE KEYS */;
INSERT INTO `incidents` VALUES (1,'Ransomware on DC-01','Ransomware binary detected on primary domain controller. Files being encrypted.','CRITICAL','IN_PROGRESS','2024-11-10 02:14:00',NULL),(2,'Brute force SSH on web-02','Over 500 failed SSH login attempts from IP 192.168.99.45 in 10 minutes.','HIGH','OPEN','2024-11-10 08:30:00',NULL),(3,'SQL injection on API gateway','Malicious payloads detected in query params targeting user auth endpoint.','HIGH','OPEN','2024-11-09 15:22:00',NULL),(4,'Unusual outbound traffic','Large data exfiltration attempt to unknown external IP detected.','MEDIUM','RESOLVED','2024-11-08 11:00:00',NULL),(5,'ransomware detected on server 01','folders not openning','HIGH','OPEN','2026-04-11 16:51:16',NULL),(6,'ransomware','folders not opening','CRITICAL','IN_PROGRESS','2026-04-11 16:52:45',NULL),(9,'ransomware ','','HIGH','OPEN','2026-04-13 15:07:55',NULL);
/*!40000 ALTER TABLE `incidents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mitigation_actions`
--

DROP TABLE IF EXISTS `mitigation_actions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mitigation_actions` (
  `action_id` int NOT NULL,
  `incident_id` int NOT NULL,
  `action_type` varchar(100) DEFAULT NULL,
  `description` text,
  `assigned_to` varchar(100) DEFAULT NULL,
  `priority` enum('LOW','MEDIUM','HIGH','CRITICAL') DEFAULT 'MEDIUM',
  `status` enum('PENDING','IN_PROGRESS','DONE') DEFAULT 'PENDING',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`action_id`,`incident_id`),
  KEY `incident_id` (`incident_id`),
  CONSTRAINT `mitigation_actions_ibfk_1` FOREIGN KEY (`incident_id`) REFERENCES `incidents` (`incident_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mitigation_actions`
--

LOCK TABLES `mitigation_actions` WRITE;
/*!40000 ALTER TABLE `mitigation_actions` DISABLE KEYS */;
INSERT INTO `mitigation_actions` VALUES (1,1,'ISOLATE_HOST','Immediately isolate DC-01 from network','Pranav','CRITICAL','IN_PROGRESS','2026-04-11 15:06:52',NULL),(1,2,'BLOCK_IP','Block 192.168.99.45 at firewall','Divasha','HIGH','DONE','2026-04-11 15:06:52',NULL),(1,3,'PATCH_SYSTEM','Apply input sanitization patch to API','Divasha','HIGH','IN_PROGRESS','2026-04-11 15:06:52',NULL),(1,4,'INVESTIGATE','Identify what data was exfiltrated','Pranav','MEDIUM','DONE','2026-04-11 15:06:52',NULL),(2,1,'BLOCK_IP','Block 185.220.101.5 on perimeter firewall','Divasha','CRITICAL','DONE','2026-04-11 15:06:52',NULL),(2,2,'CHANGE_CREDS','Force SSH key rotation on web-02','Pranav','HIGH','PENDING','2026-04-11 15:06:52',NULL),(3,1,'PATCH_SYSTEM','Apply CVE-2024-1234 patch after recovery','Pranav','HIGH','PENDING','2026-04-11 15:06:52',NULL);
/*!40000 ALTER TABLE `mitigation_actions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `threats`
--

DROP TABLE IF EXISTS `threats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `threats` (
  `threat_id` int NOT NULL AUTO_INCREMENT,
  `incident_id` int NOT NULL,
  `vuln_id` int DEFAULT NULL,
  `threat_actor` varchar(100) DEFAULT NULL,
  `attack_type` varchar(50) DEFAULT NULL,
  `attack_vector` varchar(50) DEFAULT NULL,
  `risk_score` int DEFAULT NULL,
  PRIMARY KEY (`threat_id`),
  KEY `incident_id` (`incident_id`),
  KEY `vuln_id` (`vuln_id`),
  CONSTRAINT `threats_ibfk_1` FOREIGN KEY (`incident_id`) REFERENCES `incidents` (`incident_id`) ON DELETE CASCADE,
  CONSTRAINT `threats_ibfk_2` FOREIGN KEY (`vuln_id`) REFERENCES `vulnerabilities` (`vuln_id`) ON DELETE SET NULL,
  CONSTRAINT `threats_chk_1` CHECK ((`risk_score` between 1 and 10))
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `threats`
--

LOCK TABLES `threats` WRITE;
/*!40000 ALTER TABLE `threats` DISABLE KEYS */;
INSERT INTO `threats` VALUES (1,1,1,'Unknown APT','RANSOMWARE','NETWORK',10),(2,2,3,'Script Kiddie','BRUTE_FORCE','NETWORK',7),(3,3,4,'Unknown','SQL_INJECTION','WEB',8),(4,4,NULL,'Insider Threat','DATA_EXFILTRATION','INTERNAL',6);
/*!40000 ALTER TABLE `threats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vulnerabilities`
--

DROP TABLE IF EXISTS `vulnerabilities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vulnerabilities` (
  `vuln_id` int NOT NULL AUTO_INCREMENT,
  `cve_id` varchar(20) DEFAULT NULL,
  `cvss_score` decimal(3,1) DEFAULT NULL,
  `affected_system` varchar(100) DEFAULT NULL,
  `description` text,
  `patch_status` enum('UNPATCHED','PATCHED','MITIGATED') DEFAULT 'UNPATCHED',
  PRIMARY KEY (`vuln_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vulnerabilities`
--

LOCK TABLES `vulnerabilities` WRITE;
/*!40000 ALTER TABLE `vulnerabilities` DISABLE KEYS */;
INSERT INTO `vulnerabilities` VALUES (1,'CVE-2024-1234',9.8,'Apache HTTP Server','Remote code execution via malformed request','UNPATCHED'),(2,'CVE-2023-4567',7.5,'OpenSSL 3.0','Buffer overflow in certificate parsing','PATCHED'),(3,'CVE-2024-8910',8.1,'Windows SMB','Privilege escalation via SMB relay attack','UNPATCHED'),(4,'CVE-2023-1122',6.5,'MySQL 8.0','SQL injection in authentication module','MITIGATED');
/*!40000 ALTER TABLE `vulnerabilities` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-19 14:50:38
