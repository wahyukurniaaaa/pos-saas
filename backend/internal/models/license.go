package models

import (
	"time"
)

type License struct {
	ID            uint            `gorm:"primaryKey;autoIncrement" json:"-"`
	LicenseCode   string          `gorm:"unique;not null" json:"license_code"`
	TierLevel     string          `gorm:"default:'Tier 1 - Lifetime'" json:"tier_level"`
	MaxDevices    int             `gorm:"default:1" json:"max_devices"`
	MaxOutlets    int             `gorm:"default:1" json:"max_outlets"`
	IsActive      bool            `gorm:"default:true" json:"is_active"`
	CustomerEmail string          `gorm:"index" json:"customer_email"`
	OrderID       string          `gorm:"index;default:null" json:"order_id"`
	Source        string          `gorm:"default:null" json:"source"`
	Devices       []LicenseDevice `gorm:"foreignKey:LicenseID" json:"devices,omitempty"`
	CreatedAt     time.Time       `json:"-"`
	UpdatedAt     time.Time       `json:"-"`
}

type LicenseDevice struct {
	ID                uint      `gorm:"primaryKey;autoIncrement" json:"-"`
	LicenseID         uint      `gorm:"index" json:"-"`
	DeviceFingerprint string    `gorm:"index;not null" json:"device_fingerprint"`
	DeviceModel       string    `json:"device_model"`
	OsVersion         string    `json:"os_version"`
	ActivationDate    time.Time `json:"activation_date"`
	LastVerifiedAt    time.Time `json:"last_verified_at"`
	CreatedAt         time.Time `json:"-"`
}
