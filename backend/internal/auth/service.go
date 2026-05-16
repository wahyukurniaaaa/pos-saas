package auth

import (
	"errors"
	"posify-backend/internal/license"
	"posify-backend/internal/models"
	"posify-backend/pkg/uuidgen"

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

	// 4. Buat Store Profile dari data registrasi
	phone := req.Phone
	businessType := req.BusinessType
	profile := &models.StoreProfile{
		ID:           uuidgen.New(),
		Name:         req.StoreName,
		Phone:        &phone,
		BusinessType: &businessType,
	}
	// Non-fatal: jika gagal buat profil, akun tetap terbuat
	_ = s.repo.CreateStoreProfile(profile)

	res := &RegisterResponse{
		User: &user,
	}

	return res, nil
}
