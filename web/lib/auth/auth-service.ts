export type AuthDecision = {
  redirectUrl: string | null;
};

/**
 * Pure function to determine authorization redirect logic.
 * @param user The current user object (or null if unauthenticated)
 * @param tierLevel The tier level ('pro', 'free', etc.)
 * @returns AuthDecision with a redirectUrl if access is denied, or null if allowed.
 */
export function authorizeDashboardAccess(user: any | null, tierLevel: string | null): AuthDecision {
  if (!user) {
    return { redirectUrl: '/login' };
  }

  if (!tierLevel || tierLevel !== 'pro') {
    return { redirectUrl: '/upgrade' };
  }

  return { redirectUrl: null };
}
