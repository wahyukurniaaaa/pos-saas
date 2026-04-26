import { EnhancedHero } from '@/components/marketing/enhanced-hero'
import { AnimatedFeatures } from '@/components/marketing/animated-features'
import { AnimatedPricing } from '@/components/marketing/animated-pricing'

export default function Home() {
  return (
    <main>
      <EnhancedHero />
      <AnimatedFeatures />
      <AnimatedPricing />
    </main>
  )
}
