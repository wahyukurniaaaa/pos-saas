import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

const transactions = [
  { id: 'TRX-001', customer: 'Ahmad', amount: 150000, status: 'paid', time: '10:30' },
  { id: 'TRX-002', customer: 'Budi', amount: 235000, status: 'paid', time: '10:15' },
  { id: 'TRX-003', customer: 'Citra', amount: 89000, status: 'partial', time: '09:45' },
]

export function RecentTransactions() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Transaksi Terbaru</CardTitle>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>ID</TableHead>
              <TableHead>Pelanggan</TableHead>
              <TableHead>Waktu</TableHead>
              <TableHead className="text-right">Total</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {transactions.map((t) => (
              <TableRow key={t.id}>
                <TableCell className="font-medium">{t.id}</TableCell>
                <TableCell>{t.customer}</TableCell>
                <TableCell>{t.time}</TableCell>
                <TableCell className="text-right">
                  Rp {t.amount.toLocaleString()}
                </TableCell>
                <TableCell>
                  <span className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                    t.status === 'paid' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
                  }`}>
                    {t.status === 'paid' ? 'Lunas' : 'Partial'}
                  </span>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  )
}
