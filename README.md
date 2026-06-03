# Smart Bus System

## Project Overview

This project consists of two main components:

1. **Flutter Mobile Application** – Located in the Flutter project folder.
2. **CodeIgniter 4 Backend API** – Located in the `ci4` folder.

Both components are required for the system to function properly.

---

## Flutter Setup

### Important Files

Before running the Flutter application, ensure the following files are placed in their respective directories:

* `AndroidManifest.xml` → Place inside the Android project's manifest directory.
* `pubspec.yaml` → Place in the root directory of the Flutter project.

### Application Source Code

The main Flutter application source code is located inside the `lib` folder.

### Running the Flutter Application

1. Open the Flutter project.
2. Run:

   ```bash
   flutter pub get
   ```
3. Start the application:

   ```bash
   flutter run
   ```

---

## CodeIgniter 4 Backend Setup

### XAMPP Configuration

The `ci4` folder contains the CodeIgniter 4 backend project.

1. Copy the entire `ci4` folder into:

   ```
   xampp/htdocs/
   ```
2. Start:

   * Apache
   * MySQL

from the XAMPP Control Panel.

---

## Database Setup

A SQL database file is provided inside the `ci4` folder.

### Steps

1. Open phpMyAdmin.
2. Create a new database named:

   ```
   smart_bus
   ```
3. Select the newly created database.
4. Import the SQL file provided inside the `ci4` folder.
5. Wait for the import process to complete successfully.

---

## Running the Backend

After placing the project in `htdocs` and importing the database:

1. Ensure Apache and MySQL are running.
2. Access the backend through your local server configuration.
3. Verify the database connection settings if necessary.

---

## Notes

* The Flutter application and CodeIgniter 4 backend must both be configured correctly for the system to work.
* Ensure `AndroidManifest.xml` and `pubspec.yaml` are placed in their correct Flutter directories before running the application.
* The database name must be exactly:

  ```
  smart_bus
  ```
* The provided SQL file must be imported into the `smart_bus` database before starting the system.
