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

// StoreProfile represents the business profile for a store owner
type StoreProfile struct {
	ID                     string     `gorm:"primaryKey;type:uuid" json:"id"`
	Name                   string     `gorm:"not null" json:"name"`
	Phone                  *string    `json:"phone"`
	Address                *string    `json:"address"`
	BusinessType           *string    `json:"business_type"`
	LogoURI                *string    `json:"logo_uri"`
	TaxPercentage          int        `gorm:"default:0" json:"tax_percentage"`
	TaxType                string     `gorm:"default:'exclusive'" json:"tax_type"`
	ServiceChargePercentage int       `gorm:"default:0" json:"service_charge_percentage"`
	LoyaltyPointConversion int        `gorm:"default:10000" json:"loyalty_point_conversion"`
	LoyaltyPointValue      int        `gorm:"default:100" json:"loyalty_point_value"`
	DeductStockOnHold      bool       `gorm:"default:false" json:"deduct_stock_on_hold"`
	UserID                 string     `json:"user_id"`
	CreatedAt              time.Time  `json:"created_at"`
	UpdatedAt              time.Time  `json:"updated_at"`
	DeletedAt              *time.Time `gorm:"index" json:"deleted_at"`
}
