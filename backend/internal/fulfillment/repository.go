package fulfillment

import (
	"errors"
	"posify-backend/internal/models"

	"gorm.io/gorm"
)

type Repository interface {
	FindBySKU(sku string) (*models.MappingSKU, error)
	CheckOrderExists(orderID string, source string) (bool, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindBySKU(sku string) (*models.MappingSKU, error) {
	var mapping models.MappingSKU
	err := r.db.Where("marketplace_sku = ?", sku).First(&mapping).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &mapping, nil
}

func (r *repository) CheckOrderExists(orderID string, source string) (bool, error) {
	var count int64
	err := r.db.Model(&models.License{}).Where("order_id = ? AND source = ?", orderID, source).Count(&count).Error
	return count > 0, err
}
