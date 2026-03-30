package fulfillment

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"os"

	"github.com/gofiber/fiber/v2"
	"posify-backend/pkg/response"
)

type Handler struct {
	svc Service
}

func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) HandleTikTokWebhook(c *fiber.Ctx) error {
	secret := os.Getenv("WEBHOOK_SECRET")
	signature := c.Get("X-Tiktok-Signature") 
	
	if secret != "" && signature != "" {
		mac := hmac.New(sha256.New, []byte(secret))
		mac.Write(c.Body())
		expectedMAC := hex.EncodeToString(mac.Sum(nil))
		if !hmac.Equal([]byte(signature), []byte(expectedMAC)) {
			return response.Error(c, fiber.StatusUnauthorized, "Invalid signature")
		}
	}

	var payload TikTokWebhookPayload
	if err := c.BodyParser(&payload); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Invalid payload")
	}

	if err := h.svc.ProcessTikTokOrder(payload); err != nil {
		// Retur OK agar marketplace tidak retrying terus menerus jika error non-critical (SKU not mapped)
		return response.Success(c, fiber.StatusOK, "Processed with skip/error", nil)
	}

	return response.Success(c, fiber.StatusOK, "Webhook processed successfully", nil)
}

func (h *Handler) HandleShopeeWebhook(c *fiber.Ctx) error {
	secret := os.Getenv("WEBHOOK_SECRET")
	signature := c.Get("Authorization") 
	
	// TODO: Shopee signature logic has specific string formation (url + body)
	if secret != "" && signature != "" {
		// Mock logic
	}

	var payload ShopeeWebhookPayload
	if err := c.BodyParser(&payload); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Invalid payload")
	}

	h.svc.ProcessShopeeOrder(payload)
	return response.Success(c, fiber.StatusOK, "Webhook processed successfully", nil)
}

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Post("/tiktok", h.HandleTikTokWebhook)
	router.Post("/shopee", h.HandleShopeeWebhook)
}
