# Beginner's Guide to SQL & MariaDB (Inception Evaluation)

This guide introduces SQL fundamentals, core syntax, and practical commands specifically tailored for defending your **Inception** MariaDB database during evaluation.

---

## 1. Fundamental SQL Concepts

* **Database:** A structured container holding one or more related tables (e.g., `wordpress_db`).
* **Table:** A grid of data organized into rows and columns (e.g., `wp_posts`, `wp_comments`).
* **Row (Record):** A single entry in a table (e.g., one comment or one blog post).
* **Column (Field):** A specific attribute of the record (e.g., `comment_author`, `post_title`).
* **Semicolon `;`:** Terminates SQL statements. Every command in the CLI must end with `;` (or `\G`).

---

## 2. Accessing MariaDB in Docker

### Connect as Root (Full Admin Access):
```bash
docker exec -it mariadb mariadb -u root -p
# Enter Password: db_root_secret_password_456!
```

### Connect as Regular Database User (`wp_user`):
```bash
docker exec -it mariadb mariadb -u wp_user -p wordpress_db
# Enter Password: db_user_secret_password_123!
```

---

## 3. Database Navigation Commands

| Action | Command | Explanation |
| :--- | :--- | :--- |
| **List Databases** | `SHOW DATABASES;` | Displays all database instances on the MariaDB server. |
| **Select Database** | `USE wordpress_db;` | Switches into `wordpress_db` so you can query its tables. |
| **Show Active DB** | `SELECT DATABASE();` | Prints the name of the database currently in use. |

---

## 4. Table Inspection Commands

Once you have selected a database (`USE wordpress_db;`):

| Action | Command | Explanation |
| :--- | :--- | :--- |
| **List Tables** | `SHOW TABLES;` | Lists all tables inside `wordpress_db` (`wp_posts`, `wp_users`, etc.). |
| **View Table Schema** | `DESCRIBE wp_posts;` | Shows column names, data types, and primary keys of a table. |

---

## 5. Querying Data with `SELECT`

`SELECT` retrieves records from a table.

### Syntax:
```sql
SELECT column1, column2 FROM table_name WHERE condition;
```

### Basic Examples:
```sql
-- Select all columns and all rows from wp_users
SELECT * FROM wp_users;

-- Select specific columns only
SELECT ID, user_login, user_email FROM wp_users;

-- Select with a filter (WHERE clause)
SELECT * FROM wp_comments WHERE comment_author = 'regular_author';
```

### 💡 Pro-Tip: Vertical Display (`\G`)
In wide tables like `wp_posts`, printing lines horizontally gets messy. Use **`\G`** instead of **`;`** at the end of a command to display output vertically line-by-line:

```sql
SELECT ID, post_title, post_content FROM wp_posts\G
```

---

## 6. Exact SQL Queries for Inception Defense

When the evaluator asks to inspect your database, use these targeted queries:

### A. Prove Database is Not Empty:
```sql
USE wordpress_db;
SHOW TABLES;
SELECT COUNT(*) AS total_posts FROM wp_posts;
```

### B. View WordPress User Accounts:
*(Proves Admin username does NOT contain `admin` or `Admin`)*
```sql
SELECT ID, user_login, user_email, user_registered FROM wp_users;
```

### C. View Posted Comments (`wp_comments`):
*(Show comments submitted during evaluation setup)*
```sql
SELECT comment_ID, comment_author, comment_content, comment_date FROM wp_comments;
```
*(Or vertical view)*
```sql
SELECT * FROM wp_comments\G
```

### D. View Edited Page / Post Content (`wp_posts`):
*(Proves site changes persist into the MariaDB database)*
```sql
SELECT ID, post_title, post_status, post_modified FROM wp_posts;
```

---

## 7. Basic Data Manipulation (CRUD Operations)

If you ever need to add, update, or delete data manually:

### Create (INSERT):
```sql
INSERT INTO wp_comments (comment_post_ID, comment_author, comment_content) 
VALUES (1, 'evaluator', 'Great defense presentation!');
```

### Update (UPDATE):
```sql
UPDATE wp_posts 
SET post_title = 'Updated Title Defense' 
WHERE ID = 1;
```

### Delete (DELETE):
```sql
DELETE FROM wp_comments WHERE comment_ID = 5;
```

---

## 8. Exiting the MariaDB CLI

To exit the MariaDB shell and return to your terminal prompt, run any of the following:

```sql
exit;
```
*(or type `\q` or press `CTRL + D`)*
