// Vercel serverless function entry point
// Re-exports the Express app for Vercel
const app = require('../src/index');

module.exports = app;
