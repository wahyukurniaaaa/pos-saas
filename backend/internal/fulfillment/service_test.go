package fulfillment_test

import (
	"testing"

	"posify-backend/internal/fulfillment"
	"posify-backend/internal/license"
	"posify-backend/internal/models"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// --- Mocks ---

type MockRepository struct {
	mock.Mock
}

func (m *MockRepository) FindBySKU(sku string) (*models.MappingSKU, error) {
	args := m.Called(sku)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.MappingSKU), args.Error(1)
}

func (m *MockRepository) CheckOrderExists(orderID string, source string) (bool, error) {
	args := m.Called(orderID, source)
	return args.Bool(0), args.Error(1)
}

type MockLicenseService struct {
	mock.Mock
}

func (m *MockLicenseService) Activate(req license.ActivateRequest) (*models.License, error) {
	return nil, nil
}
func (m *MockLicenseService) Verify(req license.VerifyRequest) (bool, error) {
	return false, nil
}
func (m *MockLicenseService) Deregister(req license.DeregisterRequest) error {
	return nil
}

func (m *MockLicenseService) Generate(req license.GenerateRequest) (*models.License, error) {
	args := m.Called(req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.License), args.Error(1)
}

// --- TikTok Tests ---

func TestProcessTikTokOrder_Success(t *testing.T) {
	mockRepo := new(MockRepository)
	mockLicenseSvc := new(MockLicenseService)
	svc := fulfillment.NewService(mockRepo, mockLicenseSvc)

	payload := fulfillment.TikTokWebhookPayload{}
	payload.Data.OrderID = "TK-123"
	payload.Data.OrderStatus = "AWAITING_SHIPMENT"

	// Expectations
	mockRepo.On("CheckOrderExists", "TK-123", "tiktok").Return(false, nil)

	mockMapping := &models.MappingSKU{
		MarketplaceSKU: "POS-LITE-TIKTOK",
		TierLevel:      "Tier 1",
		MaxDevices:     1,
	}
	mockRepo.On("FindBySKU", "POS-LITE-TIKTOK").Return(mockMapping, nil)

	mockLicenseSvc.On("Generate", mock.AnythingOfType("license.GenerateRequest")).Return(&models.License{}, nil)

	// Action
	err := svc.ProcessTikTokOrder(payload)

	// Assert
	assert.NoError(t, err)
	mockRepo.AssertExpectations(t)
	mockLicenseSvc.AssertExpectations(t)
}

func TestProcessTikTokOrder_Duplicate(t *testing.T) {
	mockRepo := new(MockRepository)
	mockLicenseSvc := new(MockLicenseService)
	svc := fulfillment.NewService(mockRepo, mockLicenseSvc)

	payload := fulfillment.TikTokWebhookPayload{}
	payload.Data.OrderID = "TK-123"
	payload.Data.OrderStatus = "AWAITING_SHIPMENT"

	// Expectations
	mockRepo.On("CheckOrderExists", "TK-123", "tiktok").Return(true, nil) // Order exists

	err := svc.ProcessTikTokOrder(payload)

	assert.NoError(t, err) // duplicate is ignored without error
	mockRepo.AssertCalled(t, "CheckOrderExists", "TK-123", "tiktok")
	mockRepo.AssertNotCalled(t, "FindBySKU") // Should skip
}

func TestProcessTikTokOrder_IgnoredStatus(t *testing.T) {
	mockRepo := new(MockRepository)
	mockLicenseSvc := new(MockLicenseService)
	svc := fulfillment.NewService(mockRepo, mockLicenseSvc)

	payload := fulfillment.TikTokWebhookPayload{}
	payload.Data.OrderID = "TK-123"
	payload.Data.OrderStatus = "UNPAID" // Not eligible for fulfillment yet

	err := svc.ProcessTikTokOrder(payload)

	assert.NoError(t, err) 
	mockRepo.AssertNotCalled(t, "CheckOrderExists") 
}

// --- Shopee Tests ---

func TestProcessShopeeOrder_Success(t *testing.T) {
	mockRepo := new(MockRepository)
	mockLicenseSvc := new(MockLicenseService)
	svc := fulfillment.NewService(mockRepo, mockLicenseSvc)

	payload := fulfillment.ShopeeWebhookPayload{}
	payload.Data.Ordersn = "SHP-999"
	payload.Data.Status = "READY_TO_SHIP"

	// Expectations
	mockRepo.On("CheckOrderExists", "SHP-999", "shopee").Return(false, nil)

	mockMapping := &models.MappingSKU{
		MarketplaceSKU: "POS-LITE-SHOPEE",
		TierLevel:      "Tier 1",
		MaxDevices:     1,
	}
	mockRepo.On("FindBySKU", "POS-LITE-SHOPEE").Return(mockMapping, nil)

	mockLicenseSvc.On("Generate", mock.AnythingOfType("license.GenerateRequest")).Return(&models.License{}, nil)

	// Action
	err := svc.ProcessShopeeOrder(payload)

	// Assert
	assert.NoError(t, err)
	mockRepo.AssertExpectations(t)
	mockLicenseSvc.AssertExpectations(t)
}

func TestProcessShopeeOrder_UnmappedSKU(t *testing.T) {
	mockRepo := new(MockRepository)
	mockLicenseSvc := new(MockLicenseService)
	svc := fulfillment.NewService(mockRepo, mockLicenseSvc)

	payload := fulfillment.ShopeeWebhookPayload{}
	payload.Data.Ordersn = "SHP-UNKNOWN"
	payload.Data.Status = "COMPLETED"

	// Expectations
	mockRepo.On("CheckOrderExists", "SHP-UNKNOWN", "shopee").Return(false, nil)
	mockRepo.On("FindBySKU", "POS-LITE-SHOPEE").Return(nil, nil) // Return nil, not mapped

	// Action
	err := svc.ProcessShopeeOrder(payload)

	// Assert
	assert.ErrorContains(t, err, "SKU not mapped")
	mockLicenseSvc.AssertNotCalled(t, "Generate")
}
