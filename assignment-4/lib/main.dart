import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('cache');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posts Manager',
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

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${post.id}', style: const TextStyle(fontSize: 14)),
            Text(
              'User ID: ${post.userId}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(post.body, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
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

  Future<Post> _createPost(String title, String body) async {
    const String url = 'https://jsonplaceholder.typicode.com/posts';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final post = Post.fromJson({
        'userId': data['userId'] ?? 1,
        'id': data['id'] ?? _allPosts.length + 1,
        'title': data['title'] ?? title,
        'body': data['body'] ?? body,
      });
      return post;
    } else {
      throw Exception('Failed to create post (status: ${response.statusCode})');
    }
  }

  Future<Post> _updatePost(Post post) async {
    final String url = 'https://jsonplaceholder.typicode.com/posts/${post.id}';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'id': post.id,
        'title': post.title,
        'body': post.body,
        'userId': post.userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Post.fromJson({
        'userId': data['userId'] ?? post.userId,
        'id': data['id'] ?? post.id,
        'title': data['title'] ?? post.title,
        'body': data['body'] ?? post.body,
      });
    } else {
      throw Exception('Failed to update post (status: ${response.statusCode})');
    }
  }

  Future<void> _deletePost(int id) async {
    final String url = 'https://jsonplaceholder.typicode.com/posts/$id';
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _allPosts.removeWhere((post) => post.id == id);
        _filteredPosts = _filterPosts(_allPosts);
      });
      final cacheBox = Hive.box('cache');
      cacheBox.put(
        'posts',
        jsonEncode(
          _allPosts
              .map(
                (post) => {
                  'userId': post.userId,
                  'id': post.id,
                  'title': post.title,
                  'body': post.body,
                },
              )
              .toList(),
        ),
      );
    } else {
      throw Exception('Failed to delete post (status: ${response.statusCode})');
    }
  }

  Future<void> _showPostForm({Post? post}) async {
    final titleController = TextEditingController(text: post?.title ?? '');
    final bodyController = TextEditingController(text: post?.body ?? '');

    final isEditing = post != null;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Post' : 'Create Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                if (title.isEmpty || body.isEmpty) {
                  return;
                }

                Navigator.of(context).pop();
                try {
                  if (isEditing) {
                    final updatedPost = await _updatePost(
                      Post(
                        userId: post!.userId,
                        id: post.id,
                        title: title,
                        body: body,
                      ),
                    );
                    setState(() {
                      final index = _allPosts.indexWhere(
                        (p) => p.id == post.id,
                      );
                      if (index != -1) _allPosts[index] = updatedPost;
                      _filteredPosts = _filterPosts(_allPosts);
                    });
                  } else {
                    final newPost = await _createPost(title, body);
                    setState(() {
                      _allPosts.insert(0, newPost);
                      _filteredPosts = _filterPosts(_allPosts);
                    });
                  }
                  final cacheBox = Hive.box('cache');
                  cacheBox.put(
                    'posts',
                    jsonEncode(
                      _allPosts
                          .map(
                            (post) => {
                              'userId': post.userId,
                              'id': post.id,
                              'title': post.title,
                              'body': post.body,
                            },
                          )
                          .toList(),
                    ),
                  );
                } catch (e) {
                  setState(() {
                    _lastError = e.toString();
                  });
                }
              },
              child: Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        );
      },
    );
  }

  void _showPostDetail(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Manager'),
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
                  onTap: () => _showPostDetail(post),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'view') {
                        _showPostDetail(post);
                      } else if (value == 'edit') {
                        _showPostForm(post: post);
                      } else if (value == 'delete') {
                        await _deletePost(post.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('View Details'),
                      ),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostForm(),
        tooltip: 'Create Post',
        child: const Icon(Icons.add),
      ),
    );
  }
}
