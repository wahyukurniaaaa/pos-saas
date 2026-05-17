package license

const (
	TierTrial = "trial"
	TierLite  = "lite"
	TierPro   = "pro"
)

var TierDeviceLimit = map[string]int{
	TierTrial: 1,
	TierLite:  1,
	TierPro:   10,
}

var TierOutletLimit = map[string]int{
	TierTrial: 1,
	TierLite:  1,
	TierPro:   3,
}

type ActivateRequest struct {
	LicenseCode       string `json:"license_code" validate:"required"`
	DeviceFingerprint string `json:"device_fingerprint" validate:"required,max=100"`
	DeviceModel       string `json:"device_model"`
	OsVersion         string `json:"os_version"`
}

type VerifyRequest struct {
	LicenseCode       string `json:"license_code" validate:"required"`
	DeviceFingerprint string `json:"device_fingerprint" validate:"required"`
}

type LicenseResponseData struct {
	LicenseCode    string `json:"license_code"`
	ActivationDate string `json:"activation_date"`
	TierLevel      string `json:"tier_level"`
	MaxDevices     int    `json:"max_devices"`
	MaxOutlets     int    `json:"max_outlets"`
	ExpiredAt      string `json:"expired_at,omitempty"`
}

type VerifyResponseData struct {
	IsActive bool `json:"is_active"`
}

type VerifyAccountRequest struct {
	Email             string `json:"email" validate:"required,email"`
	UserID            string `json:"user_id"` // Optional backward compatibility
	DeviceFingerprint string `json:"device_fingerprint" validate:"required,max=100"`
	DeviceModel       string `json:"device_model"`
	OsVersion         string `json:"os_version"`
}

type VerifyAccountResponseData struct {
	IsActive    bool             `json:"is_active"`
	LicenseCode string           `json:"license_code"`
	TierLevel   string           `json:"tier_level"`
	MaxDevices  int              `json:"max_devices"`
	MaxOutlets  int              `json:"max_outlets"`
	ExpiredAt   string           `json:"expired_at,omitempty"`
	Devices     []DeviceResponse `json:"devices"`
}

type GenerateRequest struct {
	TierLevel      string `json:"tier_level" validate:"required"`
	CustomerEmail  string `json:"customer_email" validate:"required,email"`
	UserID         string `json:"user_id" validate:"required"`
	DurationMonths int    `json:"duration_months"` // 0 means lifetime (for lite) or 7 days (for trial)
	OrderID        string `json:"order_id"`
	Source         string `json:"source"`
}

type GenerateResponseData struct {
	LicenseCode   string `json:"license_code"`
	TierLevel     string `json:"tier_level"`
	MaxDevices    int    `json:"max_devices"`
	MaxOutlets    int    `json:"max_outlets"`
	CustomerEmail string `json:"customer_email"`
	UserID        string `json:"user_id"`
	ExpiredAt     string `json:"expired_at,omitempty"`
}

type DeregisterRequest struct {
	LicenseCode       string `json:"license_code" validate:"required"`
	CustomerEmail     string `json:"customer_email" validate:"required,email"`
	// Optional: if provided, only this device is unbound. If empty, all devices are reset.
	DeviceFingerprint string `json:"device_fingerprint"`
}

type GetDevicesRequest struct {
	LicenseCode   string `json:"license_code" validate:"required"`
	CustomerEmail string `json:"customer_email" validate:"required,email"`
}

type DeviceResponse struct {
	DeviceFingerprint string `json:"device_fingerprint"`
	DeviceModel       string `json:"device_model"`
	OsVersion         string `json:"os_version"`
	ActivationDate    string `json:"activation_date"`
}
