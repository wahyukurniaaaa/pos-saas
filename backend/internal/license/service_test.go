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

func (m *MockRepository) UpdateDevice(device *models.LicenseDevice) error {
	args := m.Called(device)
	return args.Error(0)
}

func (m *MockRepository) ClearDevices(licenseID uint) error {
	args := m.Called(licenseID)
	return args.Error(0)
}

func (m *MockRepository) DeleteDevice(licenseID uint, fingerprint string) error {
	args := m.Called(licenseID, fingerprint)
	return args.Error(0)
}

func TestActivate_SuccessFirstTime(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo, nil)

	req := license.ActivateRequest{
		LicenseCode:       "VALID-CODE",
		DeviceFingerprint: "device-123",
		DeviceModel:       "Samsung S24",
		OsVersion:         "Android 14",
	}

	// Given an unused license
	mockLicense := &models.License{
		ID:          1,
		LicenseCode: "VALID-CODE",
		IsActive:    true,
		MaxDevices:  1,
		Devices:     []models.LicenseDevice{},
	}

	mockRepo.On("FindByCode", "VALID-CODE").Return(mockLicense, nil)
	mockRepo.On("Update", mock.AnythingOfType("*models.License")).Return(nil)

	// Action
	result, err := svc.Activate(req)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, 1, len(result.Devices))
	assert.Equal(t, "device-123", result.Devices[0].DeviceFingerprint)
	mockRepo.AssertExpectations(t)
}

func TestActivate_FailNotFound(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo, nil)

	req := license.ActivateRequest{LicenseCode: "INVALID"}

	mockRepo.On("FindByCode", "INVALID").Return(nil, nil) // explicitly nil, nil per repo impl

	result, err := svc.Activate(req)

	assert.ErrorIs(t, err, license.ErrLicenseNotFound)
	assert.Nil(t, result)
}

func TestActivate_FailUsedByOtherDevice(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo, nil)

	req := license.ActivateRequest{
		LicenseCode:       "USED-CODE",
		DeviceFingerprint: "new-device-hacker",
	}

	mockLicense := &models.License{
		ID:          1,
		LicenseCode: "USED-CODE",
		IsActive:    true,
		MaxDevices:  1,
		Devices: []models.LicenseDevice{
			{DeviceFingerprint: "old-device-owner"},
		},
	}

	mockRepo.On("FindByCode", "USED-CODE").Return(mockLicense, nil)

	result, err := svc.Activate(req)

	assert.ErrorIs(t, err, license.ErrLicenseUsed)
	assert.Nil(t, result)
}

func TestActivate_SuccessSameDeviceRetry(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo, nil)

	req := license.ActivateRequest{
		LicenseCode:       "USED-CODE",
		DeviceFingerprint: "my-device-123",
	}

	mockLicense := &models.License{
		ID:          1,
		LicenseCode: "USED-CODE",
		IsActive:    true,
		MaxDevices:  1,
		Devices: []models.LicenseDevice{
			{DeviceFingerprint: "my-device-123", LastVerifiedAt: time.Now().Add(-48 * time.Hour)},
		},
	}

	mockRepo.On("FindByCode", "USED-CODE").Return(mockLicense, nil)
	mockRepo.On("UpdateDevice", mock.Anything).Return(nil)

	// Action
	result, err := svc.Activate(req)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	mockRepo.AssertCalled(t, "UpdateDevice", mock.Anything)
}

func TestVerify_FailBanned(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo, nil)

	req := license.VerifyRequest{
		LicenseCode:       "BANNED-CODE",
		DeviceFingerprint: "my-device-123",
	}

	mockLicense := &models.License{
		ID:          1,
		LicenseCode: "BANNED-CODE",
		IsActive:    false, // Key point
		Devices: []models.LicenseDevice{
			{DeviceFingerprint: "my-device-123"},
		},
	}

	mockRepo.On("FindByCode", "BANNED-CODE").Return(mockLicense, nil)

	isActive, err := svc.Verify(req)

	assert.ErrorIs(t, err, license.ErrLicenseBanned)
	assert.False(t, isActive)
}

func TestDeregister_Success(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo, nil)

	req := license.DeregisterRequest{
		LicenseCode:   "TEST-CODE",
		CustomerEmail: "owner@test.com",
	}

	mockLicense := &models.License{
		ID:            1,
		LicenseCode:   "TEST-CODE",
		CustomerEmail: "owner@test.com",
	}

	mockRepo.On("FindByCode", "TEST-CODE").Return(mockLicense, nil)
	mockRepo.On("ClearDevices", uint(1)).Return(nil)

	err := svc.Deregister(req)

	assert.NoError(t, err)
	mockRepo.AssertExpectations(t)
}

func TestDeregister_FailEmailMismatch(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo, nil)

	req := license.DeregisterRequest{
		LicenseCode:   "TEST-CODE",
		CustomerEmail: "hacker@test.com",
	}

	mockLicense := &models.License{
		ID:            1,
		LicenseCode:   "TEST-CODE",
		CustomerEmail: "owner@test.com",
	}

	mockRepo.On("FindByCode", "TEST-CODE").Return(mockLicense, nil)

	err := svc.Deregister(req)

	assert.ErrorContains(t, err, "Email tidak cocok")
}

func TestGenerate_SuccessLite(t *testing.T) {
	mockRepo := new(MockRepository)
	// We pass nil for mailer. It might panic in goroutine, but usually test exits before
	svc := license.NewService(mockRepo, nil)

	req := license.GenerateRequest{
		TierLevel:     "lite",
		CustomerEmail: "test@example.com",
	}

	// generate10DigitCode calls FindByCode
	mockRepo.On("FindByCode", mock.AnythingOfType("string")).Return((*models.License)(nil), nil)
	mockRepo.On("Create", mock.AnythingOfType("*models.License")).Return(nil)

	lic, err := svc.Generate(req)

	assert.NoError(t, err)
	assert.NotNil(t, lic)
	assert.Equal(t, 1, lic.MaxDevices)
	assert.Equal(t, 1, lic.MaxOutlets)
	assert.Equal(t, "lite", lic.TierLevel)
}

func TestGenerate_SuccessPro(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo, nil)

	req := license.GenerateRequest{
		TierLevel:     "pro",
		CustomerEmail: "test@example.com",
	}

	mockRepo.On("FindByCode", mock.AnythingOfType("string")).Return((*models.License)(nil), nil)
	mockRepo.On("Create", mock.AnythingOfType("*models.License")).Return(nil)

	lic, err := svc.Generate(req)

	assert.NoError(t, err)
	assert.NotNil(t, lic)
	assert.Equal(t, 10, lic.MaxDevices)
	assert.Equal(t, 3, lic.MaxOutlets)
	assert.Equal(t, "pro", lic.TierLevel)
}

func TestGenerate_FailInvalidTier(t *testing.T) {
	mockRepo := new(MockRepository)
	svc := license.NewService(mockRepo, nil)

	req := license.GenerateRequest{
		TierLevel:     "enterprise",
		CustomerEmail: "test@example.com",
	}

	lic, err := svc.Generate(req)

	assert.ErrorContains(t, err, "TierLevel tidak valid")
	assert.Nil(t, lic)
}
