package license

import (
	"errors"

	"posify-backend/internal/models"

	"gorm.io/gorm"
)

type Repository interface {
	FindByCode(code string) (*models.License, error)
	Update(license *models.License) error
	Create(license *models.License) error
	UpdateDevice(device *models.LicenseDevice) error
	ClearDevices(licenseID uint) error
	DeleteDevice(licenseID uint, fingerprint string) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindByCode(code string) (*models.License, error) {
	var license models.License
	err := r.db.Preload("Devices").Where("license_code = ?", code).First(&license).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil // Return nil, nil for not found to handle explicitly in service
		}
		return nil, err
	}
	return &license, nil
}

func (r *repository) Update(license *models.License) error {
	return r.db.Save(license).Error
}

func (r *repository) Create(license *models.License) error {
	return r.db.Create(license).Error
}

func (r *repository) UpdateDevice(device *models.LicenseDevice) error {
	return r.db.Save(device).Error
}

func (r *repository) ClearDevices(licenseID uint) error {
	return r.db.Where("license_id = ?", licenseID).Delete(&models.LicenseDevice{}).Error
}

// DeleteDevice removes a single device record identified by its fingerprint under a specific license.
func (r *repository) DeleteDevice(licenseID uint, fingerprint string) error {
	return r.db.
		Where("license_id = ? AND device_fingerprint = ?", licenseID, fingerprint).
		Delete(&models.LicenseDevice{}).
		Error
}
