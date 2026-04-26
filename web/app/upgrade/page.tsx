import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card'
import { Check, Rocket, Zap, ShieldCheck } from 'lucide-react'
import Link from 'next/link'

export default function UpgradePage() {
  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-gray-50 p-4 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute top-0 right-0 w-1/2 h-1/2 bg-indigo-50 rounded-full blur-3xl opacity-50 -translate-y-1/2 translate-x-1/2" />
      <div className="absolute bottom-0 left-0 w-1/2 h-1/2 bg-blue-50 rounded-full blur-3xl opacity-50 translate-y-1/2 -translate-x-1/2" />

      <Card className="max-w-2xl w-full border-0 shadow-2xl z-10">
        <CardHeader className="text-center pb-2">
          <div className="mx-auto w-16 h-16 bg-indigo-100 rounded-2xl flex items-center justify-center mb-4">
            <Rocket className="w-8 h-8 text-indigo-600" />
          </div>
          <CardTitle className="text-3xl font-bold text-gray-900">Dashboard Khusus Pro</CardTitle>
          <CardDescription className="text-lg mt-2">
            Maaf, Dashboard Analytics dan Sinkronisasi Cloud hanya tersedia untuk pengguna paket **PRO**.
          </CardDescription>
        </CardHeader>
        
        <CardContent className="py-8">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <h4 className="font-semibold text-gray-900 flex items-center gap-2">
                <Zap className="w-4 h-4 text-amber-500" /> Fitur Pro yang Anda Lewatkan:
              </h4>
              <ul className="space-y-3">
                {[
                  'Dashboard Analytics Real-time',
                  'Sinkronisasi Cloud Tak Terbatas',
                  'Laporan Penjualan Detail (Excel/PDF)',
                  'Manajemen Multi-Outlet',
                  'Backup Data Otomatis'
                ].map((feature) => (
                  <li key={feature} className="flex items-start gap-2 text-sm text-gray-600">
                    <Check className="w-4 h-4 text-green-500 mt-0.5 shrink-0" />
                    {feature}
                  </li>
                ))}
              </ul>
            </div>
            
            <div className="bg-indigo-50 rounded-2xl p-6 flex flex-col justify-center border border-indigo-100">
              <div className="text-center">
                <p className="text-indigo-600 font-bold uppercase tracking-wider text-xs">Penawaran Terbatas</p>
                <div className="mt-2 flex items-baseline justify-center gap-1">
                  <span className="text-4xl font-extrabold text-gray-900">Rp 49rb</span>
                  <span className="text-gray-500">/bulan</span>
                </div>
                <p className="text-gray-500 text-xs mt-1">Batalkan kapan saja</p>
              </div>
              <Button className="w-full mt-6 bg-indigo-600 hover:bg-indigo-700 text-white font-bold h-12 shadow-lg shadow-indigo-200">
                Upgrade ke Pro Sekarang
              </Button>
            </div>
          </div>
        </CardContent>
        
        <CardFooter className="bg-gray-50 rounded-b-xl flex flex-col sm:flex-row items-center justify-between gap-4 p-6 border-t">
          <div className="flex items-center gap-2 text-gray-500 text-xs">
            <ShieldCheck className="w-4 h-4" />
            Pembayaran Aman & Terenkripsi
          </div>
          <div className="flex items-center gap-4">
            <Link href="/" className="text-sm text-gray-500 hover:text-gray-700 font-medium">
              Kembali ke Beranda
            </Link>
            <Button variant="ghost" size="sm" asChild>
              <Link href="/login">Ganti Akun</Link>
            </Button>
          </div>
        </CardFooter>
      </Card>
    </div>
  )
}
