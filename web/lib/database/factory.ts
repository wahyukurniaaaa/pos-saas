import { IAnalyticsRepository } from './interfaces/repository.interface'
import { SupabaseAnalyticsRepository } from './repositories/supabase/analytics.repository'

export class RepositoryFactory {
  static createAnalyticsRepository(): IAnalyticsRepository {
    return new SupabaseAnalyticsRepository()
  }
}
