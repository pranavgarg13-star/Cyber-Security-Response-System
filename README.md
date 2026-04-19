# Cybersecurity Incident Response System

A DBMS project built with MySQL, Flask, and Python.

## Project objectives
1. Model a database for cybersecurity incidents (events, alerts, vulnerabilities, threats, mitigation actions)
2. Implement SQL queries to correlate events, identify attack patterns, assess risk, and prioritize response
3. Identify the weak entity and create an ER diagram

## Tech stack
- Database: MySQL
- Backend: Python / Flask
- Frontend: HTML, CSS, Jinja2

## Setup instructions

### 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/cyber-res.git
cd cyber-res

### 2. Install dependencies
pip install -r requirements.txt

### 3. Set up the database
- Open MySQL Workbench
- Run cyber_res.sql to create and populate the database

### 4. Configure database connection
cp db_example.py db.py
# Edit db.py with your MySQL username and password

### 5. Run the app
python app.py
Visit http://127.0.0.1:5000
