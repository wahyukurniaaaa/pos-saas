import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card'
import { AlertCircle } from 'lucide-react'
import Link from 'next/link'

export default function AuthCodeErrorPage() {
  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-gray-50 p-4">
      <Card className="max-w-md w-full border-0 shadow-lg">
        <CardHeader className="text-center">
          <div className="mx-auto w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mb-4">
            <AlertCircle className="w-6 h-6 text-red-600" />
          </div>
          <CardTitle className="text-xl font-bold">Autentikasi Gagal</CardTitle>
          <CardDescription>
            Terjadi kesalahan saat mencoba menukar kode autentikasi. Ini mungkin disebabkan oleh kode yang sudah kadaluarsa atau tidak valid.
          </CardDescription>
        </CardHeader>
        <CardContent className="text-center text-sm text-gray-500">
          Silakan coba login kembali. Jika masalah berlanjut, hubungi dukungan teknis kami.
        </CardContent>
        <CardFooter className="flex justify-center border-t p-6">
          <Button asChild className="bg-indigo-600 hover:bg-indigo-700">
            <Link href="/login">Kembali ke Login</Link>
          </Button>
        </CardFooter>
      </Card>
    </div>
  )
}
