package mailer_test

import (
	"log"
	"os"
	"path/filepath"
	"posify-backend/pkg/mailer"
	"testing"

	"github.com/joho/godotenv"
)

func TestSendLiveEmail(t *testing.T) {
	// Load .env relative to the project root
	// We go up two levels from pkg/mailer/
	envPath := filepath.Join("..", "..", ".env")
	_ = godotenv.Load(envPath)

	apiKey := os.Getenv("RESEND_API_KEY")
	if apiKey == "" || apiKey == "re_your_api_key_here" {
		t.Skip("Skipping live email test: RESEND_API_KEY not configured with real key in .env")
	}

	m := mailer.NewMailer()
	err := m.SendLicenseEmail("wahyukurniaaaa@gmail.com", "POS-L1-TEST-EMAIL", "Premium - Testing", 5)
	if err != nil {
		t.Fatalf("Gagal mengirim email test: %v", err)
	}
	log.Println("Success: Email test berhasil dikirim ke wahyukurniaaaa@gmail.com")
}
