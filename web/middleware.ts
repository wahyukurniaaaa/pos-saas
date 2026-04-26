import { NextResponse, type NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'
import { authorizeDashboardAccess } from '@/lib/auth/auth-service'

export async function middleware(request: NextRequest) {
  // Update the supabase session (refreshes tokens if needed)
  const { supabase, response } = updateSession(request)

  // Protect the /dashboard routes
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    const {
      data: { user },
    } = await supabase.auth.getUser()

    // Extract license code from user metadata
    const licenseCode = user?.user_metadata?.license_code;
    
    // For now, if they have a license_code, we treat them as 'pro'
    // Alternatively, we could fetch from the external API here.
    const tierLevel = licenseCode ? 'pro' : 'free';

    const authDecision = authorizeDashboardAccess(user, tierLevel);

    if (authDecision.redirectUrl) {
      const url = request.nextUrl.clone()
      url.pathname = authDecision.redirectUrl
      return NextResponse.redirect(url)
    }
  }

  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * Feel free to modify this pattern to include more paths.
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
