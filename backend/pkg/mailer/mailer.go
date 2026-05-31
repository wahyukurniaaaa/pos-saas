package mailer

import (
	"fmt"
	"os"

	"github.com/resend/resend-go/v2"
)

type Mailer struct {
	client *resend.Client
	from   string
	portal string
}

func NewMailer() *Mailer {
	apiKey := os.Getenv("RESEND_API_KEY")
	from := os.Getenv("EMAIL_FROM")
	if from == "" {
		from = "Lumio POS <onboarding@resend.dev>" // Default Resend test email
	}
	portal := os.Getenv("PORTAL_URL")
	if portal == "" {
		portal = "https://lumio.wahyukurnia.com"
	}

	return &Mailer{
		client: resend.NewClient(apiKey),
		from:   from,
		portal: portal,
	}
}

func (m *Mailer) SendLicenseEmail(to, licenseCode, tier string, maxDevices int, expiredAt string, amount float64, paymentMethod string) error {
	// Colors from Lumio Brand:
	// Navy (Primary): #0F2F62
	// Cyan (Accent): #08ABE6
	// Background: #F8FAFC

	if expiredAt == "" {
		expiredAt = "Selamanya (Lifetime)"
	}

	// Build payment invoice block (only shown when amount is provided)
	invoiceBlock := ""
	if amount > 0 {
		pmLabel := paymentMethod
		if pmLabel == "" {
			pmLabel = "-"
		}
		invoiceBlock = fmt.Sprintf(`
			<div style="margin-top: 24px; background: linear-gradient(135deg, #ECFDF5 0%%, #D1FAE5 100%%); border: 1px solid #6EE7B7; border-radius: 16px; padding: 24px;">
				<div style="font-size: 12px; text-transform: uppercase; letter-spacing: 0.12em; color: #059669; font-weight: 700; margin-bottom: 16px;">Ringkasan Pembayaran</div>
				<table width="100%%" border="0" cellspacing="0" cellpadding="0">
					<tr>
						<td style="padding-bottom: 10px; font-size: 14px; color: #374151;">Total Pembayaran</td>
						<td align="right" style="padding-bottom: 10px; font-size: 18px; color: #065F46; font-weight: 800;">Rp %s</td>
					</tr>
					<tr>
						<td style="padding-top: 10px; border-top: 1px solid #A7F3D0; font-size: 14px; color: #374151;">Metode Pembayaran</td>
						<td align="right" style="padding-top: 10px; border-top: 1px solid #A7F3D0; font-size: 14px; color: #065F46; font-weight: 700;">%s</td>
					</tr>
				</table>
			</div>`, formatRupiah(int64(amount)), pmLabel)
	}

	logoURL := fmt.Sprintf("%s/logo-wordmark-primary.png", m.portal)

	htmlContent := fmt.Sprintf(`
		<!DOCTYPE html>
		<html>
		<head>
			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1.0">
			<title>Aktivasi Akun Lumio POS</title>
		</head>
		<body style="margin: 0; padding: 0; background-color: #F8FAFC; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #1B2A44;">
			<table width="100%%" border="0" cellspacing="0" cellpadding="0" style="background-color: #F8FAFC; padding: 40px 20px;">
				<tr>
					<td align="center">
						<table width="100%%" style="max-width: 600px; background-color: #FFFFFF; border: 1px solid #E2E8F0; border-radius: 24px; overflow: hidden; box-shadow: 0 10px 25px -5px rgba(15, 47, 98, 0.1);">
							<!-- Header -->
							<tr>
								<td style="padding: 48px 48px 32px 48px; text-align: center;">
									<div style="margin-bottom: 24px; text-align: center;">
										<img src="%s" alt="Lumio POS" style="height: 32px; max-width: 100%%; object-fit: contain; margin: 0 auto; display: block;" />
									</div>
									<h1 style="font-size: 24px; font-weight: 800; line-height: 1.3; margin: 0; color: #0F2F62;">
										Akun Anda Kini <br/>Sudah Premium!
									</h1>
								</td>
							</tr>
							
							<!-- Main Content -->
							<tr>
								<td style="padding: 0 48px 40px 48px;">
									<p style="font-size: 16px; line-height: 1.6; color: #475569; margin: 0 0 32px 0; text-align: center;">
										Kabar baik! Paket <strong>%s</strong> telah berhasil diaktifkan untuk akun Anda. Nikmati kemudahan mengelola bisnis dengan fitur terlengkap dari Lumio POS.
									</p>
									
									<div style="background: linear-gradient(135deg, #0F2F62 0%%, #1B2A44 100%%); padding: 32px; text-align: center; border-radius: 20px;">
										<div style="font-size: 12px; text-transform: uppercase; letter-spacing: 0.15em; color: #08ABE6; margin-bottom: 8px; font-weight: 700;">Status Aktivasi</div>
										<div style="font-size: 24px; font-weight: 800; color: #FFFFFF;">Otomatis Aktif</div>
										<p style="font-size: 13px; color: #CBD5E1; margin: 8px 0 0 0;">Cukup login ke aplikasi Lumio POS untuk mulai.</p>
									</div>

									<!-- Invoice / Payment Summary -->
									%s

									<!-- Specs Table -->
									<div style="margin-top: 24px; background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 16px; padding: 24px;">
										<table width="100%%" border="0" cellspacing="0" cellpadding="0">
											<tr>
												<td style="padding-bottom: 12px; font-size: 14px; color: #64748B;">Email Terdaftar</td>
												<td align="right" style="padding-bottom: 12px; font-size: 14px; color: #0F2F62; font-weight: 700;">%s</td>
											</tr>
											<tr>
												<td style="padding: 12px 0; border-top: 1px solid #F1F5F9; font-size: 14px; color: #64748B;">Batas Perangkat</td>
												<td align="right" style="padding: 12px 0; border-top: 1px solid #F1F5F9; font-size: 14px; color: #0F2F62; font-weight: 700;">%d Unit</td>
											</tr>
											<tr>
												<td style="padding-top: 12px; border-top: 1px solid #F1F5F9; font-size: 14px; color: #64748B;">Masa Aktif Hingga</td>
												<td align="right" style="padding-top: 12px; border-top: 1px solid #F1F5F9; font-size: 14px; color: #08ABE6; font-weight: 700;">%s</td>
											</tr>
										</table>
									</div>

									<div style="margin-top: 40px; text-align: center;">
										<a href="https://wa.me/628123456789" style="display: inline-block; background-color: #08ABE6; color: #FFFFFF; text-decoration: none; padding: 16px 32px; font-size: 15px; font-weight: 700; border-radius: 12px; box-shadow: 0 4px 14px 0 rgba(8, 171, 230, 0.39);">
											Hubungi Tim Support
										</a>
										<p style="margin-top: 16px; font-size: 12px; color: #94A3B8;">
											ID Transaksi: <span style="font-family: monospace;">%s</span>
										</p>
									</div>
								</td>
							</tr>

							<!-- Footer -->
							<tr>
								<td style="padding: 32px 48px; background-color: #F8FAFC; border-top: 1px solid #E2E8F0; text-align: center;">
									<p style="font-size: 12px; line-height: 1.6; color: #94A3B8; margin: 0;">
										&copy; 2026 <strong>Lumio Indonesia</strong>. Seluruh hak cipta dilindungi.<br/>
										Email ini dikirim otomatis, mohon tidak membalas email ini.
									</p>
								</td>
							</tr>
						</table>
					</td>
				</tr>
			</table>
		</body>
		</html>
	`, logoURL, tier, invoiceBlock, to, maxDevices, expiredAt, licenseCode)

	params := &resend.SendEmailRequest{
		From:    m.from,
		To:      []string{to},
		Subject: "Lumio POS: Akun Premium Anda Telah Aktif!",
		Html:    htmlContent,
	}

	_, err := m.client.Emails.Send(params)
	if err != nil {
		return fmt.Errorf("failed to send email via resend: %w", err)
	}

	return nil
}

// formatRupiah formats an integer as Indonesian Rupiah with thousand separators.
// e.g. 1500000 → "1.500.000"
func formatRupiah(amount int64) string {
	s := fmt.Sprintf("%d", amount)
	result := make([]byte, 0, len(s)+len(s)/3)
	offset := len(s) % 3
	for i, c := range s {
		if i > 0 && (i-offset)%3 == 0 {
			result = append(result, '.')
		}
		result = append(result, byte(c))
	}
	return string(result)
}
