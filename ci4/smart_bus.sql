-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 30, 2026 at 08:48 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `smart_bus`
--

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `admin_id` int(10) UNSIGNED NOT NULL,
  `full_name` varchar(120) NOT NULL,
  `employee_id` varchar(50) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`admin_id`, `full_name`, `employee_id`, `email`, `password`, `created_at`, `updated_at`) VALUES
(1, 'System Admin', 'ADM001', 'admin@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '2026-05-11 09:48:23', '2026-06-11 20:33:08');

-- --------------------------------------------------------

--
-- Table structure for table `buses`
--

CREATE TABLE `buses` (
  `bus_id` int(10) UNSIGNED NOT NULL,
  `plate_number` varchar(30) NOT NULL,
  `mac_address` varchar(20) NOT NULL,
  `status` enum('available','in_service','maintenance') NOT NULL DEFAULT 'available',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `buses`
--

INSERT INTO `buses` (`bus_id`, `plate_number`, `mac_address`, `status`, `created_at`) VALUES
(1, 'NED6755', '00:13:10:85:FE:01', 'available', '2026-05-12 09:48:23'),
(2, 'BQH8212', 'AA:BB:CC:DD:EE:02', 'available', '2026-05-11 09:48:23'),
(4, 'BSF6527', 'AA:BB:CC:DD:EE:03', 'available', '2026-06-11 20:50:00'),
(5, 'BSF7391', 'AA:BB:CC:DD:EE:04', 'available', '2026-07-01 02:27:20'),
(6, 'BSF6524', 'AA:BB:CC:DD:EE:05', 'available', '2026-07-01 02:27:56'),
(7, 'BSF7393', 'AA:BB:CC:DD:EE:06', 'available', '2026-07-01 02:28:40'),
(8, 'CEH4266', 'AA:BB:CC:DD:EE:07', 'available', '2026-07-01 02:28:58'),
(9, 'CEH4267', 'AA:BB:CC:DD:EE:08', 'available', '2026-07-01 02:45:46'),
(10, 'CEH4268', 'AA:BB:CC:DD:EE:09', 'in_service', '2026-07-01 02:45:46'),
(11, 'BSF7395', 'AA:BB:CC:DD:EE:0A', 'available', '2026-07-01 02:45:46'),
(12, 'BSF7396', 'AA:BB:CC:DD:EE:0B', 'maintenance', '2026-07-01 02:45:46'),
(13, 'NED6756', 'AA:BB:CC:DD:EE:0C', 'available', '2026-07-01 02:45:46');

-- --------------------------------------------------------

--
-- Table structure for table `cancel_requests`
--

CREATE TABLE `cancel_requests` (
  `cancel_id` int(10) UNSIGNED NOT NULL,
  `schedule_id` int(10) UNSIGNED NOT NULL,
  `driver_id` int(10) UNSIGNED NOT NULL,
  `supervisor_id` int(10) UNSIGNED DEFAULT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `created_at` datetime DEFAULT current_timestamp(),
  `reviewed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cancel_requests`
--

INSERT INTO `cancel_requests` (`cancel_id`, `schedule_id`, `driver_id`, `supervisor_id`, `reason`, `status`, `created_at`, `reviewed_at`) VALUES
(5, 18, 1, 1, 'sick', 'Approved', '2026-06-03 02:46:57', '2026-06-02 18:47:13'),
(6, 17, 1, 1, NULL, 'Approved', '2026-06-03 03:33:48', '2026-06-02 19:34:49'),
(7, 21, 1, 1, 'sick again', 'Approved', '2026-06-03 03:51:24', '2026-06-02 19:52:18'),
(8, 20, 1, 1, 'injury during work', 'Approved', '2026-06-03 03:51:44', '2026-06-02 19:52:20'),
(9, 35, 6, 1, 'Doktor temujanji', 'Pending', '2026-07-01 03:15:00', NULL),
(10, 37, 7, 2, 'Family emergency — kena attend kenduri', 'Approved', '2026-07-01 02:00:00', '2026-07-01 04:20:00'),
(11, 30, 4, 1, 'Bus AC malfunction reported pre-trip', 'Rejected', '2026-06-29 12:00:00', '2026-06-29 13:15:00'),
(12, 38, 8, NULL, 'Sakit demam panas', 'Pending', '2026-07-01 06:30:00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `drivers`
--

CREATE TABLE `drivers` (
  `driver_id` int(10) UNSIGNED NOT NULL,
  `full_name` varchar(120) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `drivers`
--

INSERT INTO `drivers` (`driver_id`, `full_name`, `email`, `password`, `phone`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Mohammed Nazir Bin Amirdat Khan', 'nazir@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '+60-12-3456789', 'active', '2026-05-11 09:48:23', '2026-06-11 20:30:42'),
(2, 'Hairil Azli Bin Ali', 'azli@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '+60-13-7654321', 'active', '2026-05-11 09:48:23', '2026-06-11 20:33:42'),
(3, 'Roslan Bin Mohd Saad', 'roslan@maraliner.com', '$2y$10$VxDkiSXsMvWIRY0bWLBv3OCvNTUjH726YdEfdkJbG8tjq7RGh9WHa', '+60 12-345 6789', 'active', '2026-06-11 20:47:19', '2026-06-11 20:47:19'),
(4, 'Azhar Bin Mohamad Sharif', 'azhar@maraliner.com', '$2y$10$az5.30.mu8Fns5HwXaa6kewaglyi4ScNXbUmEcLn4cCFUzNT/.pny', '+60 12-901 2345', 'active', '2026-06-11 20:48:26', '2026-06-11 20:48:26'),
(5, 'Syed Ahmad Fahmi Bin Syed Abu Bakar', 'fahmi@maraliner.com', '$2y$10$.v32DtvhmTBQARuzgcCnD.bF8zjxKxrHyy5hXLgHi1WiQoA35lCjC', '+60 12-161 8033', 'active', '2026-06-11 20:49:27', '2026-06-11 20:49:27'),
(6, 'Zulkarnain Bin Abdullah', 'zulkarnain@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '+60 19-234 5678', 'active', '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(7, 'Mohd Faizal Bin Ramli', 'faizal@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '+60 17-345 6789', 'active', '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(8, 'Khairul Anwar Bin Othman', 'khairul@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '+60 11-456 7890', 'active', '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(9, 'Rosli Bin Yahaya', 'rosli@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '+60 13-567 8901', 'active', '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(10, 'Shamsul Bahri Bin Idris', 'shamsul@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '+60 16-678 9012', 'inactive', '2026-07-01 02:45:46', '2026-07-01 02:45:46');

-- --------------------------------------------------------

--
-- Table structure for table `leave_applications`
--

CREATE TABLE `leave_applications` (
  `leave_id` int(10) UNSIGNED NOT NULL,
  `driver_id` int(10) UNSIGNED NOT NULL,
  `supervisor_id` int(10) UNSIGNED DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `created_at` datetime DEFAULT current_timestamp(),
  `reviewed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `leave_applications`
--

INSERT INTO `leave_applications` (`leave_id`, `driver_id`, `supervisor_id`, `start_date`, `end_date`, `reason`, `status`, `created_at`, `reviewed_at`) VALUES
(1, 1, 1, '2026-06-02', '2026-06-04', 'medical', 'Approved', '2026-06-03 03:47:01', '2026-06-02 19:48:32'),
(2, 1, 1, '2026-06-06', '2026-06-08', 'event', 'Rejected', '2026-06-03 03:48:13', '2026-06-30 16:35:52'),
(5, 1, 1, '2026-06-30', '2026-07-01', 'sick', 'Approved', '2026-07-01 02:33:18', '2026-06-30 18:33:23'),
(6, 2, 1, '2026-07-05', '2026-07-06', 'Hari Raya Haji extended leave', 'Approved', '2026-06-25 10:00:00', '2026-06-26 09:15:00'),
(7, 3, 1, '2026-07-10', '2026-07-12', 'Family medical appointment', 'Pending', '2026-06-30 14:00:00', NULL),
(8, 4, 2, '2026-06-20', '2026-06-22', 'Hospital follow-up', 'Approved', '2026-06-15 08:30:00', '2026-06-16 10:00:00'),
(9, 6, 1, '2026-07-15', '2026-07-15', 'JPJ license renewal', 'Pending', '2026-07-01 01:45:00', NULL),
(10, 7, NULL, '2026-07-20', '2026-07-22', 'Annual leave — anak kahwin', 'Pending', '2026-07-01 02:10:00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `overtime_requests`
--

CREATE TABLE `overtime_requests` (
  `overtime_id` int(10) UNSIGNED NOT NULL,
  `schedule_id` int(10) UNSIGNED NOT NULL,
  `supervisor_id` int(10) UNSIGNED DEFAULT NULL,
  `extra_minutes` int(11) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `created_at` datetime DEFAULT current_timestamp(),
  `reviewed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `overtime_requests`
--

INSERT INTO `overtime_requests` (`overtime_id`, `schedule_id`, `supervisor_id`, `extra_minutes`, `reason`, `status`, `created_at`, `reviewed_at`) VALUES
(6, 18, 1, 938, 'merdeka day', 'Approved', '2026-06-03 03:39:21', '2026-06-02 19:46:15'),
(7, 17, 1, 579, 'solat', 'Approved', '2026-06-03 03:39:30', '2026-06-02 19:46:17'),
(8, 28, 1, 15, 'Heavy traffic near Rawang exit ramp', 'Approved', '2026-06-28 11:20:00', '2026-06-28 14:00:00'),
(9, 30, 1, 42, 'Detour — Jalan Kuala Selangor roadwork', 'Approved', '2026-06-29 17:50:00', '2026-06-30 09:00:00'),
(10, 31, 2, 30, 'Long boarding queue at HAB Pudu evening peak', 'Approved', '2026-06-30 13:10:00', '2026-06-30 14:00:00'),
(11, 32, 1, 5, 'Minor boarding delay at Terminal Bas Rawang', 'Pending', '2026-07-01 08:10:00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `routes`
--

CREATE TABLE `routes` (
  `route_id` int(10) UNSIGNED NOT NULL,
  `route_name` varchar(150) NOT NULL,
  `origin` varchar(150) NOT NULL,
  `destination` varchar(150) NOT NULL,
  `distance_km` decimal(6,2) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `routes`
--

INSERT INTO `routes` (`route_id`, `route_name`, `origin`, `destination`, `distance_km`, `created_at`) VALUES
(6, 'ML 80 Outbound', 'Bukit Beruntung', 'TERMINAL BAS RAWANG', 24.00, '2026-05-24 15:37:31'),
(7, 'ML 80 Inbound', 'Terminal Bas Rawang', 'Bukit Beruntung', 24.00, '2026-05-24 15:38:16'),
(8, 'ML 81 Outbound', 'Terminal Bas Rawang', 'HAB LEBUH PUDU (TP)', 31.00, '2026-05-24 15:38:53'),
(9, 'ML 81 Inbound', 'HAB LEBUH PUDU (TP)', 'TERMINAL BAS RAWANG', 31.00, '2026-05-24 15:39:52'),
(10, 'ML 83 Outbound', 'Bukit Idaman', 'HAB LEBUH PUDU (TP)', 24.00, '2026-05-24 15:41:10'),
(11, 'ML 88 Outbound', 'Terminal Bukit Sentosa', 'HAB LEBUH PUDU (TP)', 51.00, '2026-05-24 15:42:22'),
(12, 'ML 83 Inbound', 'HAB LEBUH PUDU (TP)', 'Bukit Idaman', 24.00, '2026-07-01 02:30:13'),
(13, 'ML 88 Inbound', 'HAB LEBUH PUDU (TP)', 'Terminal Bukit Sentosa', 51.00, '2026-07-01 02:30:36'),
(14, 'ML 82 Outbound', 'Terminal Bas Rawang', 'Selayang Mall', 18.50, '2026-07-01 02:45:46'),
(15, 'ML 82 Inbound', 'Selayang Mall', 'Terminal Bas Rawang', 18.50, '2026-07-01 02:45:46'),
(16, 'ML 84 Outbound', 'Bukit Beruntung', 'HAB LEBUH PUDU (TP)', 42.00, '2026-07-01 02:45:46'),
(17, 'ML 84 Inbound', 'HAB LEBUH PUDU (TP)', 'Bukit Beruntung', 42.00, '2026-07-01 02:45:46'),
(18, 'ML 85 Outbound', 'Bandar Tasik Puteri', 'Terminal Bas Rawang', 12.50, '2026-07-01 02:45:46');

-- --------------------------------------------------------

--
-- Table structure for table `schedules`
--

CREATE TABLE `schedules` (
  `schedule_id` int(10) UNSIGNED NOT NULL,
  `driver_id` int(10) UNSIGNED DEFAULT NULL,
  `supervisor_id` int(10) UNSIGNED NOT NULL,
  `bus_id` int(10) UNSIGNED NOT NULL,
  `route_id` int(10) UNSIGNED NOT NULL,
  `schedule_date` date NOT NULL,
  `expected_start` time NOT NULL,
  `expected_end` time NOT NULL,
  `actual_start` datetime DEFAULT NULL,
  `actual_end` datetime DEFAULT NULL,
  `job_status` enum('Pending','In-Progress','Completed','Cancelled') NOT NULL DEFAULT 'Pending',
  `is_synced` tinyint(1) NOT NULL DEFAULT 1,
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `schedules`
--

INSERT INTO `schedules` (`schedule_id`, `driver_id`, `supervisor_id`, `bus_id`, `route_id`, `schedule_date`, `expected_start`, `expected_end`, `actual_start`, `actual_end`, `job_status`, `is_synced`, `notes`, `created_at`, `updated_at`) VALUES
(16, 1, 1, 1, 6, '2026-06-02', '08:00:00', '10:00:00', '2026-05-24 07:50:07', '2026-05-24 07:50:27', 'Completed', 1, NULL, '2026-05-24 15:43:12', '2026-06-03 02:45:11'),
(17, 1, 1, 1, 7, '2026-06-02', '08:00:00', '10:00:00', '2026-06-02 19:39:03', '2026-06-02 19:39:04', 'Completed', 1, NULL, '2026-05-24 15:54:26', '2026-06-03 03:39:26'),
(18, 1, 1, 1, 9, '2026-06-02', '01:00:00', '04:00:00', '2026-06-02 19:38:50', '2026-06-02 19:38:51', 'Completed', 1, NULL, '2026-06-03 02:46:37', '2026-06-03 03:39:13'),
(19, 1, 1, 1, 10, '2026-06-02', '00:05:00', '11:02:00', '2026-06-02 19:13:34', '2026-06-02 19:13:36', 'Completed', 1, NULL, '2026-06-03 02:55:56', '2026-06-03 03:13:40'),
(20, NULL, 1, 1, 9, '2026-06-02', '21:00:00', '22:00:00', NULL, NULL, 'Pending', 1, NULL, '2026-06-03 02:56:26', '2026-06-03 03:52:20'),
(21, NULL, 1, 1, 11, '2026-06-02', '14:00:00', '22:00:00', NULL, NULL, 'Pending', 1, NULL, '2026-06-03 02:56:58', '2026-06-03 03:52:18'),
(22, 1, 1, 1, 8, '2026-06-02', '23:00:00', '14:00:00', NULL, NULL, 'Pending', 1, NULL, '2026-06-03 02:57:28', '2026-06-03 02:57:28'),
(23, 1, 1, 1, 6, '2026-06-29', '13:00:00', '23:00:00', NULL, NULL, 'Pending', 1, NULL, '2026-06-30 00:10:56', '2026-06-30 00:10:56'),
(24, NULL, 1, 1, 8, '2026-06-30', '08:00:00', '10:00:00', NULL, NULL, 'Pending', 1, NULL, '2026-06-30 23:19:23', '2026-07-01 02:33:23'),
(26, NULL, 1, 1, 10, '2026-06-30', '08:00:00', '10:00:00', NULL, NULL, 'Pending', 1, NULL, '2026-07-01 02:32:23', '2026-07-01 02:33:23'),
(27, 2, 1, 2, 6, '2026-06-28', '06:00:00', '08:00:00', '2026-06-28 06:02:11', '2026-06-28 07:58:34', 'Completed', 1, NULL, '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(28, 2, 1, 2, 7, '2026-06-28', '09:00:00', '11:00:00', '2026-06-28 09:01:22', '2026-06-28 11:15:08', 'Completed', 1, 'Heavy traffic near Rawang exit', '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(29, 3, 1, 4, 8, '2026-06-29', '07:00:00', '09:30:00', '2026-06-29 07:00:45', '2026-06-29 09:33:12', 'Completed', 1, NULL, '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(30, 4, 1, 5, 11, '2026-06-29', '14:00:00', '17:00:00', '2026-06-29 14:05:00', '2026-06-29 17:42:18', 'Completed', 1, 'Detour — Jalan Kuala Selangor roadwork', '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(31, 3, 2, 4, 9, '2026-06-30', '10:00:00', '12:30:00', '2026-06-30 10:00:33', '2026-06-30 13:00:55', 'Completed', 1, 'Boarding delays at HAB Pudu', '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(32, 2, 1, 6, 14, '2026-07-01', '06:30:00', '08:00:00', '2026-07-01 06:32:10', '2026-07-01 08:05:22', 'Completed', 1, NULL, '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(33, 4, 2, 7, 16, '2026-07-01', '07:00:00', '09:30:00', '2026-07-01 07:01:55', NULL, 'In-Progress', 1, NULL, '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(34, 5, 1, 8, 6, '2026-07-01', '13:00:00', '15:00:00', NULL, NULL, 'Pending', 1, NULL, '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(35, 6, 1, 2, 11, '2026-07-01', '15:00:00', '18:00:00', NULL, NULL, 'Pending', 1, NULL, '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(36, NULL, 1, 9, 18, '2026-07-01', '17:00:00', '18:00:00', NULL, NULL, 'Pending', 1, 'Awaiting reassignment — open for volunteer', '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(37, NULL, 2, 11, 17, '2026-07-02', '06:00:00', '08:30:00', NULL, NULL, 'Pending', 1, 'Driver cancelled — needs reassignment', '2026-07-01 02:45:46', '2026-07-01 02:45:46'),
(38, 8, 1, 13, 15, '2026-07-02', '09:00:00', '10:30:00', NULL, NULL, 'Pending', 1, NULL, '2026-07-01 02:45:46', '2026-07-01 02:45:46');

-- --------------------------------------------------------

--
-- Table structure for table `supervisors`
--

CREATE TABLE `supervisors` (
  `supervisor_id` int(10) UNSIGNED NOT NULL,
  `full_name` varchar(120) NOT NULL,
  `employee_id` varchar(50) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `supervisors`
--

INSERT INTO `supervisors` (`supervisor_id`, `full_name`, `employee_id`, `email`, `password`, `created_at`, `updated_at`) VALUES
(1, 'Muhammad Azfar', 'SUP001', 'azfar@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '2026-05-11 09:48:23', '2026-06-11 20:33:23'),
(2, 'Norazlinda Binti Hassan', 'SUP002', 'norazlinda@maraliner.com', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '2026-07-01 02:45:46', '2026-07-01 02:45:46');

-- --------------------------------------------------------

--
-- Table structure for table `volunteer_requests`
--

CREATE TABLE `volunteer_requests` (
  `volunteer_id` int(10) UNSIGNED NOT NULL,
  `schedule_id` int(10) UNSIGNED NOT NULL,
  `driver_id` int(10) UNSIGNED NOT NULL,
  `supervisor_id` int(10) UNSIGNED DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `status` enum('Pending','Approved','Rejected','Auto-Rejected') NOT NULL DEFAULT 'Pending',
  `created_at` datetime DEFAULT current_timestamp(),
  `reviewed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `volunteer_requests`
--

INSERT INTO `volunteer_requests` (`volunteer_id`, `schedule_id`, `driver_id`, `supervisor_id`, `note`, `status`, `created_at`, `reviewed_at`) VALUES
(2, 21, 1, NULL, 'untuk esok', 'Pending', '2026-06-03 03:54:17', NULL),
(3, 20, 1, 1, 'dari 1pm hingga 2pm', 'Rejected', '2026-06-03 04:00:38', '2026-06-11 13:21:00'),
(4, 36, 5, NULL, 'Saya free petang ni, boleh cover trip ML 85', 'Pending', '2026-07-01 04:00:00', NULL),
(5, 36, 9, NULL, 'Available, dekat dengan terminal sekarang', 'Pending', '2026-07-01 04:10:00', NULL),
(6, 35, 9, 1, 'Boleh ambil alih kalau perlu', 'Auto-Rejected', '2026-07-01 03:30:00', '2026-07-01 04:00:00'),
(7, 37, 6, 2, 'Boleh ambil trip esok pagi', 'Pending', '2026-07-01 05:00:00', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`admin_id`),
  ADD UNIQUE KEY `employee_id` (`employee_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `buses`
--
ALTER TABLE `buses`
  ADD PRIMARY KEY (`bus_id`),
  ADD UNIQUE KEY `plate_number` (`plate_number`),
  ADD UNIQUE KEY `mac_address` (`mac_address`),
  ADD KEY `idx_mac` (`mac_address`);

--
-- Indexes for table `cancel_requests`
--
ALTER TABLE `cancel_requests`
  ADD PRIMARY KEY (`cancel_id`),
  ADD KEY `fk_cancel_supervisor` (`supervisor_id`),
  ADD KEY `idx_cr_status` (`status`),
  ADD KEY `idx_cr_driver` (`driver_id`),
  ADD KEY `fk_cancel_schedule` (`schedule_id`);

--
-- Indexes for table `drivers`
--
ALTER TABLE `drivers`
  ADD PRIMARY KEY (`driver_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `leave_applications`
--
ALTER TABLE `leave_applications`
  ADD PRIMARY KEY (`leave_id`),
  ADD KEY `fk_leave_driver` (`driver_id`),
  ADD KEY `fk_leave_supervisor` (`supervisor_id`);

--
-- Indexes for table `overtime_requests`
--
ALTER TABLE `overtime_requests`
  ADD PRIMARY KEY (`overtime_id`),
  ADD KEY `fk_ot_supervisor` (`supervisor_id`),
  ADD KEY `fk_ot_schedule` (`schedule_id`);

--
-- Indexes for table `routes`
--
ALTER TABLE `routes`
  ADD PRIMARY KEY (`route_id`);

--
-- Indexes for table `schedules`
--
ALTER TABLE `schedules`
  ADD PRIMARY KEY (`schedule_id`),
  ADD KEY `fk_sched_supervisor` (`supervisor_id`),
  ADD KEY `fk_sched_route` (`route_id`),
  ADD KEY `idx_sched_bus_date` (`bus_id`,`schedule_date`),
  ADD KEY `idx_sched_driver_date` (`driver_id`,`schedule_date`);

--
-- Indexes for table `supervisors`
--
ALTER TABLE `supervisors`
  ADD PRIMARY KEY (`supervisor_id`),
  ADD UNIQUE KEY `employee_id` (`employee_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `volunteer_requests`
--
ALTER TABLE `volunteer_requests`
  ADD PRIMARY KEY (`volunteer_id`),
  ADD KEY `fk_vol_supervisor` (`supervisor_id`),
  ADD KEY `idx_vr_status` (`status`),
  ADD KEY `idx_vr_driver` (`driver_id`),
  ADD KEY `fk_vol_schedule` (`schedule_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `admin_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `buses`
--
ALTER TABLE `buses`
  MODIFY `bus_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `cancel_requests`
--
ALTER TABLE `cancel_requests`
  MODIFY `cancel_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `drivers`
--
ALTER TABLE `drivers`
  MODIFY `driver_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `leave_applications`
--
ALTER TABLE `leave_applications`
  MODIFY `leave_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `overtime_requests`
--
ALTER TABLE `overtime_requests`
  MODIFY `overtime_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `routes`
--
ALTER TABLE `routes`
  MODIFY `route_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `schedules`
--
ALTER TABLE `schedules`
  MODIFY `schedule_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT for table `supervisors`
--
ALTER TABLE `supervisors`
  MODIFY `supervisor_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `volunteer_requests`
--
ALTER TABLE `volunteer_requests`
  MODIFY `volunteer_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `cancel_requests`
--
ALTER TABLE `cancel_requests`
  ADD CONSTRAINT `fk_cancel_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`driver_id`),
  ADD CONSTRAINT `fk_cancel_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cancel_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`);

--
-- Constraints for table `leave_applications`
--
ALTER TABLE `leave_applications`
  ADD CONSTRAINT `fk_leave_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`driver_id`),
  ADD CONSTRAINT `fk_leave_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`);

--
-- Constraints for table `overtime_requests`
--
ALTER TABLE `overtime_requests`
  ADD CONSTRAINT `fk_ot_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ot_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`);

--
-- Constraints for table `schedules`
--
ALTER TABLE `schedules`
  ADD CONSTRAINT `fk_sched_bus` FOREIGN KEY (`bus_id`) REFERENCES `buses` (`bus_id`),
  ADD CONSTRAINT `fk_sched_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`driver_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_sched_route` FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`),
  ADD CONSTRAINT `fk_sched_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`);

--
-- Constraints for table `volunteer_requests`
--
ALTER TABLE `volunteer_requests`
  ADD CONSTRAINT `fk_vol_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`driver_id`),
  ADD CONSTRAINT `fk_vol_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_vol_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisors` (`supervisor_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
