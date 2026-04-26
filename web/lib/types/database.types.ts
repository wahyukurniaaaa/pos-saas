export type Database = {
  public: {
    Tables: {
      transactions: {
        Row: {
          id: string
          outlet_id: string
          total_amount: number
          created_at: string
        }
      }
    }
  }
}
