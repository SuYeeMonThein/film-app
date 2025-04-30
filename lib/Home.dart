import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _apiKey =
      'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4MDY2YmUxYjEzYTVkZjM5NDA3ZDlmNTgzZDU3OWQ1ZCIsInN1YiI6IjYzOWQ0MmNiOWJjZDBmMDA4YzUxYWFjNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.885dfzBlsRrx43OUWHaTqduAgiGGWup3fm2PSjcnjZw';
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  bool _isLoading = true;

  // For Popular Movies
  List<dynamic> _popularMovies = [];
  int _popularPage = 1;
  bool _isLoadingMorePopular = false;
  bool _hasMorePopular = true;
  final ScrollController _popularController = ScrollController();

  // For Top Rated Movies
  List<dynamic> _topRatedMovies = [];
  int _topRatedPage = 1;
  bool _isLoadingMoreTopRated = false;
  bool _hasMoreTopRated = true;
  final ScrollController _topRatedController = ScrollController();

  // For Now Playing Movies
  List<dynamic> _nowPlayingMovies = [];
  int _nowPlayingPage = 1;
  bool _isLoadingMoreNowPlaying = false;
  bool _hasMoreNowPlaying = true;
  final ScrollController _nowPlayingController = ScrollController();

  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllMovies();

    // Setup scroll listeners for infinite scrolling
    _setupScrollListeners();

    // Check authentication status
    Future.delayed(Duration.zero, () {
      _checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _popularController.dispose();
    _topRatedController.dispose();
    _nowPlayingController.dispose();
    super.dispose();
  }

  void _setupScrollListeners() {
    _popularController.addListener(() {
      if (_popularController.position.pixels >=
          _popularController.position.maxScrollExtent - 200) {
        _loadMorePopular();
      }
    });

    _topRatedController.addListener(() {
      if (_topRatedController.position.pixels >=
          _topRatedController.position.maxScrollExtent - 200) {
        _loadMoreTopRated();
      }
    });

    _nowPlayingController.addListener(() {
      if (_nowPlayingController.position.pixels >=
          _nowPlayingController.position.maxScrollExtent - 200) {
        _loadMoreNowPlaying();
      }
    });
  }

  Future<void> _fetchAllMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Reset page counters
      _popularPage = 1;
      _topRatedPage = 1;
      _nowPlayingPage = 1;

      // Reset hasMore flags
      _hasMorePopular = true;
      _hasMoreTopRated = true;
      _hasMoreNowPlaying = true;

      // Fetch all three categories in parallel
      final results = await Future.wait([
        _fetchMovies('/movie/popular', 1),
        _fetchMovies('/movie/top_rated', 1),
        _fetchMovies('/movie/now_playing', 1),
      ]);

      if (mounted) {
        setState(() {
          _popularMovies = results[0];
          _topRatedMovies = results[1];
          _nowPlayingMovies = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load movies: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<dynamic>> _fetchMovies(String endpoint, int page) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint?language=en-US&page=$page'),
      headers: {'Authorization': _apiKey, 'accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Failed to load movies: ${response.statusCode}');
    }
  }

  Future<void> _loadMorePopular() async {
    if (_isLoadingMorePopular || !_hasMorePopular) return;

    setState(() {
      _isLoadingMorePopular = true;
    });

    try {
      _popularPage++;
      final newMovies = await _fetchMovies('/movie/popular', _popularPage);

      if (newMovies.isEmpty) {
        setState(() {
          _hasMorePopular = false;
          _isLoadingMorePopular = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _popularMovies.addAll(newMovies);
          _isLoadingMorePopular = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMorePopular = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more movies: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreTopRated() async {
    if (_isLoadingMoreTopRated || !_hasMoreTopRated) return;

    setState(() {
      _isLoadingMoreTopRated = true;
    });

    try {
      _topRatedPage++;
      final newMovies = await _fetchMovies('/movie/top_rated', _topRatedPage);

      if (newMovies.isEmpty) {
        setState(() {
          _hasMoreTopRated = false;
          _isLoadingMoreTopRated = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _topRatedMovies.addAll(newMovies);
          _isLoadingMoreTopRated = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMoreTopRated = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more movies: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreNowPlaying() async {
    if (_isLoadingMoreNowPlaying || !_hasMoreNowPlaying) return;

    setState(() {
      _isLoadingMoreNowPlaying = true;
    });

    try {
      _nowPlayingPage++;
      final newMovies = await _fetchMovies(
        '/movie/now_playing',
        _nowPlayingPage,
      );

      if (newMovies.isEmpty) {
        setState(() {
          _hasMoreNowPlaying = false;
          _isLoadingMoreNowPlaying = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _nowPlayingMovies.addAll(newMovies);
          _isLoadingMoreNowPlaying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMoreNowPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more movies: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  void _checkAuthStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('User is logged in: ${user.uid}');
      print('Email: ${user.email}');
      print('Email verified: ${user.emailVerified}');
    } else {
      print('No user is logged in');
    }
  }

  void _navigateToSearch() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Search feature coming soon')));
  }

  void _navigateToProfile() {
    Navigator.of(context).pushNamed('/profile');
  }

  Future<void> _showAddToWatchlistDialog(Map<String, dynamic> movie) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add to Watchlist'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [Text('Add "${movie['title']}" to your watchlist?')],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _addToWatchlist(movie);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToWatchlist(Map<String, dynamic> movie) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add movies to your watchlist'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pushNamed('/login');
        return;
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final movieData = {
        'id': movie['id'],
        'title': movie['title'],
        'poster_path': movie['poster_path'],
        'backdrop_path': movie['backdrop_path'] ?? '',
        'vote_average': movie['vote_average'] ?? 0.0,
        'release_date': movie['release_date'] ?? '',
        'added_at': Timestamp.now(),
      };

      await userDocRef.set({
        'watchlist': {movie['id'].toString(): movieData},
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to watchlist'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Watchlist error: $e');
      String errorMessage = 'Error adding to watchlist: ${e.toString()}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _debugFirestoreAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Debug: No user logged in');
        return;
      }

      print('Debug: Current user ID: ${user.uid}');

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      print('Debug: User document exists: ${userDoc.exists}');

      if (userDoc.exists) {
        print('Debug: User data: ${userDoc.data()}');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .doc('test')
          .set({'test': true, 'timestamp': FieldValue.serverTimestamp()});

      print('Debug: Test write successful');

      final testDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('watchlist')
              .doc('test')
              .get();

      print('Debug: Test read successful: ${testDoc.exists}');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .doc('test')
          .delete();

      print('Debug: Test cleanup successful');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  Widget _buildMovieList(
    List<dynamic> movies,
    String title,
    ScrollController controller,
    bool isLoadingMore,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemCount: movies.length + (isLoadingMore ? 1 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemBuilder: (context, index) {
              if (index == movies.length) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final movie = movies[index];
              final posterPath = movie['poster_path'];
              final backdropPath = movie['backdrop_path'];
              final imageUrl =
                  posterPath != null
                      ? '$_imageBaseUrl$posterPath'
                      : backdropPath != null
                      ? '$_imageBaseUrl$backdropPath'
                      : 'https://via.placeholder.com/150x225?text=No+Image';

              return Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _showAddToWatchlistDialog(movie),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          imageUrl,
                          height: 150,
                          width: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              width: 120,
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              width: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie['title'] ?? 'Unknown Title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          (movie['vote_average'] ?? 0.0).toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
            tooltip: 'Search Movies',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
            tooltip: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAllMovies,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _fetchAllMovies,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 8),
                      _buildMovieList(
                        _popularMovies,
                        'Popular Movies',
                        _popularController,
                        _isLoadingMorePopular,
                      ),
                      const SizedBox(height: 16),
                      _buildMovieList(
                        _topRatedMovies,
                        'Top Rated Movies',
                        _topRatedController,
                        _isLoadingMoreTopRated,
                      ),
                      const SizedBox(height: 16),
                      _buildMovieList(
                        _nowPlayingMovies,
                        'Now Playing',
                        _nowPlayingController,
                        _isLoadingMoreNowPlaying,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
      ),
    );
  }
}
