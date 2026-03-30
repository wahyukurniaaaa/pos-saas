package auth

import (
	"errors"
	"posify-backend/internal/license"
	"posify-backend/internal/models"

	"golang.org/x/crypto/bcrypt"
)

type service struct {
	repo       Repository
	licenseSvc license.Service
}

func NewService(repo Repository, licenseSvc license.Service) Service {
	return &service{repo, licenseSvc}
}

func (s *service) RegisterWithLicense(req RegisterRequest) (*RegisterResponse, error) {
	// 1. Cek User Existing
	existingUser, err := s.repo.FindByEmail(req.Email)
	if err != nil {
		return nil, err
	}
	if existingUser != nil {
		return nil, errors.New("email sudah terdaftar, silakan login")
	}

	// 2. Hash Password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, errors.New("gagal memproses password")
	}

	// 3. Buat User
	user := models.User{
		Email:        req.Email,
		PasswordHash: string(hashedPassword),
		Status:       "active",
	}
	if err := s.repo.CreateUser(&user); err != nil {
		return nil, errors.New("gagal membuat akun")
	}

	res := &RegisterResponse{
		User: &user,
	}

	// 4. Proses Lisensi (Jika disediakan)
	if req.LicenseCode != "" && req.DeviceFingerprint != "" {
		actRes, err := s.licenseSvc.Activate(license.ActivateRequest{
			LicenseCode:       req.LicenseCode,
			DeviceFingerprint: req.DeviceFingerprint,
			DeviceModel:       "Unified Registration",
			OsVersion:         "N/A",
		})
		
		if err != nil {
			// Kita biarkan user terbuat, tapi error lisensi akan dilampirkan/ditangani
			// Agar akun tidak fail-to-create hanya krn salah ketik lisensi
			return res, errors.New("akun berhasil dibuat, tapi aktivasi lisensi gagal: " + err.Error())
		}
		res.License = actRes
	}

	return res, nil
}
