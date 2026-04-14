package fulfillment

import (
	"errors"
	"fmt"
	"log"
	"posify-backend/internal/license"
)

type Service interface {
	ProcessTikTokOrder(payload TikTokWebhookPayload) error
	ProcessShopeeOrder(payload ShopeeWebhookPayload) error
}

type service struct {
	repo       Repository
	licenseSvc license.Service
}

func NewService(repo Repository, licenseSvc license.Service) Service {
	return &service{repo: repo, licenseSvc: licenseSvc}
}

func (s *service) ProcessTikTokOrder(payload TikTokWebhookPayload) error {
	// Hanya proses jika order menanti pengiriman atau selesai pembayarannya
	if payload.Data.OrderStatus != "AWAITING_SHIPMENT" && payload.Data.OrderStatus != "COMPLETED" {
		return nil // Abaikan status selain ini
	}

	orderID := payload.Data.OrderID
	source := "tiktok"

	// Cek duplikasi
	exists, err := s.repo.CheckOrderExists(orderID, source)
	if err != nil {
		return err
	}
	if exists {
		log.Printf("[TikTok] Order %s already processed.\n", orderID)
		return nil 
	}

	// TODO: Panggil TikTok Open API get_order_detail menggunakan orderID untuk mendapatkan SKU dan Email.
	// Untuk MVP/V1, kita hardcode atau mock email khusus karena TikTok menyensor email pembeli.
	mockSKU := "POS-LITE-TIKTOK" 
	mockEmail := fmt.Sprintf("buyer_%s@tiktok-dummy.posify", orderID) // Dummy email untuk klaim nanti

	return s.fulfillOrder(orderID, source, mockSKU, mockEmail)
}

func (s *service) ProcessShopeeOrder(payload ShopeeWebhookPayload) error {
	// Status "READY_TO_SHIP" atau ekivalen
	if payload.Data.Status != "READY_TO_SHIP" && payload.Data.Status != "COMPLETED" {
		return nil 
	}

	orderID := payload.Data.Ordersn
	source := "shopee"

	exists, err := s.repo.CheckOrderExists(orderID, source)
	if err != nil {
		return err
	}
	if exists {
		return nil
	}

	// TODO: Panggil Shopee Open API get_order_detail
	mockSKU := "POS-LITE-SHOPEE"
	mockEmail := fmt.Sprintf("buyer_%s@shopee-dummy.posify", orderID)

	return s.fulfillOrder(orderID, source, mockSKU, mockEmail)
}

func (s *service) fulfillOrder(orderID, source, sku, customerEmail string) error {
	mapping, err := s.repo.FindBySKU(sku)
	if err != nil {
		return err
	}
	if mapping == nil {
		// Bukan produk lisensi
		return errors.New("SKU not mapped")
	}

	req := license.GenerateRequest{
		TierLevel:     mapping.TierLevel,
		CustomerEmail: customerEmail,
		OrderID:       orderID,
		Source:        source,
	}

	_, err = s.licenseSvc.Generate(req)
	if err != nil {
		log.Printf("[%s] Failed to generate license for order %s: %v\n", source, orderID, err)
		return err
	}

	log.Printf("[%s] Successfully fulfilled order %s\n", source, orderID)
	return nil
}
