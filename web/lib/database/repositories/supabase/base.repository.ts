import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import type { Database } from '@/lib/types/database'

export abstract class SupabaseRepository {
  protected supabase = createClientComponentClient<Database>()
  protected userTier: 'free' | 'lite' | 'pro' = 'free'
  protected currentOutletId: string | null = null

  setTier(tier: 'free' | 'lite' | 'pro') {
    this.userTier = tier
  }

  setOutletId(outletId: string) {
    this.currentOutletId = outletId
  }
}
