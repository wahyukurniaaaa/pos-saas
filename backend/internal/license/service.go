package license

import (
	"crypto/rand"
	"errors"
	"fmt"
	"time"

	"posify-backend/internal/models"
	"posify-backend/pkg/mailer"
)

var (
	ErrLicenseNotFound  = errors.New("Kode lisensi tidak ditemukan atau format salah.")
	ErrLicenseUsed      = errors.New("Batas maksimum perangkat telah tercapai. Silakan lepas perangkat lama melalui menu Pengaturan > Manajemen Perangkat.")
	ErrLicenseBanned    = errors.New("Lisensi telah diblokir/disuspend.")
	ErrDeviceNotFound   = errors.New("Perangkat dengan fingerprint tersebut tidak ditemukan pada lisensi ini.")
)

func generate10DigitCode() (string, error) {
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	bytes := make([]byte, 10)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	for i, b := range bytes {
		bytes[i] = charset[b%byte(len(charset))]
	}
	return string(bytes), nil
}

type Service interface {
	Activate(req ActivateRequest) (*models.License, error)
	Verify(req VerifyRequest) (bool, error)
	VerifyAccount(req VerifyAccountRequest) (*VerifyAccountResponseData, error)
	Generate(req GenerateRequest) (*models.License, error)
	Deregister(req DeregisterRequest) error
	GetDevices(req GetDevicesRequest) ([]models.LicenseDevice, error)
}

type service struct {
	repo   Repository
	mailer *mailer.Mailer
}

func NewService(repo Repository, mailer *mailer.Mailer) Service {
	return &service{repo: repo, mailer: mailer}
}

func (s *service) Activate(req ActivateRequest) (*models.License, error) {
	// 1. Find License
	lic, err := s.repo.FindByCode(req.LicenseCode)
	if err != nil {
		return nil, err
	}
	if lic == nil {
		return nil, ErrLicenseNotFound
	}

	// 2. Check if banned
	if !lic.IsActive {
		return nil, ErrLicenseBanned
	}

	// 3. Check Multi-Device Logic
	now := time.Now()
	var associatedDevice *models.LicenseDevice
	for i := range lic.Devices {
		if lic.Devices[i].DeviceFingerprint == req.DeviceFingerprint {
			associatedDevice = &lic.Devices[i]
			break
		}
	}

	if associatedDevice != nil {
		// Already activated by THIS device. Update LastVerifiedAt and return.
		associatedDevice.LastVerifiedAt = now
		associatedDevice.DeviceModel = req.DeviceModel
		associatedDevice.OsVersion = req.OsVersion
		if err := s.repo.UpdateDevice(associatedDevice); err != nil {
			return nil, err
		}
		return lic, nil
	}

	// 4. New device is trying to activate. Check limit.
	if len(lic.Devices) >= lic.MaxDevices {
		return nil, ErrLicenseUsed
	}

	// 5. Add new device
	newDevice := models.LicenseDevice{
		LicenseID:         lic.ID,
		DeviceFingerprint: req.DeviceFingerprint,
		DeviceModel:       req.DeviceModel,
		OsVersion:         req.OsVersion,
		ActivationDate:    now,
		LastVerifiedAt:    now,
	}

	// In GORM, adding to slice and updating parent works if configured,
	// but we'll use UpdateDevice or just save the parent if it cascades.
	// Since we preloaded, adding to the slice and saving the parent is usually standard.
	lic.Devices = append(lic.Devices, newDevice)
	if err := s.repo.Update(lic); err != nil {
		return nil, err
	}

	return lic, nil
}

func (s *service) Verify(req VerifyRequest) (bool, error) {
	lic, err := s.repo.FindByCode(req.LicenseCode)
	if err != nil {
		return false, err
	}
	if lic == nil {
		return false, ErrLicenseNotFound
	}

	if !lic.IsActive {
		return false, ErrLicenseBanned
	}

	if lic.ExpiredAt != nil && time.Now().After(*lic.ExpiredAt) {
		return false, errors.New("Lisensi Anda telah kedaluwarsa.")
	}

	// Find the device
	var associatedDevice *models.LicenseDevice
	for i := range lic.Devices {
		if lic.Devices[i].DeviceFingerprint == req.DeviceFingerprint {
			associatedDevice = &lic.Devices[i]
			break
		}
	}

	if associatedDevice == nil {
		return false, ErrLicenseNotFound // Device not registered for this license
	}

	// Update verification timestamp
	associatedDevice.LastVerifiedAt = time.Now()
	if err := s.repo.UpdateDevice(associatedDevice); err != nil {
		return false, err
	}

	return true, nil
}

func (s *service) VerifyAccount(req VerifyAccountRequest) (*VerifyAccountResponseData, error) {
	var lic *models.License
	var err error

	if req.UserID != "" {
		lic, err = s.repo.FindByUserID(req.UserID)
	}
	
	if lic == nil && req.Email != "" {
		lic, err = s.repo.FindByEmail(req.Email)
	}

	if err != nil {
		return nil, err
	}
	if lic == nil {
		return nil, errors.New("Akun belum berlangganan. Hubungi Admin via WhatsApp untuk mengaktifkan.")
	}

	if !lic.IsActive {
		return nil, ErrLicenseBanned
	}

	now := time.Now()
	if lic.ExpiredAt != nil && now.After(*lic.ExpiredAt) {
		return nil, errors.New("Lisensi Anda telah kedaluwarsa. Hubungi Admin untuk perpanjangan.")
	}

	var associatedDevice *models.LicenseDevice
	for i := range lic.Devices {
		if lic.Devices[i].DeviceFingerprint == req.DeviceFingerprint {
			associatedDevice = &lic.Devices[i]
			break
		}
	}

	if associatedDevice != nil {
		associatedDevice.LastVerifiedAt = now
		associatedDevice.DeviceModel = req.DeviceModel
		associatedDevice.OsVersion = req.OsVersion
		if err := s.repo.UpdateDevice(associatedDevice); err != nil {
			return nil, err
		}
	} else {
		// New device
		if len(lic.Devices) >= lic.MaxDevices {
			return nil, ErrLicenseUsed
		}
		newDevice := models.LicenseDevice{
			LicenseID:         lic.ID,
			DeviceFingerprint: req.DeviceFingerprint,
			DeviceModel:       req.DeviceModel,
			OsVersion:         req.OsVersion,
			ActivationDate:    now,
			LastVerifiedAt:    now,
		}
		lic.Devices = append(lic.Devices, newDevice)
		if err := s.repo.Update(lic); err != nil {
			return nil, err
		}
	}

	devicesResponse := make([]DeviceResponse, len(lic.Devices))
	for i, d := range lic.Devices {
		devicesResponse[i] = DeviceResponse{
			DeviceFingerprint: d.DeviceFingerprint,
			DeviceModel:       d.DeviceModel,
			OsVersion:         d.OsVersion,
			ActivationDate:    d.ActivationDate.Format(time.RFC3339),
		}
	}

	res := &VerifyAccountResponseData{
		IsActive:    lic.IsActive,
		LicenseCode: lic.LicenseCode,
		TierLevel:   lic.TierLevel,
		MaxDevices:  lic.MaxDevices,
		MaxOutlets:  lic.MaxOutlets,
		Devices:     devicesResponse,
	}

	if lic.ExpiredAt != nil {
		res.ExpiredAt = lic.ExpiredAt.Format(time.RFC3339)
	}

	return res, nil
}

// Generate creates a new random license code
func (s *service) Generate(req GenerateRequest) (*models.License, error) {
	// Validate Tier
	maxDevices, ok := TierDeviceLimit[req.TierLevel]
	if !ok {
		return nil, errors.New("TierLevel tidak valid. Harus 'lite', 'pro', atau 'trial'.")
	}
	maxOutlets := TierOutletLimit[req.TierLevel]

	var code string
	var err error
	
	// Retry loop to ensure uniqueness
	for i := 0; i < 3; i++ {
		code, err = generate10DigitCode()
		if err != nil {
			return nil, err
		}
		
		existing, _ := s.repo.FindByCode(code)
		if existing == nil {
			break
		}
		if i == 2 {
			return nil, errors.New("gagal membuat kode unik setelah beberapa percobaan")
		}
	}

	source := req.Source
	if source == "" {
		source = "manual"
	}

	var expiredAt *time.Time
	if req.TierLevel == TierTrial {
		exp := time.Now().AddDate(0, 0, 7)
		expiredAt = &exp
	} else if req.TierLevel == TierPro && req.DurationMonths > 0 {
		exp := time.Now().AddDate(0, req.DurationMonths, 0)
		expiredAt = &exp
	}

	license := &models.License{
		LicenseCode:   code,
		TierLevel:     req.TierLevel,
		MaxDevices:    maxDevices,
		MaxOutlets:    maxOutlets,
		CustomerEmail: req.CustomerEmail,
		UserID:        req.UserID,
		ExpiredAt:     expiredAt,
		IsActive:      true,
		OrderID:       req.OrderID,
		Source:        source,
	}

	if err := s.repo.Create(license); err != nil {
		return nil, err
	}

	// Send Email Async
	if s.mailer != nil {
		go func() {
			expiredAtStr := ""
			if license.ExpiredAt != nil {
				expiredAtStr = license.ExpiredAt.Format("02 January 2006")
			}
			if err := s.mailer.SendLicenseEmail(req.CustomerEmail, code, req.TierLevel, maxDevices, expiredAtStr); err != nil {
				fmt.Printf("Email error for %s: %v\n", req.CustomerEmail, err)
			}
		}()
	}

	return license, nil
}

func (s *service) Deregister(req DeregisterRequest) error {
	lic, err := s.repo.FindByCode(req.LicenseCode)
	if err != nil {
		return err
	}
	if lic == nil {
		return ErrLicenseNotFound
	}

	if lic.CustomerEmail != req.CustomerEmail {
		return errors.New("Email tidak cocok dengan lisensi ini.")
	}

	// Selective reset: only remove the specified device.
	if req.DeviceFingerprint != "" {
		// Verify the device actually belongs to this license before attempting deletion.
		deviceExists := false
		for _, d := range lic.Devices {
			if d.DeviceFingerprint == req.DeviceFingerprint {
				deviceExists = true
				break
			}
		}
		if !deviceExists {
			return ErrDeviceNotFound
		}
		return s.repo.DeleteDevice(lic.ID, req.DeviceFingerprint)
	}

	// Full reset: remove all devices (legacy behavior).
	return s.repo.ClearDevices(lic.ID)
}

func (s *service) GetDevices(req GetDevicesRequest) ([]models.LicenseDevice, error) {
	lic, err := s.repo.FindByCode(req.LicenseCode)
	if err != nil {
		return nil, err
	}
	if lic == nil {
		return nil, ErrLicenseNotFound
	}
	
	if lic.CustomerEmail != req.CustomerEmail {
		return nil, errors.New("Email tidak cocok dengan lisensi ini.")
	}

	return lic.Devices, nil
}
