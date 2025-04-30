import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _error;
  String _username = '';
  String _email = '';
  List<Map<String, dynamic>> _watchlist = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Set email from Auth
      _email = user.email ?? 'No email available';

      // Get user data from Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        _username = userDoc.data()?['name'] ?? 'User';

        // Get watchlist from the map field
        final watchlistMap =
            userDoc.data()?['watchlist'] as Map<String, dynamic>?;

        if (watchlistMap != null) {
          _watchlist =
              watchlistMap.entries
                  .map((entry) => entry.value as Map<String, dynamic>)
                  .toList();
        } else {
          _watchlist = [];
        }
      } else {
        _username = 'User';
        _watchlist = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading profile: $e';
        _isLoading = false;
      });
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

  // Method to add a movie to watchlist (you can call this from movie details page)
  Future<void> addMovieToWatchlist(Map<String, dynamic> movie) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Convert the movie ID to string for document ID
      final movieId = movie['id'].toString();

      // Add to watchlist collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .doc(movieId)
          .set(movie);

      // Refresh the watchlist
      await _loadUserProfile();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to watchlist')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding to watchlist: $e')));
    }
  }

  Future<void> _removeFromWatchlist(String movieId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('watchlist')
          .doc(movieId)
          .delete();

      setState(() {
        _watchlist.removeWhere((movie) => movie['id'].toString() == movieId);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from watchlist')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing movie: $e')));
    }
  }

  Color _getAvatarColor() {
    if (_username.isEmpty) return Colors.blue;

    // Generate a color based on the first character of username
    final int charCode = _username.codeUnitAt(0);
    return Colors.primaries[charCode % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadUserProfile,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // User info card with avatar
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: _getAvatarColor(),
                              child: Text(
                                _username.isNotEmpty
                                    ? _username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _username,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Watchlist section
                    const Text(
                      'My Watchlist',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Watchlist items
                    _watchlist.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.movie_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Your watchlist is empty',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Movies you add to your watchlist will appear here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _watchlist.length,
                          itemBuilder: (context, index) {
                            final movie = _watchlist[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading:
                                    movie['poster_path'] != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.network(
                                            'https://image.tmdb.org/t/p/w92${movie['poster_path']}',
                                            width: 50,
                                            height: 75,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => Container(
                                                  width: 50,
                                                  height: 75,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.error,
                                                  ),
                                                ),
                                          ),
                                        )
                                        : Container(
                                          width: 50,
                                          height: 75,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.movie),
                                        ),
                                title: Text(
                                  movie['title'] ?? 'Unknown Movie',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle:
                                    movie['release_date'] != null
                                        ? Text(
                                          'Released: ${movie['release_date']}',
                                        )
                                        : null,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _removeFromWatchlist(
                                        movie['id'].toString(),
                                      ),
                                  tooltip: 'Remove from watchlist',
                                ),
                                onTap: () {
                                  // Navigate to movie details
                                  // Navigator.of(context).pushNamed('/movie-details', arguments: movie['id']);
                                },
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
    );
  }
}
