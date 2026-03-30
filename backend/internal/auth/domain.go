package auth

import "posify-backend/internal/models"

type RegisterRequest struct {
	Email             string `json:"email" validate:"required,email"`
	Password          string `json:"password" validate:"required,min=6"`
	LicenseCode       string `json:"license_code,omitempty"`
	DeviceFingerprint string `json:"device_fingerprint,omitempty"`
}

type RegisterResponse struct {
	User    *models.User    `json:"user"`
	License *models.License `json:"license,omitempty"`
	Token   string          `json:"token,omitempty"` // For future JWT, omit for now if not used
}

type Repository interface {
	CreateUser(user *models.User) error
	FindByEmail(email string) (*models.User, error)
}

type Service interface {
	RegisterWithLicense(req RegisterRequest) (*RegisterResponse, error)
}
