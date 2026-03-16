import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog({Category? existing}) {
    _nameController.text = existing?.name ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing != null ? 'Edit Kategori' : 'Tambah Kategori',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nama kategori',
            hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              final db = ref.read(databaseProvider);

              if (existing != null) {
                await db.updateCategory(existing.copyWith(name: name));
              } else {
                await db.insertCategory(CategoriesCompanion.insert(name: name));
              }

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Kategori',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Yakin ingin menghapus kategori "${cat.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.deleteCategory(cat);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Kategori Produk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(child: StreamBuilder<List<Category>>(
        stream: db.watchAllCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kategori',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.label,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    cat.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: AppTheme.primaryColor,
                        onPressed: () => _showAddCategoryDialog(existing: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppTheme.errorColor,
                        onPressed: () => _confirmDelete(cat),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
