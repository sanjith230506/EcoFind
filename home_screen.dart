import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'upload_product_page.dart';
import 'my_products_page.dart';
import 'my_cart_page.dart';
import 'profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "All";
  String sortOption = "Newest"; // Sorting options: Newest, Oldest, Price Low → High, Price High → Low
  TextEditingController searchController = TextEditingController();

  int _currentIndex = 0;

final colors = {
  "primary": Colors.teal,           // fresh primary color
  "secondary": Colors.orangeAccent,  // secondary color for ChoiceChips
  "background": Colors.grey[100],
  "card": Colors.white,
};


  final currentUser = FirebaseAuth.instance.currentUser;

  // Firestore stream
  Stream<QuerySnapshot> getProductsStream() {
    Query query = FirebaseFirestore.instance.collection('products');

    if (selectedCategory != "All") {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    // Sorting logic
    switch (sortOption) {
      case "Newest":
        query = query.orderBy('createdAt', descending: true);
        break;
      case "Oldest":
        query = query.orderBy('createdAt', descending: false);
        break;
      case "Price Low → High":
        query = query.orderBy('price', descending: false);
        break;
      case "Price High → Low":
        query = query.orderBy('price', descending: true);
        break;
    }

    return query.snapshots();
  }

  // Add to cart function
  Future<void> addToCart(String productId, Map<String, dynamic> productData) async {
    if (currentUser == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cart');

    final existingProduct = await cartRef.doc(productId).get();

    if (existingProduct.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product already in cart")),
      );
      return;
    }

    await cartRef.doc(productId).set({
      'productId': productId,
      'title': productData['title'] ?? '',
      'price': productData['price'] ?? 0,
      'imageUrl': productData['imageUrl'] ?? '',
      'category': productData['category'] ?? '',
      'quantity': 1,
      'addedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product added to cart")),
    );
  }

  void filterSearch(String query) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categories = ["All", "Fashion", "Electronics", "Books", "Furniture"];
    final sortOptions = ["Newest", "Oldest", "Price Low → High", "Price High → Low"];

    return Scaffold(
      backgroundColor: colors["background"],
      appBar: AppBar(
        backgroundColor: colors["primary"],
        title: const Text("EcoFinds"),
        actions: [
          IconButton(
    icon: const Icon(Icons.person),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    },
  ),
          IconButton(
  icon: const Icon(Icons.shopping_cart),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyCartPage()),
    );
  },
),

        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: filterSearch,
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors["card"],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Categories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    selectedColor: colors["primary"],
                    backgroundColor: Colors.grey[300],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  ),
                );
              },
            ),
          ),

          // Sorting options
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sortOptions.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final option = sortOptions[index];
                final isSelected = sortOption == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        sortOption = option;
                      });
                    },
                    selectedColor: colors["secondary"],
                    backgroundColor: Colors.grey[300],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  ),
                );
              },
            ),
          ),

          // Product Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No products found"));
                }

                final products = snapshot.data!.docs.where((doc) {
                  final title = doc['title']?.toString().toLowerCase() ?? '';
                  return title.contains(searchController.text.toLowerCase());
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final productData = product.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: productData['imageUrl'] != null &&
                                      productData['imageUrl'].toString().isNotEmpty
                                  ? Image.network(
                                      productData['imageUrl'],
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(child: Icon(Icons.image, size: 50)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              productData['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${productData['price'] ?? 0}",
                              style: TextStyle(fontSize: 14, color: colors["primary"]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              productData['category'] ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  addToCart(product.id, productData);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors["primary"],
                                ),
                                child: const Text("Add to Cart"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadProductScreen()),
          );
        },
        backgroundColor: colors["primary"],
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: colors["primary"],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 1) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const MyCartPage()),
  );
} else if (index == 2) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const MyProductsPage()),
  );
}
else if (index == 3) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ProfilePage()),
  );
}

        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "My Listings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
