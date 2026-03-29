import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (kIsWeb) {
    runApp(const UnsupportedPlatformApp());
    return;
  }

  await PostsDatabase.instance.initDb();
  runApp(const OfflinePostsManagerApp());
}

class UnsupportedPlatformApp extends StatelessWidget {
  const UnsupportedPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unsupported platform',
      home: Scaffold(
        appBar: AppBar(title: const Text('Unsupported platform')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Offline SQLite app is supported on mobile and desktop platforms only. Please run on Android, iOS, Windows, macOS, or Linux.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class OfflinePostsManagerApp extends StatelessWidget {
  const OfflinePostsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Posts Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PostsPage(),
    );
  }
}

class Post {
  final int? id;
  final String title;
  final String body;

  Post({this.id, required this.title, required this.body});

  Map<String, dynamic> toMap() {
    return {if (id != null) 'id': id, 'title': title, 'body': body};
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
    );
  }
}

class PostsDatabase {
  static final PostsDatabase instance = PostsDatabase._init();
  static Database? _database;

  PostsDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    throw Exception('Database not initialized');
  }

  Future<void> initDb() async {
    if (_database != null) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'posts_manager.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE posts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<Post> insertPost(Post post) async {
    try {
      final id = await (await database).insert('posts', post.toMap());
      return post.copyWith(id: id);
    } on DatabaseException catch (e) {
      throw Exception('Insert error: ${e.toString()}');
    }
  }

  Future<List<Post>> fetchAllPosts() async {
    try {
      final result = await (await database).query('posts', orderBy: 'id DESC');
      return result.map((row) => Post.fromMap(row)).toList();
    } on DatabaseException catch (e) {
      throw Exception('Read error: ${e.toString()}');
    }
  }

  Future<Post> updatePost(Post post) async {
    if (post.id == null)
      throw Exception('Post id is null and cannot be updated');
    try {
      final updated = await (await database).update(
        'posts',
        post.toMap(),
        where: 'id = ?',
        whereArgs: [post.id],
      );

      if (updated == 0) throw Exception('No post found with id ${post.id}');
      return post;
    } on DatabaseException catch (e) {
      throw Exception('Update error: ${e.toString()}');
    }
  }

  Future<void> deletePost(int id) async {
    try {
      final deleted = await (await database).delete(
        'posts',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (deleted == 0) throw Exception('No post found with id $id');
    } on DatabaseException catch (e) {
      throw Exception('Delete error: ${e.toString()}');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

extension PostCopy on Post {
  Post copyWith({int? id, String? title, String? body}) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = PostsDatabase.instance.fetchAllPosts();
      _errorMessage = null;
    });
  }

  Future<void> _openPostForm([Post? post]) async {
    final titleController = TextEditingController(text: post?.title ?? '');
    final bodyController = TextEditingController(text: post?.body ?? '');
    final isEditing = post != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Post' : 'New Post'),
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                if (title.isEmpty || body.isEmpty) return;

                try {
                  if (isEditing) {
                    await PostsDatabase.instance.updatePost(
                      post!.copyWith(title: title, body: body),
                    );
                  } else {
                    await PostsDatabase.instance.insertPost(
                      Post(title: title, body: body),
                    );
                  }
                  Navigator.of(context).pop(true);
                } catch (e) {
                  Navigator.of(context).pop(false);
                  setState(() {
                    _errorMessage = e.toString();
                  });
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        );
      },
    );

    if (result == true) _refreshPosts();
  }

  Future<void> _confirmDelete(Post post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete post?'),
          content: Text('Are you sure you want to delete "${post.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await PostsDatabase.instance.deletePost(post.id!);
        _refreshPosts();
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _viewDetails(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Posts Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshPosts),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPostForm(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            final posts = snapshot.data ?? [];
            if (posts.isEmpty) {
              return const Center(
                child: Text('No posts yet. Add one using + button.'),
              );
            }

            return Column(
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Card(
                        child: ListTile(
                          title: Text(post.title),
                          subtitle: Text(
                            post.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _viewDetails(post),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'view') _viewDetails(post);
                              if (value == 'edit') await _openPostForm(post);
                              if (value == 'delete') await _confirmDelete(post);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'view', child: Text('View')),
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${post.id ?? '-'}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text('Title', style: Theme.of(context).textTheme.titleMedium),
            Text(
              post.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Body', style: Theme.of(context).textTheme.titleMedium),
            Text(post.body, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
