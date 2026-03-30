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
	db.AutoMigrate(&models.License{}, &models.MappingSKU{}, &models.User{})

	// Seed mapping SKUs
	var skuCount int64
	db.Model(&models.MappingSKU{}).Count(&skuCount)
	if skuCount == 0 {
		db.Create(&[]models.MappingSKU{
			{MarketplaceSKU: "POS-LITE-TIKTOK", TierLevel: "Tier 1 - Lifetime", MaxDevices: 1},
			{MarketplaceSKU: "POS-LITE-SHOPEE", TierLevel: "Tier 1 - Lifetime", MaxDevices: 1},
		})
		log.Println("Seeded Dummy Mapping SKUs: POS-LITE-TIKTOK, POS-LITE-SHOPEE")
	}

	var count int64
	db.Model(&models.License{}).Count(&count)
	
	if count == 0 {
		db.Create(&models.License{
			LicenseCode:   "A8F9K2X1Y2",
			TierLevel:     "Tier 1 - Lifetime",
			MaxDevices:    1,
			IsActive:      true,
			CustomerEmail: "tester@posify",
			Source:        "seed",
		})
		log.Println("Seeded Dummy License: A8F9K2X1Y2")
	} else {
		log.Println("Licenses database already Seeded")
	}
}
