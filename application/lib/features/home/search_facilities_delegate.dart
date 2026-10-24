import 'dart:math';
import 'package:application/core/theme/app_colors.dart';
import 'package:application/core/widgets/lottie_loader.dart';
import 'package:application/features/facilities/facility_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchFacilitiesDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search venues, sports, cities...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMain(context)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.montserrat(
          color: AppColors.textSec(context),
          fontSize: 14,
        ),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: GoogleFonts.montserrat(
          color: AppColors.textMain(context),
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: AppColors.textSec(context)),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: AppColors.textMain(context)),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptySuggestions(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildEmptySuggestions(BuildContext context) {
    return Container(
      color: AppColors.background(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Discover Venues',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by venue name, sport, city, or anything else',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: AppColors.textSec(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Container(
      color: AppColors.background(context),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _searchFacilities(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LottieLoader(message: 'Searching...');
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong',
                style: GoogleFonts.montserrat(color: AppColors.textSec(context)),
              ),
            );
          }

          final facilities = snapshot.data ?? [];

          // Apply fuzzy matching and scoring
          final scored = _fuzzyRank(facilities, query);

          if (scored.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: AppColors.textSec(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No results found for "$query"',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.textSec(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try different keywords or check spelling',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.textSec(context).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Venue results
              if (scored.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'VENUES',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.textSec(context),
                    ),
                  ),
                ),
                ...scored.map(
                  (facility) => _buildFacilityTile(context, facility),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFacilityTile(
    BuildContext context,
    Map<String, dynamic> facility,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 52,
          height: 52,
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Image.network(
            facility['image_url'] ?? '',
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.sports, color: AppColors.primary),
          ),
        ),
      ),
      title: Text(
        facility['name'] ?? 'Unknown',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textMain(context),
        ),
      ),
      subtitle: Text(
        '${facility['location'] ?? ''} · ${facility['sport_type'] ?? ''}',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          color: AppColors.textSec(context),
        ),
      ),
      trailing: facility['price_per_hour'] != null
          ? Text(
              '₹${facility['price_per_hour']}',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 14,
              ),
            )
          : null,
      onTap: () {
        close(context, facility['name'] ?? '');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacilityDetailsScreen(facility: facility),
          ),
        );
      },
    );
  }
  // ── Fuzzy matching ──

  /// Rank facilities by fuzzy match score against the query.
  List<Map<String, dynamic>> _fuzzyRank(
    List<Map<String, dynamic>> facilities,
    String query,
  ) {
    if (query.isEmpty) return facilities;
    final q = query.toLowerCase();

    final scored = <MapEntry<Map<String, dynamic>, double>>[];

    for (final f in facilities) {
      final fields = [
        (f['name'] ?? '').toString().toLowerCase(),
        (f['location'] ?? '').toString().toLowerCase(),
        (f['sport_type'] ?? '').toString().toLowerCase(),
        (f['description'] ?? '').toString().toLowerCase(),
      ];

      double bestScore = double.infinity;
      for (final field in fields) {
        if (field.isEmpty) continue;

        // Exact substring match → best possible
        if (field.contains(q)) {
          bestScore = 0;
          break;
        }

        // Word-level fuzzy: check each word
        final words = field.split(RegExp(r'\s+'));
        for (final word in words) {
          final dist = _levenshtein(q, word);
          // Normalize by longer string length
          final normalized = dist / max(q.length, word.length);
          bestScore = min(bestScore, normalized);
        }
      }

      // Threshold: allow up to 50% edit distance
      if (bestScore <= 0.5) {
        scored.add(MapEntry(f, bestScore));
      }
    }

    // Sort by best match first
    scored.sort((a, b) => a.value.compareTo(b.value));
    return scored.map((e) => e.key).toList();
  }

  /// Standard Levenshtein distance
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final n = s.length;
    final m = t.length;
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));

    for (int i = 0; i <= n; i++) dp[i][0] = i;
    for (int j = 0; j <= m; j++) dp[0][j] = j;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }
    return dp[n][m];
  }

  // ── Data fetching ──

  Future<List<Map<String, dynamic>>> _searchFacilities(String query) async {
    if (query.isEmpty) return [];
    try {
      // Fetch broadly — the fuzzy ranking will sort/filter
      final q = query.trim();
      final response = await Supabase.instance.client
          .from('facilities')
          .select()
          .or('name.ilike.%$q%,location.ilike.%$q%,sport_type.ilike.%$q%');

      // If we got results with ilike, great. If not, fetch all and fuzzy-match client-side.
      if ((response as List).isNotEmpty) {
        return List<Map<String, dynamic>>.from(response);
      }

      // Broader fallback: fetch all facilities for fuzzy matching
      final allFacilities = await Supabase.instance.client
          .from('facilities')
          .select();
      return List<Map<String, dynamic>>.from(allFacilities);
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }
}
