import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/news_bloc.dart';
import '../bloc/news_event.dart';
import '../bloc/news_state.dart';
import '../widgets/news_flip_panel.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: NewsView(),
    );
  }
}

class NewsView extends StatelessWidget {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? Colors.white70 : Colors.black54;
    return BlocConsumer<NewsBloc, NewsState>(
      listener: (context, state) {
        if (state is NewsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
          );
        }
      },
      builder: (context, state) {
        if (state is NewsLoading || state is NewsInitial) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? Colors.white24 : theme.colorScheme.primary,
            ),
          );
        }
        if (state is NewsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, style: TextStyle(color: muted), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<NewsBloc>().add(const FetchNews(perPage: 10)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is NewsLoaded) {
          if (state.articles.isEmpty) {
            return Center(
              child: Text('No articles available', style: TextStyle(color: muted)),
            );
          }
          return Stack(
            children: [
              NewsFlipPanel(
                items: state.articles,
                hasMore: !state.hasReachedMax,
                isLoadingMore: state.isLoadingMore,
                adInterval: 5,
                onNearEnd: () => context.read<NewsBloc>().add(const FetchMoreNews()),
              ),
              if (state.isLoadingMore)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Text('Loading more...',
                              style: TextStyle(fontSize: 12, color: muted)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
