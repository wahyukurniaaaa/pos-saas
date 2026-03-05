package license

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"posify-backend/internal/models"
)

var (
	ErrLicenseNotFound = errors.New("Kode lisensi tidak ditemukan atau format salah.")
	ErrLicenseUsed     = errors.New("Lisensi ini sudah diaktifkan di perangkat lain. Silakan hubungi CS untuk reset perangkat.")
	ErrLicenseBanned   = errors.New("Lisensi telah diblokir/disuspend.")
)

type Service interface {
	Activate(req ActivateRequest) (*models.License, error)
	Verify(req VerifyRequest) (bool, error)
	Generate(req GenerateRequest) (*models.License, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
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

	// 3. Check Fingerprint Logic
	if lic.DeviceFingerprint != nil {
		// Already activated by someone. Is it the same device trying to re-activate (e.g., cleared app data)?
		if *lic.DeviceFingerprint != req.DeviceFingerprint {
			return nil, ErrLicenseUsed
		}
		// If same fingerprint, just return success (idempotent)
		return lic, nil
	}

	// 4. First time activation! Bind it.
	now := time.Now()
	lic.DeviceFingerprint = &req.DeviceFingerprint
	lic.DeviceModel = &req.DeviceModel
	lic.OsVersion = &req.OsVersion
	lic.ActivationDate = &now

	// 5. Save to DB
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
	// Must exactly match
	if lic == nil || lic.DeviceFingerprint == nil || *lic.DeviceFingerprint != req.DeviceFingerprint {
		return false, ErrLicenseNotFound
	}
	
	if !lic.IsActive {
		return false, ErrLicenseBanned
	}

	return true, nil
}

// Generate creates a new random license code
func (s *service) Generate(req GenerateRequest) (*models.License, error) {
	// Generate format POS-L1-XXXXX-XXXXX
	bytes := make([]byte, 5)
	if _, err := rand.Read(bytes); err != nil {
		return nil, err
	}
	part1 := strings.ToUpper(hex.EncodeToString(bytes))
	
	bytes2 := make([]byte, 5)
	if _, err := rand.Read(bytes2); err != nil {
		return nil, err
	}
	part2 := strings.ToUpper(hex.EncodeToString(bytes2))
	
	code := fmt.Sprintf("POS-L1-%s-%s", part1, part2)

	license := &models.License{
		LicenseCode: code,
		TierLevel:   req.TierLevel,
		MaxDevices:  req.MaxDevices,
		IsActive:    true,
	}

	if err := s.repo.Create(license); err != nil {
		return nil, err
	}

	return license, nil
}
