package main

import (
	"log"

	"posify-backend/internal/models"
	"posify-backend/pkg/database"

	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load()
	db := database.Connect()
	
	// Ensure table exists
	db.AutoMigrate(&models.License{})

	var count int64
	db.Model(&models.License{}).Count(&count)
	
	if count == 0 {
		db.Create(&models.License{
			LicenseCode: "POS-L1-A8F9K2-X1Y2Z3",
			TierLevel:   "Tier 1 - Lifetime",
			MaxDevices:  1,
			IsActive:    true,
		})
		log.Println("Seeded Dummy License: POS-L1-A8F9K2-X1Y2Z3")
	} else {
		log.Println("Database already Seeded")
	}
}
