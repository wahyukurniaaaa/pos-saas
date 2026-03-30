package license

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
}

type VerifyResponseData struct {
	IsActive bool `json:"is_active"`
}

type GenerateRequest struct {
	TierLevel     string `json:"tier_level" validate:"required"`
	MaxDevices    int    `json:"max_devices" validate:"required,min=1"`
	CustomerEmail string `json:"customer_email" validate:"required,email"`
	OrderID       string `json:"order_id"`
	Source        string `json:"source"`
}

type GenerateResponseData struct {
	LicenseCode   string `json:"license_code"`
	TierLevel     string `json:"tier_level"`
	MaxDevices    int    `json:"max_devices"`
	CustomerEmail string `json:"customer_email"`
}

type DeregisterRequest struct {
	LicenseCode   string `json:"license_code" validate:"required"`
	CustomerEmail string `json:"customer_email" validate:"required,email"`
}
