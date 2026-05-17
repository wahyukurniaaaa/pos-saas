package auth

import "posify-backend/internal/models"

type RegisterRequest struct {
	Email             string `json:"email" validate:"required,email"`
	Password          string `json:"password" validate:"required,min=6"`
	StoreName         string `json:"store_name" validate:"required"`
	Phone             string `json:"phone" validate:"required"`
	BusinessType      string `json:"business_type"`
	DeviceFingerprint string `json:"device_fingerprint,omitempty"`
}

type RegisterResponse struct {
	User    *models.User    `json:"user"`
	License *models.License `json:"license,omitempty"`
}

type Repository interface {
	CreateUser(user *models.User) error
	FindByEmail(email string) (*models.User, error)
	CreateStoreProfile(profile *models.StoreProfile) error
}

type Service interface {
	RegisterWithLicense(req RegisterRequest) (*RegisterResponse, error)
}
