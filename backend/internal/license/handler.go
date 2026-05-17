package license

import (
	"fmt"
	"log"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"

	"posify-backend/pkg/response"
)

var validate = validator.New()

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Post("/activate", h.Activate)
	router.Post("/verify", h.Verify)
	router.Post("/verify-account", h.VerifyAccount)
	router.Post("/reset", h.Deregister)
	router.Post("/devices", h.GetDevices)
}

func (h *Handler) RegisterAdminRoutes(router fiber.Router) {
	router.Post("/generate", h.Generate)
}

func (h *Handler) Activate(c *fiber.Ctx) error {
	var req ActivateRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format JSON tidak valid.")
	}

	if err := validate.Struct(req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Data yang dikirim tidak lengkap atau salah format.")
	}

	lic, err := h.service.Activate(req)
	if err != nil {
		switch err {
		case ErrLicenseNotFound:
			return response.Error(c, fiber.StatusNotFound, err.Error())
		case ErrLicenseBanned, ErrLicenseUsed:
			return response.Error(c, fiber.StatusForbidden, err.Error())
		default:
			log.Println("ActivateError:", err)
			return response.Error(c, fiber.StatusInternalServerError, "Terjadi kesalahan pada server.")
		}
	}

	resData := LicenseResponseData{
		LicenseCode: lic.LicenseCode,
		TierLevel:   lic.TierLevel,
		MaxDevices:  lic.MaxDevices,
		MaxOutlets:  lic.MaxOutlets,
	}

	// Find the activation date of the current device from the list
	for _, dev := range lic.Devices {
		if dev.DeviceFingerprint == req.DeviceFingerprint {
			resData.ActivationDate = dev.ActivationDate.Format("2006-01-02T15:04:05Z")
			break
		}
	}

	return response.Success(c, fiber.StatusOK, "Lisensi berhasil diaktifkan untuk perangkat ini.", resData)
}

func (h *Handler) Verify(c *fiber.Ctx) error {
	var req VerifyRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format JSON tidak valid.")
	}
	if err := validate.Struct(req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Data yang dikirim tidak lengkap.")
	}

	isActive, err := h.service.Verify(req)
	if err != nil {
		switch err {
		case ErrLicenseNotFound:
			return response.Error(c, fiber.StatusNotFound, err.Error())
		case ErrLicenseBanned:
			return response.Error(c, fiber.StatusForbidden, err.Error())
		default:
			log.Println("VerifyError:", err)
			return response.Error(c, fiber.StatusInternalServerError, "Terjadi kesalahan pada server.")
		}
	}

	// Always true if no error, but defensive check
	return response.Success(c, fiber.StatusOK, "Lisensi Aktif.", VerifyResponseData{IsActive: isActive})
}

func (h *Handler) VerifyAccount(c *fiber.Ctx) error {
	var req VerifyAccountRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format JSON tidak valid.")
	}
	if err := validate.Struct(req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Data yang dikirim tidak lengkap.")
	}

	resData, err := h.service.VerifyAccount(req)
	if err != nil {
		if err.Error() == "Akun belum berlangganan. Hubungi Admin via WhatsApp untuk mengaktifkan." {
			return response.Error(c, fiber.StatusPaymentRequired, err.Error())
		}
		if err == ErrLicenseBanned || err == ErrLicenseUsed {
			return response.Error(c, fiber.StatusForbidden, err.Error())
		}
		log.Println("VerifyAccountError:", err)
		return response.Error(c, fiber.StatusInternalServerError, "Terjadi kesalahan pada server.")
	}

	return response.Success(c, fiber.StatusOK, "Lisensi berhasil diverifikasi.", resData)
}

func (h *Handler) Generate(c *fiber.Ctx) error {
	var req GenerateRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format JSON tidak valid.")
	}

	if err := validate.Struct(req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Data yang dikirim tidak lengkap atau salah format.")
	}

	lic, err := h.service.Generate(req)
	if err != nil {
		if err.Error() == "TierLevel tidak valid. Harus 'lite', 'pro', atau 'trial'." {
			return response.Error(c, fiber.StatusBadRequest, err.Error())
		}
		log.Println("GenerateError:", err)
		// Return detail error in response for debugging
		return response.Error(c, fiber.StatusInternalServerError, fmt.Sprintf("Gagal membuat lisensi: %v", err))
	}

	resData := GenerateResponseData{
		LicenseCode:   lic.LicenseCode,
		TierLevel:     lic.TierLevel,
		MaxDevices:    lic.MaxDevices,
		MaxOutlets:    lic.MaxOutlets,
		CustomerEmail: lic.CustomerEmail,
		UserID:        lic.UserID,
	}

	if lic.ExpiredAt != nil {
		resData.ExpiredAt = lic.ExpiredAt.Format("2006-01-02T15:04:05Z")
	}

	return response.Success(c, fiber.StatusCreated, "Lisensi berhasil dibuat.", resData)
}

func (h *Handler) Deregister(c *fiber.Ctx) error {
	var req DeregisterRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format JSON tidak valid.")
	}
	if err := validate.Struct(req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Data yang dikirim tidak lengkap.")
	}

	if err := h.service.Deregister(req); err != nil {
		if err == ErrLicenseNotFound {
			return response.Error(c, fiber.StatusNotFound, err.Error())
		}
		if err == ErrDeviceNotFound {
			return response.Error(c, fiber.StatusNotFound, err.Error())
		}
		return response.Error(c, fiber.StatusBadRequest, err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Perangkat berhasil dilepas.", nil)
}

func (h *Handler) GetDevices(c *fiber.Ctx) error {
	var req GetDevicesRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format JSON tidak valid.")
	}
	if err := validate.Struct(req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Data yang dikirim tidak lengkap.")
	}

	devices, err := h.service.GetDevices(req)
	if err != nil {
		if err == ErrLicenseNotFound {
			return response.Error(c, fiber.StatusNotFound, err.Error())
		}
		return response.Error(c, fiber.StatusBadRequest, err.Error())
	}

	resData := make([]DeviceResponse, len(devices))
	for i, d := range devices {
		resData[i] = DeviceResponse{
			DeviceFingerprint: d.DeviceFingerprint,
			DeviceModel:       d.DeviceModel,
			OsVersion:         d.OsVersion,
			ActivationDate:    d.ActivationDate.Format("2006-01-02T15:04:05Z"),
		}
	}

	return response.Success(c, fiber.StatusOK, "Berhasil mengambil daftar perangkat", resData)
}
