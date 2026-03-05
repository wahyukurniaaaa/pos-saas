package license_test

import (
	"testing"
	"time"

	"posify-backend/internal/license"
	"posify-backend/internal/models"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockRepository is a mock implementation of the license.Repository interface
type MockRepository struct {
	mock.Mock
}

func (m *MockRepository) FindByCode(code string) (*models.License, error) {
	args := m.Called(code)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.License), args.Error(1)
}

func (m *MockRepository) Update(lic *models.License) error {
	args := m.Called(lic)
	return args.Error(0)
}

func (m *MockRepository) Create(lic *models.License) error {
	args := m.Called(lic)
	return args.Error(0)
}

func TestActivate_SuccessFirstTime(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo)

	req := license.ActivateRequest{
		LicenseCode:       "VALID-CODE",
		DeviceFingerprint: "device-123",
	}

	// Given an unused license
	mockLicense := &models.License{
		LicenseCode:       "VALID-CODE",
		DeviceFingerprint: nil,
		IsActive:          true,
	}

	mockRepo.On("FindByCode", "VALID-CODE").Return(mockLicense, nil)
	mockRepo.On("Update", mock.AnythingOfType("*models.License")).Return(nil)

	// Action
	result, err := svc.Activate(req)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "device-123", *result.DeviceFingerprint)
	assert.NotNil(t, result.ActivationDate)
	mockRepo.AssertExpectations(t)
}

func TestActivate_FailNotFound(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo)

	req := license.ActivateRequest{LicenseCode: "INVALID"}

	mockRepo.On("FindByCode", "INVALID").Return(nil, nil) // explicitly nil, nil per repo impl

	result, err := svc.Activate(req)

	assert.ErrorIs(t, err, license.ErrLicenseNotFound)
	assert.Nil(t, result)
}

func TestActivate_FailUsedByOtherDevice(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo)

	req := license.ActivateRequest{
		LicenseCode:       "USED-CODE",
		DeviceFingerprint: "new-device-hacker",
	}

	oldFingerprint := "old-device-owner"
	mockLicense := &models.License{
		LicenseCode:       "USED-CODE",
		DeviceFingerprint: &oldFingerprint,
		IsActive:          true,
	}

	mockRepo.On("FindByCode", "USED-CODE").Return(mockLicense, nil)

	result, err := svc.Activate(req)

	assert.ErrorIs(t, err, license.ErrLicenseUsed)
	assert.Nil(t, result)
}

func TestActivate_SuccessSameDeviceRetry(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo)

	req := license.ActivateRequest{
		LicenseCode:       "USED-CODE",
		DeviceFingerprint: "my-device-123",
	}

	fp := "my-device-123"
	now := time.Now()
	mockLicense := &models.License{
		LicenseCode:       "USED-CODE",
		DeviceFingerprint: &fp,
		ActivationDate:    &now,
		IsActive:          true,
	}

	mockRepo.On("FindByCode", "USED-CODE").Return(mockLicense, nil)

	// Should NOT call Update
	result, err := svc.Activate(req)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	mockRepo.AssertNotCalled(t, "Update")
}

func TestVerify_FailBanned(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo)

	req := license.VerifyRequest{
		LicenseCode:       "BANNED-CODE",
		DeviceFingerprint: "my-device-123",
	}

	fp := "my-device-123"
	mockLicense := &models.License{
		LicenseCode:       "BANNED-CODE",
		DeviceFingerprint: &fp,
		IsActive:          false, // Key point
	}

	mockRepo.On("FindByCode", "BANNED-CODE").Return(mockLicense, nil)

	isActive, err := svc.Verify(req)

	assert.ErrorIs(t, err, license.ErrLicenseBanned)
	assert.False(t, isActive)
}
