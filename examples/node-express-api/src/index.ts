import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { OpenFeature } from '@openfeature/server-sdk';
import { SubflagNodeProvider } from '@subflag/openfeature-node-provider';
import productsRouter from './routes/products.js';
import healthRouter from './routes/health.js';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;
const SUBFLAG_API_URL = process.env.SUBFLAG_API_URL || 'http://localhost:8080';
const SUBFLAG_API_KEY = process.env.SUBFLAG_API_KEY;

// Middleware
app.use(cors());
app.use(express.json());

// Validate required environment variables
if (!SUBFLAG_API_KEY) {
  console.error('❌ Error: SUBFLAG_API_KEY environment variable is required');
  console.error('   Please copy .env.example to .env and add your API key');
  process.exit(1);
}

// Initialize OpenFeature with Subflag provider
async function initializeOpenFeature() {
  try {
    // Narrow type for TypeScript - validated above
    const apiKey = SUBFLAG_API_KEY!;

    console.log('🚀 Initializing Subflag OpenFeature provider...');
    console.log(`   API URL: ${SUBFLAG_API_URL}`);
    console.log(`   API Key: ${apiKey.substring(0, 15)}...`);

    const provider = new SubflagNodeProvider({
      apiUrl: SUBFLAG_API_URL,
      apiKey: apiKey,
    });

    await OpenFeature.setProviderAndWait(provider);
    console.log('✅ OpenFeature provider initialized successfully');

    // Test connection with a simple flag evaluation
    const client = OpenFeature.getClient();
    const testFlag = await client.getBooleanValue('test-connection', false);
    console.log(`   Test flag evaluation: ${testFlag}`);
  } catch (error) {
    console.error('❌ Failed to initialize OpenFeature provider:', error);
    console.error('   Make sure your Subflag server is running at', SUBFLAG_API_URL);
    console.error('   and your API key is valid');
    process.exit(1);
  }
}

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Subflag Node.js Example API',
    version: '1.0.0',
    endpoints: {
      health: 'GET /api/health',
      products: 'GET /api/products',
      product: 'GET /api/products/:id',
    },
    documentation: 'See README.md for more information',
  });
});

app.use('/api/health', healthRouter);
app.use('/api/products', productsRouter);

// Error handling middleware
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('❌ Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message,
  });
});

// Start server
async function start() {
  try {
    await initializeOpenFeature();

    app.listen(PORT, () => {
      console.log('\n' + '='.repeat(60));
      console.log('🎉 Subflag Node.js Example Server');
      console.log('='.repeat(60));
      console.log(`📡 Server running at: http://localhost:${PORT}`);
      console.log(`🏥 Health check: http://localhost:${PORT}/api/health`);
      console.log(`📦 Products API: http://localhost:${PORT}/api/products`);
      console.log('='.repeat(60) + '\n');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

start();
