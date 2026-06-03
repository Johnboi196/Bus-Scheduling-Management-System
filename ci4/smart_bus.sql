-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 03, 2026 at 05:12 AM
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
(1, 'System Admin', 'ADM001', 'admin@bus.local', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '2026-05-11 09:48:23', '2026-05-11 09:54:17');

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
(2, 'WXY5678', 'AA:BB:CC:DD:EE:02', 'available', '2026-05-11 09:48:23');

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
(8, 20, 1, 1, 'injury during work', 'Approved', '2026-06-03 03:51:44', '2026-06-02 19:52:20');

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
(1, 'Ali Driver', 'ali@bus.local', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '+60-12-3456789', 'active', '2026-05-11 09:48:23', '2026-05-14 03:08:53'),
(2, 'Siti Driver', 'siti@bus.local', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '+60-13-7654321', 'active', '2026-05-11 09:48:23', '2026-05-14 03:08:53');

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
(2, 1, NULL, '2026-06-06', '2026-06-08', 'event', 'Pending', '2026-06-03 03:48:13', NULL);

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
(7, 17, 1, 579, 'solat', 'Approved', '2026-06-03 03:39:30', '2026-06-02 19:46:17');

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
(11, 'ML 88 Outbound', 'Terminal Bukit Sentosa', 'HAB LEBUH PUDU (TP)', 51.00, '2026-05-24 15:42:22');

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
(22, 1, 1, 1, 8, '2026-06-02', '23:00:00', '14:00:00', NULL, NULL, 'Pending', 1, NULL, '2026-06-03 02:57:28', '2026-06-03 02:57:28');

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
(1, 'Jane Supervisor', 'SUP001', 'jane@bus.local', '$2y$10$Lw2k0uK.IMg7rXFfwsK6tOWrKopH8Zbu0kDYNvQVpAM8R/UETCkyC', '2026-05-11 09:48:23', '2026-05-11 09:54:16');

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
(3, 20, 1, NULL, 'dari 1pm hingga 2pm', 'Pending', '2026-06-03 04:00:38', NULL);

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
  MODIFY `bus_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `cancel_requests`
--
ALTER TABLE `cancel_requests`
  MODIFY `cancel_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `drivers`
--
ALTER TABLE `drivers`
  MODIFY `driver_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `leave_applications`
--
ALTER TABLE `leave_applications`
  MODIFY `leave_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `overtime_requests`
--
ALTER TABLE `overtime_requests`
  MODIFY `overtime_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `routes`
--
ALTER TABLE `routes`
  MODIFY `route_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `schedules`
--
ALTER TABLE `schedules`
  MODIFY `schedule_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `supervisors`
--
ALTER TABLE `supervisors`
  MODIFY `supervisor_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `volunteer_requests`
--
ALTER TABLE `volunteer_requests`
  MODIFY `volunteer_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

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
