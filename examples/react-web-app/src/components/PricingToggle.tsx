import { useFeatureFlag } from '../hooks/useFeatureFlag';

/**
 * PricingToggle demonstrates A/B testing with string flags
 * Shows how to use flags to test different pricing presentations
 */
export default function PricingToggle() {
  const flags = useFeatureFlag();

  // STRING FLAG: Pricing variant
  const pricingVariant = flags.getString('pricing-variant', 'monthly');

  const pricingOptions = {
    monthly: {
      label: 'Monthly Billing',
      price: '$29',
      period: '/month',
      description: 'Pay as you go',
      color: '#7c3aed',
    },
    annual: {
      label: 'Annual Billing',
      price: '$290',
      period: '/year',
      description: 'Save $58 per year',
      color: '#059669',
    },
    lifetime: {
      label: 'Lifetime Access',
      price: '$499',
      period: 'one-time',
      description: 'Pay once, use forever',
      color: '#dc2626',
    },
  };

  const selectedPricing = pricingOptions[pricingVariant as keyof typeof pricingOptions] || pricingOptions.monthly;

  return (
    <div style={{
      backgroundColor: 'white',
      borderRadius: '8px',
      padding: '30px',
      boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
      maxWidth: '400px',
    }}>
      <div style={{
        textAlign: 'center',
        padding: '20px',
        backgroundColor: '#f9fafb',
        borderRadius: '8px',
        marginBottom: '20px',
      }}>
        <h3 style={{
          margin: '0 0 8px 0',
          color: selectedPricing.color,
          fontSize: '18px',
        }}>
          {selectedPricing.label}
        </h3>
        <div style={{ marginBottom: '8px' }}>
          <span style={{
            fontSize: '48px',
            fontWeight: 'bold',
            color: '#111',
          }}>
            {selectedPricing.price}
          </span>
          <span style={{
            fontSize: '18px',
            color: '#666',
            marginLeft: '4px',
          }}>
            {selectedPricing.period}
          </span>
        </div>
        <p style={{
          margin: 0,
          color: '#666',
          fontSize: '14px',
        }}>
          {selectedPricing.description}
        </p>
      </div>

      <button style={{
        width: '100%',
        padding: '14px',
        backgroundColor: selectedPricing.color,
        color: 'white',
        border: 'none',
        borderRadius: '6px',
        fontSize: '16px',
        fontWeight: '600',
      }}>
        Get Started
      </button>

      {/* Debug info */}
      <details style={{ marginTop: '20px', fontSize: '12px', color: '#666' }}>
        <summary style={{ cursor: 'pointer' }}>🔍 Current variant</summary>
        <pre style={{
          marginTop: '8px',
          padding: '8px',
          backgroundColor: '#f9fafb',
          borderRadius: '4px',
        }}>
          pricing-variant: "{pricingVariant}"
        </pre>
      </details>
    </div>
  );
}
