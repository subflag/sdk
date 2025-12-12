import { useFeatureFlag } from '../hooks/useFeatureFlag';

interface ProductCardProps {
  id: number;
  name: string;
  description: string;
  basePrice: number;
}

/**
 * ProductCard demonstrates all 5 OpenFeature flag types:
 * - Boolean: Feature toggles (checkout enabled)
 * - String: Dynamic text (button labels)
 * - Integer: Numeric limits (stock quantity)
 * - Double: Pricing multipliers (discount rate)
 * - Object: Complex configuration (theme settings)
 */
export default function ProductCard({ name, description, basePrice }: ProductCardProps) {
  const flags = useFeatureFlag();

  // BOOLEAN FLAG: Feature toggle for checkout
  const checkoutEnabled = flags.getBoolean('enable-checkout', false);

  // STRING FLAG: Dynamic button text
  const buttonText = flags.getString('button-text', 'View Details');

  // INTEGER FLAG: Stock quantity limit
  const stockLimit = flags.getNumber('stock-limit', 100);

  // DOUBLE FLAG: Discount multiplier (0.0 to 1.0)
  const discountRate = flags.getNumber('discount-rate', 0.0);

  // OBJECT FLAG: Theme configuration
  const themeConfig = flags.getObject<{
    primaryColor?: string;
    showBadge?: boolean;
  }>('theme-config', {
    primaryColor: '#7c3aed',
    showBadge: false,
  });

  // Calculate discounted price
  const discountedPrice = basePrice * (1 - discountRate);
  const hasDiscount = discountRate > 0;

  return (
    <div style={{
      backgroundColor: 'white',
      borderRadius: '8px',
      padding: '20px',
      boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
      position: 'relative',
    }}>
      {/* Badge (OBJECT FLAG: showBadge) */}
      {themeConfig.showBadge && hasDiscount && (
        <div style={{
          position: 'absolute',
          top: '10px',
          right: '10px',
          backgroundColor: '#dc2626',
          color: 'white',
          padding: '4px 8px',
          borderRadius: '4px',
          fontSize: '12px',
          fontWeight: 'bold',
        }}>
          {Math.round(discountRate * 100)}% OFF
        </div>
      )}

      <h3 style={{ margin: '0 0 8px 0', color: '#111' }}>{name}</h3>
      <p style={{ margin: '0 0 16px 0', color: '#666', fontSize: '14px' }}>
        {description}
      </p>

      {/* Pricing */}
      <div style={{ marginBottom: '16px' }}>
        {hasDiscount ? (
          <>
            <span style={{
              fontSize: '24px',
              fontWeight: 'bold',
              color: themeConfig.primaryColor,
            }}>
              ${discountedPrice.toFixed(2)}
            </span>
            <span style={{
              marginLeft: '8px',
              fontSize: '16px',
              color: '#999',
              textDecoration: 'line-through',
            }}>
              ${basePrice.toFixed(2)}
            </span>
          </>
        ) : (
          <span style={{
            fontSize: '24px',
            fontWeight: 'bold',
            color: themeConfig.primaryColor,
          }}>
            ${basePrice.toFixed(2)}
          </span>
        )}
      </div>

      {/* Stock info (INTEGER FLAG) */}
      <div style={{
        marginBottom: '16px',
        padding: '8px',
        backgroundColor: '#f3f4f6',
        borderRadius: '4px',
        fontSize: '14px',
        color: '#666',
      }}>
        📦 Stock limit: {stockLimit} units
      </div>

      {/* Action button (BOOLEAN + STRING FLAGS) */}
      <button
        disabled={!checkoutEnabled}
        style={{
          width: '100%',
          padding: '12px',
          backgroundColor: checkoutEnabled ? themeConfig.primaryColor : '#d1d5db',
          color: 'white',
          border: 'none',
          borderRadius: '6px',
          fontSize: '16px',
          fontWeight: '600',
          transition: 'background-color 0.2s',
        }}
        onMouseOver={(e) => {
          if (checkoutEnabled) {
            e.currentTarget.style.backgroundColor = '#6d28d9';
          }
        }}
        onMouseOut={(e) => {
          if (checkoutEnabled) {
            e.currentTarget.style.backgroundColor = themeConfig.primaryColor || '#7c3aed';
          }
        }}
      >
        {buttonText}
      </button>

      {!checkoutEnabled && (
        <p style={{
          marginTop: '8px',
          fontSize: '12px',
          color: '#dc2626',
          textAlign: 'center',
        }}>
          Checkout is currently disabled
        </p>
      )}

      {/* Debug info */}
      <details style={{ marginTop: '16px', fontSize: '12px', color: '#666' }}>
        <summary style={{ cursor: 'pointer' }}>🔍 Flag values</summary>
        <pre style={{
          marginTop: '8px',
          padding: '8px',
          backgroundColor: '#f9fafb',
          borderRadius: '4px',
          overflow: 'auto',
        }}>
          {JSON.stringify(
            {
              checkoutEnabled,
              buttonText,
              stockLimit,
              discountRate,
              themeConfig,
            },
            null,
            2
          )}
        </pre>
      </details>
    </div>
  );
}
