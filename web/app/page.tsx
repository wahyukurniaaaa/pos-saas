import { SimpleAnimatedHero } from '@/components/marketing/simple-animated-hero'
import { SimpleFeatures } from '@/components/marketing/simple-features'
import { SimplePricing } from '@/components/marketing/simple-pricing'

export default function Home() {
  return (
    <main>
      <SimpleAnimatedHero />
      <SimpleFeatures />
      <SimplePricing />
    </main>
  )
}
