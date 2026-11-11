import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProductAdminApp());
}

class ProductAdminApp extends StatelessWidget {
  const ProductAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý sản phẩm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3157D5),
          surface: const Color(0xFFF7F8FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (snapshot.hasError) {
          return _ErrorScreen(message: 'Không thể kiểm tra đăng nhập: ${snapshot.error}');
        }
        return snapshot.data == null
            ? const LoginScreen()
            : ProductListScreen(user: snapshot.data!);
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) _showAuthError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAuthError(FirebaseAuthException error) {
    final message = switch (error.code) {
      'invalid-email' => 'Email không hợp lệ.',
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'Email hoặc mật khẩu không chính xác.',
      'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
      'operation-not-allowed' => 'Firebase chưa bật phương thức Email/Password.',
      _ => error.message ?? 'Đăng nhập thất bại (${error.code}).',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(isWide ? 36 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 52),
                      const SizedBox(height: 16),
                      Text(
                        'Quản lý sản phẩm',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập để quản lý danh mục sản phẩm.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty || !email.contains('@')) {
                            return 'Vui lòng nhập email hợp lệ.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'Mật khẩu cần có ít nhất 6 ký tự.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Đăng nhập'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.soluong,
    required this.image,
  });

  final String id;
  final String name;
  final double price;
  final int soluong;
  final String image;

  factory Product.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final price = data['price'];
    final quantity = data['soluong'];
    if (data['name'] is! String || price is! num || quantity is! int || data['image'] is! String) {
      throw const FormatException('Dữ liệu sản phẩm không đúng định dạng.');
    }
    return Product(
      id: document.id,
      name: data['name'] as String,
      price: price.toDouble(),
      soluong: quantity,
      image: data['image'] as String,
    );
  }

  Map<String, Object> toMap() => {
        'name': name,
        'price': price,
        'soluong': soluong,
        'image': image,
      };
}

Future<void> _deleteStoredImage(String url) async {
  final uri = Uri.tryParse(url);
  if (url.startsWith('gs://') || uri?.host == 'firebasestorage.googleapis.com') {
    await FirebaseStorage.instance.refFromURL(url).delete();
  }
}

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({required this.user, super.key});

  final User user;

  CollectionReference<Map<String, dynamic>> get _products =>
      FirebaseFirestore.instance.collection('products');

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openForm(BuildContext context, [Product? product]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ProductFormDialog(product: product),
    );
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text('Bạn có chắc muốn xóa "${product.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;

    try {
      await _products.doc(product.id).delete();
    } on FirebaseException catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Không thể xóa sản phẩm: ${error.message ?? error.code}');
      }
      return;
    }
    try {
      await _deleteStoredImage(product.image);
    } on FirebaseException catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          'Đã xóa sản phẩm nhưng chưa xóa được ảnh trên Storage: ${error.message ?? error.code}',
        );
      }
      return;
    }
    if (context.mounted) _showMessage(context, 'Đã xóa sản phẩm.');
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 560)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(user.email ?? 'Quản trị viên'),
              ),
            ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } on FirebaseAuthException catch (error) {
                if (context.mounted) {
                  _showMessage(context, 'Không thể đăng xuất: ${error.message ?? error.code}');
                }
              }
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _products.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorScreen(
              message: 'Không thể tải sản phẩm. Kiểm tra cấu hình và quyền Firestore.\n${snapshot.error}',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data?.docs ?? [];
          late final List<Product> products;
          try {
            products = documents.map(Product.fromDocument).toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          } on FormatException catch (error) {
            return _ErrorScreen(message: 'Dữ liệu sản phẩm không hợp lệ: ${error.message}');
          }
          if (products.isEmpty) {
            return _EmptyProducts(onAdd: () => _openForm(context));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Danh sách sản phẩm',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Chip(label: Text('${products.length} sản phẩm')),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        (constraints.maxWidth / 300).floor().clamp(1, 4).toInt();
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 350,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _ProductCard(
                          product: product,
                          formattedPrice: currency.format(product.price),
                          onEdit: () => _openForm(context, product),
                          onDelete: () => _deleteProduct(context, product),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Chưa có sản phẩm nào', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Thêm sản phẩm đầu tiên để bắt đầu quản lý.'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.formattedPrice,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final String formattedPrice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              product.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFE9ECF5),
                child: Center(child: Icon(Icons.broken_image_outlined, size: 48)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedPrice,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text('Số lượng: ${product.soluong}'),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Sửa sản phẩm',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Xóa sản phẩm',
                      onPressed: onDelete,
                      color: Colors.red,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({this.product, super.key});

  final Product? product;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _quantityController.text = product.soluong.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final mimeType = lookupMimeType(image.name, headerBytes: bytes);
      if (mimeType == null || !mimeType.startsWith('image/')) {
        _showMessage('Tệp đã chọn không phải hình ảnh hợp lệ.');
        return;
      }
      if (bytes.length > 5 * 1024 * 1024) {
        _showMessage('Ảnh tối đa 5 MB. Hãy chọn ảnh nhỏ hơn.');
        return;
      }
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
    } on FirebaseException catch (error) {
      _showMessage('Không thể đọc hình ảnh: ${error.message ?? error.code}');
    } on PlatformException catch (error) {
      _showMessage('Không thể chọn hình ảnh: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validatePrice(String? value) {
    final price = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (price == null || !price.isFinite || price < 0) {
      return 'Nhập giá hợp lệ (từ 0 trở lên).';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    final quantity = int.tryParse((value ?? '').trim());
    if (quantity == null || quantity < 0) {
      return 'Nhập số lượng nguyên (từ 0 trở lên).';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.product == null && _selectedImage == null) {
      _showMessage('Vui lòng chọn hình ảnh sản phẩm.');
      return;
    }

    setState(() => _isSaving = true);
    Reference? uploadedImage;
    try {
      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product?.id);
      var imageUrl = widget.product?.image ?? '';
      if (_selectedImage != null && _imageBytes != null) {
        final contentType = lookupMimeType(
              _selectedImage!.name,
              headerBytes: _imageBytes,
            ) ??
            'image/jpeg';
        uploadedImage = FirebaseStorage.instance
            .ref()
            .child('products/${productRef.id}/${const Uuid().v4()}');
        await uploadedImage.putData(
          _imageBytes!,
          SettableMetadata(contentType: contentType),
        );
        imageUrl = await uploadedImage.getDownloadURL();
      }

      final data = Product(
        id: productRef.id,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
        soluong: int.parse(_quantityController.text.trim()),
        image: imageUrl,
      ).toMap();
      await productRef.set(data);

      final previousImage = widget.product?.image;
      if (previousImage != null && _selectedImage != null) {
        try {
          await _deleteStoredImage(previousImage);
        } on FirebaseException catch (error) {
          _showMessage(
            'Đã lưu sản phẩm nhưng chưa xóa được ảnh cũ: ${error.message ?? error.code}',
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (uploadedImage != null) {
        try {
          await uploadedImage.delete();
        } on FirebaseException catch (cleanupError) {
          _showMessage(
            'Không thể hoàn tác tệp ảnh tạm: ${cleanupError.message ?? cleanupError.code}',
          );
        }
      }
      _showMessage('Không thể lưu sản phẩm: ${error.message ?? error.code}');
    } on FormatException catch (error) {
      _showMessage('Dữ liệu nhập không hợp lệ: ${error.message}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Dialog(
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  product == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'Vui lòng nhập tên sản phẩm.';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Giá sản phẩm (₫)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: _validatePrice,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: _validateQuantity,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _selectedImage == null
                        ? (product == null ? 'Chọn hình ảnh' : 'Đổi hình ảnh')
                        : 'Đã chọn: ${_selectedImage!.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_imageBytes != null || product != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      child: _imageBytes != null
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                          : Image.network(
                              product.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Color(0xFFE9ECF5),
                                child: Center(child: Icon(Icons.broken_image_outlined)),
                              ),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(product == null ? 'Thêm' : 'Lưu thay đổi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
