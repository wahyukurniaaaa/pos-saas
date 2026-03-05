package middleware

import (
	"os"

	"posify-backend/pkg/response"

	"github.com/gofiber/fiber/v2"
)

func RequireAdminSecretKey(c *fiber.Ctx) error {
	key := c.Get("X-Admin-Secret-Key")
	expectedKey := os.Getenv("ADMIN_SECRET_KEY")

	if expectedKey == "" {
		// Should not happen in prod, but lock down if empty
		return response.Error(c, fiber.StatusInternalServerError, "Server misconfiguration: ADMIN_SECRET_KEY not set.")
	}

	if key != expectedKey {
		return response.Error(c, fiber.StatusUnauthorized, "Akses ditolak. Admin Secret Key tidak valid.")
	}

	return c.Next()
}
