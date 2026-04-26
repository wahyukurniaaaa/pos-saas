import { AnimatedHero } from '@/components/marketing/animated-hero'
import { Features } from '@/components/marketing/features'
import { Pricing } from '@/components/marketing/pricing'

export default function Home() {
  return (
    <main>
      <AnimatedHero />
      <Features />
      <Pricing />
    </main>
  )
}
