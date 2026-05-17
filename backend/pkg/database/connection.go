package database

import (
	"fmt"
	"log"
	"os"
	"strings"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func Connect() *gorm.DB {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		// Fallback to individual env vars if DATABASE_URL is not set
		host := os.Getenv("DB_HOST")
		user := os.Getenv("DB_USER")
		pass := os.Getenv("DB_PASSWORD")
		dbName := os.Getenv("DB_NAME")
		port := os.Getenv("DB_PORT")
		sslMode := os.Getenv("DB_SSLMODE")
		if sslMode == "" {
			sslMode = "disable"
		}

		dsn = fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
			host, user, pass, dbName, port, sslMode)
	}

	// Ensure search_path=public is set — required for Supabase Transaction Pooler
	// which does not set a default schema, causing AutoMigrate to fail with
	// "no schema has been selected to create in" (SQLSTATE 3F000).
	if !strings.Contains(dsn, "search_path") {
		if strings.Contains(dsn, "?") {
			dsn += "&search_path=public"
		} else {
			dsn += "?search_path=public"
		}
	}

	db, err := gorm.Open(postgres.New(postgres.Config{
		DSN:                  dsn,
		PreferSimpleProtocol: true, // Disables implicit prepared statement caching (fixes SQLSTATE 42P05)
	}), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Explicitly set search_path for the session as a safety net
	if err := db.Exec("SET search_path TO public").Error; err != nil {
		log.Printf("Warning: failed to set search_path: %v", err)
	}

	log.Println("Database connection successfully opened (PostgreSQL)")
	return db
}
