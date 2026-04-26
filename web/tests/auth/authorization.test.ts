import { describe, it, expect } from 'vitest';
import { authorizeDashboardAccess } from '../../lib/auth/auth-service';

describe('authorizeDashboardAccess', () => {
  it('should redirect to /login if user is unauthenticated', () => {
    const decision = authorizeDashboardAccess(null, null);
    expect(decision.redirectUrl).toBe('/login');
  });

  it('should redirect to /upgrade if user is authenticated but tier is free/null', () => {
    const user = { id: '123', email: 'test@example.com' };
    const decision1 = authorizeDashboardAccess(user, null);
    expect(decision1.redirectUrl).toBe('/upgrade');

    const decision2 = authorizeDashboardAccess(user, 'free');
    expect(decision2.redirectUrl).toBe('/upgrade');
  });

  it('should allow access (return null redirect) if user is authenticated and tier is pro', () => {
    const user = { id: '123', email: 'test@example.com' };
    const decision = authorizeDashboardAccess(user, 'pro');
    expect(decision.redirectUrl).toBeNull();
  });
});
