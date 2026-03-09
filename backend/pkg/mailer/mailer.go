package mailer

import (
	"fmt"
	"os"

	"github.com/resend/resend-go/v2"
)

type Mailer struct {
	client *resend.Client
	from   string
}

func NewMailer() *Mailer {
	apiKey := os.Getenv("RESEND_API_KEY")
	from := os.Getenv("EMAIL_FROM")
	if from == "" {
		from = "POSify <onboarding@resend.dev>" // Default Resend test email
	}

	return &Mailer{
		client: resend.NewClient(apiKey),
		from:   from,
	}
}

func (m *Mailer) SendLicenseEmail(to, licenseCode, tier string, maxDevices int) error {
	// Colors from mobile/lib/core/theme/app_theme.dart:
	// primaryColor: #1A237E
	// textPrimary: #0F172A
	// textSecondary: #64748B
	// backgroundLight: #F6F6F8
	// borderColor: #E2E8F0

	htmlContent := fmt.Sprintf(`
		<!DOCTYPE html>
		<html>
		<body style="margin: 0; padding: 0; background-color: #F6F6F8; font-family: 'Inter', Helvetica, Arial, sans-serif; color: #0F172A;">
			<table width="100%%" border="0" cellspacing="0" cellpadding="0" style="background-color: #F6F6F8; padding: 40px 20px;">
				<tr>
					<td align="center">
						<table width="100%%" style="max-width: 550px; background-color: #FFFFFF; border: 1px solid #E2E8F0; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);">
							<!-- Header: Brand Indigo -->
							<tr>
								<td style="padding: 48px 48px 32px 48px; text-align: left;">
									<div style="font-size: 13px; letter-spacing: 0.1em; color: #1A237E; font-weight: 700; text-transform: uppercase; margin-bottom: 24px;">
										Konfirmasi Lisensi — POSify
									</div>
									<h1 style="font-size: 32px; font-weight: 800; line-height: 1.2; margin: 0; color: #0F172A; letter-spacing: -0.01em;">
										Aktivasi Premium <br/>Siap Digunakan.
									</h1>
								</td>
							</tr>
							
							<!-- Content -->
							<tr>
								<td style="padding: 0 48px 48px 48px;">
									<p style="font-size: 16px; line-height: 1.6; color: #64748B; margin: 0 0 32px 0;">
										Terima kasih telah memilih POSify. Berikut adalah detail lisensi eksklusif untuk akun Anda.
									</p>
									
									<div style="background-color: #F8FAFC; border: 2px dashed #E2E8F0; padding: 32px; text-align: center; border-radius: 8px;">
										<div style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.15em; color: #94A3B8; margin-bottom: 12px; font-weight: 600;">License Key Anda</div>
										<div style="font-size: 24px; font-family: 'Courier New', monospace; font-weight: 700; color: #1A237E; letter-spacing: 0.05em;">%s</div>
									</div>

									<!-- Specs Section -->
									<div style="margin-top: 32px; border: 1px solid #F1F5F9; border-radius: 8px; padding: 16px;">
										<table width="100%%">
											<tr>
												<td style="padding: 8px 0; font-size: 14px; color: #64748B;">Level Paket</td>
												<td align="right" style="padding: 8px 0; font-size: 14px; color: #0F172A; font-weight: 700;">%s</td>
											</tr>
											<tr>
												<td style="padding: 8px 0; font-size: 14px; color: #64748B;">Batas Perangkat</td>
												<td align="right" style="padding: 8px 0; font-size: 14px; color: #0F172A; font-weight: 700;">%d Perangkat</td>
											</tr>
										</table>
									</div>

									<div style="margin-top: 40px; text-align: center;">
										<a href="#" style="display: inline-block; background-color: #1A237E; color: #FFFFFF; text-decoration: none; padding: 18px 40px; font-size: 15px; font-weight: 700; border-radius: 8px; box-shadow: 0 10px 15px -3px rgba(26, 35, 126, 0.2);">
											Aktivasi Sekarang
										</a>
									</div>
								</td>
							</tr>

							<!-- Footer -->
							<tr>
								<td style="padding: 40px; background-color: #F8FAFC; border-top: 1px solid #E2E8F0; text-align: center;">
									<p style="font-size: 11px; line-height: 1.6; color: #94A3B8; margin: 0;">
										&copy; 2026 POSify Core. Dikirim otomatis oleh sistem lisensi kami.<br/>
										Jika ada pertanyaan, hubungi tim support kami.
									</p>
								</td>
							</tr>
						</table>
					</td>
				</tr>
			</table>
		</body>
		</html>
	`, licenseCode, tier, maxDevices)

	params := &resend.SendEmailRequest{
		From:    m.from,
		To:      []string{to},
		Subject: "POSify: Kode Lisensi Anda Telah Tersedia",
		Html:    htmlContent,
	}

	_, err := m.client.Emails.Send(params)
	if err != nil {
		return fmt.Errorf("failed to send email via resend: %w", err)
	}

	return nil
}
