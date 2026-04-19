
import mysql.connector

def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="YOUR_MYSQL_USERNAME",
        password="YOUR_MYSQL_PASSWORD",
        database="cyber_irs"
    )