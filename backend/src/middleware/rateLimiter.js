// Rate Limiting Middleware for V-Serve ARTA API
// Provides system-wide protection against abuse and DDoS attacks

const rateLimit = require('express-rate-limit');

// Helper to get client identifier (IP or API key if present)
const getClientIdentifier = (req) => {
  // Check for API key in header (for future API key authentication)
  const apiKey = req.headers['x-api-key'];
  if (apiKey) {
    return `api:${apiKey}`;
  }
  
  // Use IP address (consider X-Forwarded-For for proxied requests)
  const forwarded = req.headers['x-forwarded-for'];
  const ip = forwarded ? forwarded.split(',')[0].trim() : req.ip;
  return `ip:${ip}`;
};

// Custom key generator for rate limiting
const keyGenerator = (req) => getClientIdentifier(req);

// Standard error response format
const createLimitHandler = (message) => (req, res) => {
  res.status(429).json({
    error: 'Too Many Requests',
    message: message,
    retryAfter: res.getHeader('Retry-After'),
  });
};

// =============================================================================
// RATE LIMIT CONFIGURATIONS
// =============================================================================

/**
 * Global Rate Limiter
 * Applies to all routes as a baseline protection
 * 1000 requests per 15 minutes per IP
 */
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Max 1000 requests per window
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  keyGenerator,
  handler: createLimitHandler('Too many requests. Please try again later.'),
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/ping' || req.path === '/health';
  },
});

/**
 * Authentication Rate Limiter
 * Stricter limits for login attempts to prevent brute force attacks
 * 10 attempts per 15 minutes per IP
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Max 10 login attempts per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator,
  handler: createLimitHandler('Too many login attempts. Please try again in 15 minutes.'),
  skipSuccessfulRequests: false, // Count all requests, not just failed ones
});

/**
 * Strict Authentication Rate Limiter
 * Even stricter for repeated failures (applied after failed attempts)
 * 5 attempts per 30 minutes per IP
 */
const strictAuthLimiter = rateLimit({
  windowMs: 30 * 60 * 1000, // 30 minutes
  max: 5, // Max 5 attempts per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator,
  handler: createLimitHandler('Account temporarily locked due to multiple failed login attempts. Please try again in 30 minutes.'),
});

/**
 * Feedback Submission Rate Limiter
 * Prevents spam submissions
 * 30 submissions per 15 minutes per IP
 */
const feedbackLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // Max 30 feedback submissions per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator,
  handler: createLimitHandler('Too many feedback submissions. Please wait before submitting more.'),
});

/**
 * User Management Rate Limiter
 * Protects user CRUD operations
 * 50 requests per 15 minutes per IP
 */
const userManagementLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // Max 50 user management requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator,
  handler: createLimitHandler('Too many user management requests. Please try again later.'),
});

/**
 * Read/Query Rate Limiter
 * For GET endpoints that fetch data
 * 200 requests per 15 minutes per IP
 */
const readLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // Max 200 read requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator,
  handler: createLimitHandler('Too many data requests. Please try again later.'),
});

/**
 * Write Rate Limiter
 * For POST/PUT/DELETE operations (excluding feedback and auth)
 * 100 requests per 15 minutes per IP
 */
const writeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Max 100 write requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator,
  handler: createLimitHandler('Too many write operations. Please try again later.'),
});

/**
 * Push Notification Rate Limiter
 * Prevents push notification spam
 * 20 requests per 15 minutes per IP
 */
const pushLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // Max 20 push requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator,
  handler: createLimitHandler('Too many push notification requests. Please try again later.'),
});

/**
 * Survey Config Rate Limiter
 * For survey configuration updates
 * 30 requests per 15 minutes per IP
 */
const surveyConfigLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // Max 30 config requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator,
  handler: createLimitHandler('Too many configuration requests. Please try again later.'),
});

/**
 * Burst Protection Limiter
 * Prevents sudden bursts of requests (short window)
 * 50 requests per 10 seconds per IP
 */
const burstLimiter = rateLimit({
  windowMs: 10 * 1000, // 10 seconds
  max: 50, // Max 50 requests per 10 seconds
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator,
  handler: createLimitHandler('Request rate too high. Please slow down.'),
  skip: (req) => {
    // Skip for health checks
    return req.path === '/ping' || req.path === '/health';
  },
});

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
  // Global limiters (apply to all routes)
  globalLimiter,
  burstLimiter,
  
  // Specific endpoint limiters
  authLimiter,
  strictAuthLimiter,
  feedbackLimiter,
  userManagementLimiter,
  readLimiter,
  writeLimiter,
  pushLimiter,
  surveyConfigLimiter,
  
  // Utility exports
  keyGenerator,
  getClientIdentifier,
};
