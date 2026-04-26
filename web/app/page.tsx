import { AnimatedHero } from '@/components/marketing/animated-hero'
import { AnimatedFeatures } from '@/components/marketing/animated-features'
import { AnimatedPricing } from '@/components/marketing/animated-pricing'

export default function Home() {
  return (
    <main>
      <AnimatedHero />
      <AnimatedFeatures />
      <AnimatedPricing />
    </main>
  )
}
