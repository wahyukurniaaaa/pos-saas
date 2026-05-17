package auth

import (
	"posify-backend/pkg/response"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

type handler struct {
	svc      Service
	validate *validator.Validate
}

func NewHandler(svc Service) *handler {
	return &handler{
		svc:      svc,
		validate: validator.New(),
	}
}

func (h *handler) RegisterRoutes(router fiber.Router) {
	router.Post("/register", h.RegisterWithLicense)
}

func (h *handler) RegisterWithLicense(c *fiber.Ctx) error {
	var req RegisterRequest

	// Parse JSON
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format request tidak valid")
	}

	// Validation
	if err := h.validate.Struct(req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Validasi gagal: "+err.Error())
	}

	// Service Process
	res, err := h.svc.RegisterWithLicense(req)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, err.Error())
	}

	return response.Success(c, fiber.StatusCreated, "Akun berhasil dibuat. Silakan hubungi admin untuk aktivasi lisensi.", res)
}
