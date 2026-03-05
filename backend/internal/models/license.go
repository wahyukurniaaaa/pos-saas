package models

import (
	"time"
)

type License struct {
	ID                uint      `gorm:"primaryKey;autoIncrement" json:"-"`
	LicenseCode       string    `gorm:"uniqueIndex;not null" json:"license_code"`
	DeviceFingerprint *string   `gorm:"uniqueIndex" json:"device_fingerprint"` // Null if untouched
	DeviceModel       *string   `json:"device_model"`
	OsVersion         *string   `json:"os_version"`
	ActivationDate    *time.Time`json:"activation_date"`
	TierLevel         string    `gorm:"default:'Tier 1 - Lifetime'" json:"tier_level"`
	MaxDevices        int       `gorm:"default:1" json:"max_devices"`
	IsActive          bool      `gorm:"default:true" json:"is_active"`
	CreatedAt         time.Time `json:"-"`
	UpdatedAt         time.Time `json:"-"`
}
