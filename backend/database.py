import sqlite3
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent

DATABASE_DIR = BASE_DIR / "database"
DATABASE_DIR.mkdir(parents=True, exist_ok=True)

DATABASE_PATH = DATABASE_DIR / "socialshield.db"


def get_connection():
    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def create_tables():
    connection = get_connection()
    cursor = connection.cursor()

    # Users table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
        )
    """)

    # Scan history table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS scan_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            x_username TEXT,
            profile_url TEXT NOT NULL,
            result TEXT NOT NULL,
            confidence REAL,
            scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    connection.commit()
    connection.close()


def save_scan(user_id, x_username, profile_url, result, confidence):
    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("""
        INSERT INTO scan_history
        (user_id, x_username, profile_url, result, confidence)
        VALUES (?, ?, ?, ?, ?)
    """, (
        user_id,
        x_username,
        profile_url,
        result,
        confidence
    ))

    connection.commit()
    connection.close()

