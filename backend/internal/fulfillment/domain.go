package fulfillment

// TikTokWebhookPayload represents the structure based on TikTok official docs
type TikTokWebhookPayload struct {
	Type              int    `json:"type"`
	TTSNotificationID string `json:"tts_notification_id"`
	ShopID            string `json:"shop_id"`
	Timestamp         int64  `json:"timestamp"`
	Data              struct {
		OrderID       string `json:"order_id"`
		OrderStatus   string `json:"order_status"`
		IsOnHoldOrder bool   `json:"is_on_hold_order"`
		UpdateTime    int64  `json:"update_time"`
	} `json:"data"`
}

// ShopeeWebhookPayload represents the structure based on Shopee push mechanism
type ShopeeWebhookPayload struct {
	ShopID    int64 `json:"shop_id"`
	Code      int   `json:"code"`
	Timestamp int64 `json:"timestamp"`
	Data      struct {
		Ordersn string `json:"ordersn"`
		Status  string `json:"status"`
	} `json:"data"`
}
