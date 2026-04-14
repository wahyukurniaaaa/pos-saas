package models

import (
	"time"
)

// Outlet represents a store location
type Outlet struct {
	ID        string     `gorm:"primaryKey;type:uuid" json:"id"`
	Name      string     `gorm:"not null" json:"name"`
	Address   string     `json:"address"`
	Phone     string     `json:"phone"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `gorm:"index" json:"deleted_at"`
}

// Employee represents a store staff member
type Employee struct {
	ID                  string     `gorm:"primaryKey;type:uuid" json:"id"`
	Name                string     `gorm:"not null" json:"name"`
	PIN                 string     `gorm:"not null" json:"pin"`
	Role                string     `gorm:"not null" json:"role"`
	FailedLoginAttempts int        `gorm:"default:0" json:"failed_login_attempts"`
	LockedUntil         *time.Time `json:"locked_until"`
	Status              string     `gorm:"default:'active'" json:"status"`
	PhotoURI            *string    `json:"photo_uri"`
	OutletID            *string    `gorm:"type:uuid" json:"outlet_id"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
	DeletedAt           *time.Time `gorm:"index" json:"deleted_at"`
}
