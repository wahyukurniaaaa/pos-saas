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
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, X-App-Client-Key",
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

	// Protected Routes (Uses X-App-Client-Key and Limiter)
	licenseRoutes := api.Group("/license", middleware.RequireAppClientKey, limiterConf)
	licenseHandler.RegisterRoutes(licenseRoutes)

	// Admin Routes (Uses X-Admin-Secret-Key)
	adminRoutes := api.Group("/admin/license", middleware.RequireAdminSecretKey, limiterConf)
	licenseHandler.RegisterAdminRoutes(adminRoutes)

	// Health Check / Ping Endpoint
	api.Get("/ping", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "POSify License API is running",
		})
	})

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}
	log.Printf("Server starting on port %s", port)
	log.Fatal(app.Listen(":" + port))
}
