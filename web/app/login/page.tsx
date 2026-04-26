import { LoginForm } from '@/components/auth/login-form'

export default function LoginPage() {
  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-gray-50 relative overflow-hidden">
      {/* Decorative Blobs */}
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-indigo-100 rounded-full blur-3xl opacity-60 animate-pulse" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-blue-50 rounded-full blur-3xl opacity-60 animate-pulse" />
      
      <div className="z-10 w-full max-w-md px-4">
        <div className="mb-8 text-center">
          <h2 className="text-3xl font-extrabold text-indigo-600 tracking-tight">POSify</h2>
          <p className="text-gray-500 mt-2">Solusi Kasir Pintar untuk UMKM Indonesia</p>
        </div>
        
        <LoginForm />
        
        <p className="mt-8 text-center text-xs text-gray-400">
          &copy; {new Date().getFullYear()} POSify SaaS. Hak Cipta Dilindungi.
        </p>
      </div>
    </div>
  )
}
