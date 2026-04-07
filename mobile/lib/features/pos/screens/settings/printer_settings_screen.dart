import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:drift/drift.dart' as drift;

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  bool _isLoading = false;
  bool _autoPrint = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    setState(() => _isLoading = true);
    try {
      final isOn = await bluetooth.isOn ?? false;
      if (!isOn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bluetooth belum aktif. Silakan nyalakan bluetooth Anda.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      final devices = await bluetooth.getBondedDevices();
      final isConnected = await bluetooth.isConnected ?? false;
      
      // Load auto print settings from DB
      final db = ref.read(databaseProvider);
      final settings = await (db.select(db.printerSettings)..limit(1)).getSingleOrNull();
      final autoPrint = settings?.autoPrint ?? false;

      setState(() {
        _devices = devices;
        _connected = isConnected;
        _autoPrint = autoPrint;
      });
    } on PlatformException catch (e) {
      debugPrint("Bluetooth error: $e");
    } finally {
      setState(() => _isLoading = false);
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            _selectedDevice = null;
          });
          break;
        default:
          break;
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _isLoading = true);
    try {
      await bluetooth.connect(device);
      setState(() {
        _selectedDevice = device;
        _connected = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terhubung ke ${device.name}'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal terhubung: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    try {
      await bluetooth.disconnect();
      setState(() {
        _connected = false;
        _selectedDevice = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memutuskan: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPrint() async {
    if (!(_connected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap sambungkan printer terlebih dahulu'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await bluetooth.printCustom("POSIFY UJI CETAK", 1, 1);
      await bluetooth.printNewLine();
      await bluetooth.printCustom("Printer Terhubung dengan Baik", 0, 1);
      await bluetooth.printNewLine();
      await bluetooth.printNewLine();
      await bluetooth.paperCut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleAutoPrint(bool value) async {
    setState(() => _autoPrint = value);
    final db = ref.read(databaseProvider);
    final settings = await (db.select(db.printerSettings)..limit(1)).getSingleOrNull();
    
    if (settings != null) {
      await db.update(db.printerSettings).replace(
            settings.copyWith(autoPrint: value),
          );
    } else {
      await db.into(db.printerSettings).insert(
            PrinterSettingsCompanion.insert(
              deviceName: _selectedDevice?.name ?? 'Unknown',
              macAddress: _selectedDevice?.address ?? '00:00',
              autoPrint: drift.Value(value),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan Printer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _connected
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _connected ? Icons.print : Icons.print_disabled,
                    color: _connected
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _connected
                            ? 'Printer Terhubung'
                            : 'Printer Tidak Terhubung',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (_selectedDevice != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedDevice!.name ?? 'Unknown Device',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_connected)
                  OutlinedButton(
                    onPressed: _isLoading ? null : _disconnect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                    child: const Text('Putus'),
                  ),
              ],
            ),
          ),
          
          // Info Note for Android Location
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Izin Lokasi (GPS) diperlukan sistem Android untuk pemindaian Bluetooth. Ini adalah aturan standar OS Android.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Auto Print Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                title: Text(
                  'Cetak Otomatis',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Langsung cetak struk setelah transaksi sukses',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                value: _autoPrint,
                onChanged: _toggleAutoPrint,
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Perangkat Bluetooth Tersedia',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada perangkat bluetooth',
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected =
                          _selectedDevice?.address == device.address;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                          title: Text(
                            device.name ?? 'Unknown',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            device.address ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.successColor,
                                )
                              : null,
                          onTap: isSelected || _connected
                              ? null
                              : () => _connect(device),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _connected && !_isLoading ? _testPrint : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Uji Cetak',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
