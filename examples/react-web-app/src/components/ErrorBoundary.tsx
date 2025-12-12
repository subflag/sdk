import { Component, ReactNode } from 'react';

interface ErrorBoundaryProps {
  children: ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

/**
 * ErrorBoundary catches React errors and displays a fallback UI
 * Demonstrates graceful error handling for production applications
 */
export default class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
    };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return {
      hasError: true,
      error,
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100vh',
          padding: '20px',
          textAlign: 'center',
        }}>
          <h1 style={{ color: '#dc2626', marginBottom: '10px' }}>
            ⚠️ Something went wrong
          </h1>
          <p style={{ marginBottom: '20px', color: '#666' }}>
            An unexpected error occurred. Please try refreshing the page.
          </p>
          <button
            onClick={() => window.location.reload()}
            style={{
              padding: '10px 20px',
              backgroundColor: '#7c3aed',
              color: 'white',
              border: 'none',
              borderRadius: '6px',
              fontSize: '16px',
              fontWeight: '600',
            }}
          >
            Reload Page
          </button>
          <details style={{
            marginTop: '30px',
            maxWidth: '600px',
            textAlign: 'left',
          }}>
            <summary style={{
              cursor: 'pointer',
              fontSize: '14px',
              color: '#666',
            }}>
              Error details
            </summary>
            <pre style={{
              marginTop: '10px',
              padding: '15px',
              backgroundColor: '#fef2f2',
              borderRadius: '8px',
              overflow: 'auto',
              fontSize: '12px',
            }}>
              {this.state.error?.toString()}
              {'\n\n'}
              {this.state.error?.stack}
            </pre>
          </details>
        </div>
      );
    }

    return this.props.children;
  }
}
