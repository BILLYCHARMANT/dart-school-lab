import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  await Hive.openBox('cache');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Lab 4',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PostsPage(),
    );
  }
}

class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

class ErrorReportScreen extends StatelessWidget {
  final String errorMessage;

  const ErrorReportScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Report')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An error occurred:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(errorMessage, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  late Future<List<Post>> _postsFuture;
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  String _searchQuery = '';
  bool _isOffline = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _postsFuture = fetchPosts();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResults.contains(ConnectivityResult.none);
    });
  }

  Future<List<Post>> fetchPosts() async {
    final cacheBox = Hive.box('cache');
    final cachedData = cacheBox.get('posts');

    // Try to load from cache first
    if (cachedData != null) {
      try {
        final List<dynamic> data = jsonDecode(cachedData);
        final posts = data.map((item) => Post.fromJson(item)).toList();
        setState(() {
          _allPosts = posts;
          _filteredPosts = _filterPosts(posts);
        });
        return posts;
      } catch (e) {
        // Cache corrupted, ignore
      }
    }

    // Check connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      setState(() {
        _isOffline = true;
        _lastError =
            'No internet connection. Showing cached data if available.';
      });
      if (_allPosts.isNotEmpty) {
        return _allPosts;
      }
      throw Exception('No internet connection and no cached data.');
    }

    // Fetch from API
    try {
      const String url = 'https://jsonplaceholder.typicode.com/posts';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final posts = data.map((item) => Post.fromJson(item)).toList();

        // Cache the data
        await cacheBox.put('posts', jsonEncode(data));

        setState(() {
          _allPosts = posts;
          _filteredPosts = _filterPosts(posts);
          _isOffline = false;
          _lastError = null;
        });

        return posts;
      } else {
        throw Exception(
          'Failed to load posts (status: ${response.statusCode})',
        );
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
      rethrow;
    }
  }

  List<Post> _filterPosts(List<Post> posts) {
    if (_searchQuery.isEmpty) {
      return posts;
    }
    return posts
        .where(
          (post) =>
              post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              post.body.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredPosts = _filterPosts(_allPosts);
    });
  }

  void _refresh() {
    setState(() {
      _postsFuture = fetchPosts();
    });
  }

  void _showErrorReport() {
    if (_lastError != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ErrorReportScreen(errorMessage: _lastError!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab 4: Consume API'),
        actions: [
          if (_lastError != null)
            IconButton(
              icon: const Icon(Icons.error),
              tooltip: 'View Error Report',
              onPressed: _showErrorReport,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search posts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading posts:\n${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_isOffline)
                      const Text(
                        'You are offline. Data may be from cache.',
                        style: TextStyle(color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final posts = _filteredPosts.isNotEmpty
              ? _filteredPosts
              : (snapshot.data ?? <Post>[]);

          if (posts.isEmpty) {
            return const Center(child: Text('No posts found.'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Text(post.id.toString())),
                  title: Text(post.title),
                  subtitle: Text(post.body),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
