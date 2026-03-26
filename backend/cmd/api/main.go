package main

import (
	"log"
	"os"
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
	// Initialize environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found. Using OS environment variables.")
	}

	app := fiber.New()

	// Global Middlewares
	app.Use(logger.New())

	// CORS Configuration
	// Fix panic: AllowCredentials cannot be true when AllowOrigins is "*"
	allowOrigins := os.Getenv("ALLOWED_ORIGINS")
	if allowOrigins == "" {
		allowOrigins = "*"
	}

	app.Use(cors.New(cors.Config{
		AllowOrigins:     allowOrigins,
		AllowMethods:     "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders:     "Origin,Content-Type,Accept,X-App-Client-Key,X-Admin-Secret-Key",
		ExposeHeaders:    "Content-Length",
		AllowCredentials: allowOrigins != "*",
	}))

	// API Routes Group
	api := app.Group("/api/v1")

	// Setup Database
	db := database.Connect()
	// if err := db.AutoMigrate(&models.License{}, &models.LicenseDevice{}); err != nil {
	// 	log.Fatal("Failed to run migrations:", err)
	// }

	// Rate Limiting settings specific for the Auth routes
	limiterConf := limiter.New(limiter.Config{
		Max:        5,
		Expiration: 1 * time.Minute,
		KeyGenerator: func(c *fiber.Ctx) string {
			return c.IP()
		},
		LimitReached: func(c *fiber.Ctx) error {
			return response.Error(c, fiber.StatusTooManyRequests, "Terlalu banyak percobaan. Coba lagi dalam 1 menit.")
		},
	})

	// Dependency Injection
	resendSvc := mailer.NewMailer()
	licenseRepo := license.NewRepository(db)
	licenseSvc := license.NewService(licenseRepo, resendSvc)
	licenseHandler := license.NewHandler(licenseSvc)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	// Protected Routes (Uses X-App-Client-Key and Limiter)
	licenseRoutes := api.Group("/license", middleware.RequireAppClientKey, limiterConf)
	licenseHandler.RegisterRoutes(licenseRoutes)

	// Admin Routes (Uses X-Admin-Secret-Key)
	adminRoutes := api.Group("/admin/license", middleware.RequireAdminSecretKey, limiterConf)
	licenseHandler.RegisterAdminRoutes(adminRoutes)

	// Add special access for Admin UI to test all license endpoints
	api.Post("/license/reset", middleware.RequireAdminSecretKey, licenseHandler.Deregister)
	api.Post("/license/verify", middleware.RequireAdminSecretKey, licenseHandler.Verify)
	api.Post("/license/activate", middleware.RequireAdminSecretKey, licenseHandler.Activate)

	// STATIC FILES (ADMIN UI)
	// Only serve in development mode for security
	if os.Getenv("APP_ENV") == "development" {
		adminPath := os.Getenv("ADMIN_PATH")
		if adminPath == "" {
			adminPath = "/admin"
		}

		// Add a redirect for the path without a trailing slash
		app.Get(adminPath, func(c *fiber.Ctx) error {
			return c.Redirect(adminPath + "/")
		})

		// Serves files from ./public under the adminPath
		app.Static(adminPath, "./public", fiber.Static{
			Index: "index.html",
		})
		log.Printf("Admin UI enabled at http://localhost:%s%s/", port, adminPath)
	}

	// Health Check / Ping Endpoint
	api.Get("/ping", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "POSify License API is running",
		})
	})

	log.Printf("Server starting on port %s", port)
	log.Fatal(app.Listen(":" + port))
}
