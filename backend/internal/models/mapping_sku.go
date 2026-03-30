package models

import "time"

type MappingSKU struct {
	ID             uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	MarketplaceSKU string    `gorm:"uniqueIndex;not null" json:"marketplace_sku"`
	TierLevel      string    `gorm:"not null" json:"tier_level"`
	MaxDevices     int       `gorm:"not null;default:1" json:"max_devices"`
	CreatedAt      time.Time `json:"-"`
	UpdatedAt      time.Time `json:"-"`
}
