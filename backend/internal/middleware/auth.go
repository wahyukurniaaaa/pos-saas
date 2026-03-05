package middleware

import (
	"os"

	"posify-backend/pkg/response"

	"github.com/gofiber/fiber/v2"
)

func RequireAppClientKey(c *fiber.Ctx) error {
	key := c.Get("X-App-Client-Key")
	expectedKey := os.Getenv("APP_CLIENT_KEY")

	if expectedKey == "" {
		// Should not happen in prod
		return c.Next()
	}

	if key != expectedKey {
		return response.Error(c, fiber.StatusUnauthorized, "Akses ditolak. Client Key tidak terdaftar.")
	}

	return c.Next()
}
