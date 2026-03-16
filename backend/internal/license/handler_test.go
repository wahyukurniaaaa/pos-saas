package license_test

import (
	"bytes"
	"encoding/json"
	"net/http/httptest"
	"testing"
	"time"

	"posify-backend/internal/license"
	"posify-backend/internal/models"

	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockService is a mock implementation of the license.Service interface
type MockService struct {
	mock.Mock
}

func (m *MockService) Activate(req license.ActivateRequest) (*models.License, error) {
	args := m.Called(req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.License), args.Error(1)
}

func (m *MockService) Verify(req license.VerifyRequest) (bool, error) {
	args := m.Called(req)
	return args.Bool(0), args.Error(1)
}

func (m *MockService) Generate(req license.GenerateRequest) (*models.License, error) {
	args := m.Called(req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.License), args.Error(1)
}

func setupApp(mockSvc license.Service) *fiber.App {
	app := fiber.New()
	handler := license.NewHandler(mockSvc)
	api := app.Group("/api/v1/license")
	handler.RegisterRoutes(api)
	return app
}

func TestHandler_Activate_Success(t *testing.T) {
	mockSvc := new(MockService)
	app := setupApp(mockSvc)

	reqBody := license.ActivateRequest{
		LicenseCode:       "TEST-OK",
		DeviceFingerprint: "device123",
		DeviceModel:       "Model-A",
		OsVersion:         "Android",
	}

	activationTime := time.Now()

	mockLicense := &models.License{
		LicenseCode: "TEST-OK",
		TierLevel:   "Tier 1",
		MaxDevices:  2,
		Devices: []models.LicenseDevice{
			{
				DeviceFingerprint: "device123",
				ActivationDate:    activationTime,
			},
		},
	}

	mockSvc.On("Activate", reqBody).Return(mockLicense, nil)

	bodyBytes, _ := json.Marshal(reqBody)
	req := httptest.NewRequest("POST", "/api/v1/license/activate", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")

	resp, err := app.Test(req)
	assert.NoError(t, err)
	assert.Equal(t, 200, resp.StatusCode)

	var resData map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&resData)

	assert.Equal(t, "success", resData["status"])
	assert.Equal(t, "Lisensi berhasil diaktifkan untuk perangkat ini.", resData["message"])
	
	dataPayload := resData["data"].(map[string]interface{})
	assert.Equal(t, "TEST-OK", dataPayload["license_code"])
	assert.Equal(t, "Tier 1", dataPayload["tier_level"])
}

func TestHandler_Activate_FailValidation(t *testing.T) {
	mockSvc := new(MockService)
	app := setupApp(mockSvc)

	// Missing LicenseCode and Fingerprint
	reqBody := map[string]string{
		"device_model": "Model-B",
	}

	bodyBytes, _ := json.Marshal(reqBody)
	req := httptest.NewRequest("POST", "/api/v1/license/activate", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")

	resp, err := app.Test(req)
	assert.NoError(t, err)
	assert.Equal(t, 400, resp.StatusCode)

	var resData map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&resData)

	assert.Equal(t, "error", resData["status"])
	// Should indicate format or validation error
	assert.Contains(t, resData["message"].(string), "Data yang dikirim tidak lengkap")
}

func TestHandler_Activate_FailNotFound(t *testing.T) {
	mockSvc := new(MockService)
	app := setupApp(mockSvc)

	reqBody := license.ActivateRequest{
		LicenseCode:       "WRONG",
		DeviceFingerprint: "device123",
	}

	mockSvc.On("Activate", reqBody).Return(nil, license.ErrLicenseNotFound)

	bodyBytes, _ := json.Marshal(reqBody)
	req := httptest.NewRequest("POST", "/api/v1/license/activate", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")

	resp, err := app.Test(req)
	assert.NoError(t, err)
	assert.Equal(t, 404, resp.StatusCode)

	var resData map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&resData)
	assert.Equal(t, "error", resData["status"])
	assert.Equal(t, license.ErrLicenseNotFound.Error(), resData["message"])
}
