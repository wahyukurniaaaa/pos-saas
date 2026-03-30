package main

import (
	"log"
	"os"
	"posify-backend/internal/auth"
	"posify-backend/internal/fulfillment"
	"posify-backend/internal/license"
	"posify-backend/internal/middleware"
	"posify-backend/pkg/database"
	"posify-backend/pkg/mailer"
	"posify-backend/pkg/response"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/limiter"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/joho/godotenv"
)

func main() {
	// Initialize environment variables ASAP
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found. Using OS environment variables.")
	}

	app := fiber.New()

	// 1. STATIC FILES (ADMIN UI) - High Priority, register before groups
	if os.Getenv("APP_ENV") == "development" {
		adminPath := os.Getenv("ADMIN_PATH")
		if adminPath == "" {
			adminPath = "/admin"
		}

		// Serves files from ./public under the adminPath
		app.Static(adminPath, "./public", fiber.Static{
			Index: "index.html",
		})
		
		port := os.Getenv("PORT")
		if port == "" { port = "8080" }
		log.Printf("Admin UI enabled at http://localhost:%s%s/", port, adminPath)
	}

	// 2. Global Middlewares
	app.Use(logger.New())

	// CORS Configuration
	allowOrigins := os.Getenv("ALLOWED_ORIGINS")
	if allowOrigins == "" {
		allowOrigins = "*"
	}
	app.Use(cors.New(cors.Config{
		AllowOrigins:     allowOrigins,
		AllowMethods:     "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization, X-App-Client-Key, X-Admin-Secret-Key",
		AllowCredentials: allowOrigins != "*",
	}))

	// Rate Limiter
	limiterConf := limiter.New(limiter.Config{
		Max:        100,
		Expiration: 1 * time.Minute,
		KeyGenerator: func(c *fiber.Ctx) string {
			return c.IP()
		},
	})

	// Database Connection
	db := database.Connect()

	// API Groups
	api := app.Group("/api/v1")

	// Dependency Injection
	resendSvc := mailer.NewMailer()
	licenseRepo := license.NewRepository(db)
	licenseSvc := license.NewService(licenseRepo, resendSvc)
	licenseHandler := license.NewHandler(licenseSvc)

	// Port initialization
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// 10. Dependency Injection Fulfillment (Webhook)
	fulfillmentRepo := fulfillment.NewRepository(db)
	fulfillmentSvc := fulfillment.NewService(fulfillmentRepo, licenseSvc)
	fulfillmentHandler := fulfillment.NewHandler(fulfillmentSvc)

	// License Routes
	licenseRoutes := api.Group("/license", middleware.RequireAppClientKey, limiterConf)
	licenseHandler.RegisterRoutes(licenseRoutes)

	// Admin Routes (License Management)
	adminRoutes := api.Group("/admin/license", middleware.RequireAdminSecretKey, limiterConf)
	licenseHandler.RegisterAdminRoutes(adminRoutes)

	// Webhook Routes (No global secret middleware, handled internally via HMAC)
	webhookRoutes := api.Group("/webhooks")
	fulfillmentHandler.RegisterRoutes(webhookRoutes)

	// Auth Routes (Unified Registration / Login)
	authRepo := auth.NewRepository(db)
	authSvc := auth.NewService(authRepo, licenseSvc)
	authHandler := auth.NewHandler(authSvc)
	
	authRoutes := api.Group("/auth", limiterConf)
	authHandler.RegisterRoutes(authRoutes)

	// Special Admin Access for testing full flow from UI
	api.Post("/license/reset", middleware.RequireAdminSecretKey, licenseHandler.Deregister)
	api.Post("/license/verify", middleware.RequireAdminSecretKey, licenseHandler.Verify)
	api.Post("/license/activate", middleware.RequireAdminSecretKey, licenseHandler.Activate)

	// Health Check / Ping
	api.Get("/ping", func(c *fiber.Ctx) error {
		return response.Success(c, fiber.StatusOK, "POSify License API is running", nil)
	})

	log.Printf("Server starting on port %s", port)
	log.Fatal(app.Listen(":" + port))
}
