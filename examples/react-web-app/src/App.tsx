import { useState, useEffect } from 'react';
import { OpenFeature } from '@openfeature/web-sdk';
import { SubflagWebProvider } from '@subflag/openfeature-web-provider';
import ProductCard from './components/ProductCard';
import PricingToggle from './components/PricingToggle';
import ErrorBoundary from './components/ErrorBoundary';

const SUBFLAG_API_URL = import.meta.env.VITE_SUBFLAG_API_URL || 'http://localhost:8080';
const SUBFLAG_API_KEY = import.meta.env.VITE_SUBFLAG_API_KEY;

// Generate or retrieve a session ID for anonymous users
function getSessionId(): string {
  const key = 'subflag_session_id';
  let sessionId = sessionStorage.getItem(key);
  if (!sessionId) {
    sessionId = `session-${crypto.randomUUID()}`;
    sessionStorage.setItem(key, sessionId);
  }
  return sessionId;
}

function App() {
  const [isInitialized, setIsInitialized] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function initializeOpenFeature() {
      try {
        if (!SUBFLAG_API_KEY) {
          throw new Error('VITE_SUBFLAG_API_KEY environment variable is required. Copy .env.example to .env and add your API key.');
        }

        console.log('🚀 Initializing Subflag OpenFeature provider...');
        console.log(`   API URL: ${SUBFLAG_API_URL}`);
        console.log(`   API Key: ${SUBFLAG_API_KEY.substring(0, 15)}...`);

        const provider = new SubflagWebProvider({
          apiUrl: SUBFLAG_API_URL,
          apiKey: SUBFLAG_API_KEY,
        });

        // Set provider with initial context for targeting
        // The context is sent to the server to evaluate flags based on targeting rules
        await OpenFeature.setProviderAndWait(provider, {
          targetingKey: getSessionId(),
        });
        console.log('✅ OpenFeature provider initialized with session context');

        setIsInitialized(true);
      } catch (err) {
        console.error('❌ Failed to initialize OpenFeature provider:', err);
        setError(err instanceof Error ? err.message : String(err));
      }
    }

    initializeOpenFeature();
  }, []);

  if (error) {
    return (
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100vh',
        padding: '20px',
        textAlign: 'center',
      }}>
        <h1 style={{ color: '#dc2626', marginBottom: '10px' }}>❌ Initialization Error</h1>
        <p>Failed to initialize Subflag provider.</p>
        <pre style={{
          marginTop: '20px',
          padding: '15px',
          backgroundColor: '#fef2f2',
          borderRadius: '8px',
          textAlign: 'left',
          maxWidth: '600px',
          fontSize: '14px',
        }}>
          {error}
        </pre>
        <p style={{ marginTop: '20px', fontSize: '14px', color: '#666' }}>
          Make sure your Subflag server is running at <code>{SUBFLAG_API_URL}</code>
        </p>
      </div>
    );
  }

  if (!isInitialized) {
    return (
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100vh',
      }}>
        <div style={{
          border: '4px solid #f3f4f6',
          borderTopColor: '#7c3aed',
          borderRadius: '50%',
          width: '50px',
          height: '50px',
          animation: 'spin 1s linear infinite',
        }}></div>
        <p style={{ marginTop: '20px', color: '#666' }}>
          Initializing Subflag provider...
        </p>
      </div>
    );
  }

  return (
    <ErrorBoundary>
      <div style={{
        minHeight: '100vh',
        backgroundColor: '#f9fafb',
      }}>
        {/* Header */}
        <header style={{
          backgroundColor: '#7c3aed',
          color: 'white',
          padding: '20px',
          boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
        }}>
          <div style={{
            maxWidth: '1200px',
            margin: '0 auto',
          }}>
            <h1 style={{ margin: 0, fontSize: '24px' }}>🎯 Subflag React Example</h1>
            <p style={{ margin: '5px 0 0 0', opacity: 0.9, fontSize: '14px' }}>
              Feature flags powered by OpenFeature
            </p>
          </div>
        </header>

        {/* Main Content */}
        <main style={{
          maxWidth: '1200px',
          margin: '0 auto',
          padding: '40px 20px',
        }}>
          {/* Pricing Toggle Demo */}
          <section style={{ marginBottom: '40px' }}>
            <h2 style={{ marginBottom: '20px', color: '#111' }}>
              Pricing Toggle (String Flag)
            </h2>
            <PricingToggle />
          </section>

          {/* Products Demo */}
          <section>
            <h2 style={{ marginBottom: '20px', color: '#111' }}>
              Products (All Flag Types)
            </h2>
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
              gap: '20px',
            }}>
              <ProductCard
                id={1}
                name="Laptop Pro"
                description="High-performance laptop"
                basePrice={1299.99}
              />
              <ProductCard
                id={2}
                name="Wireless Mouse"
                description="Ergonomic wireless mouse"
                basePrice={49.99}
              />
              <ProductCard
                id={3}
                name="Mechanical Keyboard"
                description="RGB mechanical keyboard"
                basePrice={149.99}
              />
            </div>
          </section>
        </main>

        {/* Footer */}
        <footer style={{
          marginTop: '60px',
          padding: '20px',
          textAlign: 'center',
          color: '#666',
          fontSize: '14px',
        }}>
          <p>
            Powered by{' '}
            <a href="https://openfeature.dev" style={{ color: '#7c3aed' }}>
              OpenFeature
            </a>
            {' '}and{' '}
            <a href="https://github.com/subflag/subflag" style={{ color: '#7c3aed' }}>
              Subflag
            </a>
          </p>
        </footer>
      </div>
    </ErrorBoundary>
  );
}

export default App;
